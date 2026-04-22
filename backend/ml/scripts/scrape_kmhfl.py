"""
scrape_kmhfl.py — Scrape all 17,338 facilities from https://kmhfr.health.go.ke/public/facilities

Each page shows 30 facilities (≈578 pages total). The script:
  1. Loads the page in a headless browser (waits for JS to render)
  2. Extracts facility name, type, county, sub-county, ward from the DOM
  3. Clicks "Next" and repeats

Prerequisites:
    pip install playwright
    playwright install chromium

Usage:
    python ml/scripts/scrape_kmhfl.py --dry-run          # page 1 only, preview
    python ml/scripts/scrape_kmhfl.py --pages 10         # first 10 pages (300 facilities)
    python ml/scripts/scrape_kmhfl.py --output out.json  # save all to JSON
    python ml/scripts/scrape_kmhfl.py --seed             # insert into Supabase
"""

import asyncio
import json
import os
import re
import sys
import time
import argparse
from pathlib import Path

env_path = Path(__file__).parent.parent.parent / ".env"
if env_path.exists():
    from dotenv import load_dotenv
    load_dotenv(env_path)

try:
    from playwright.async_api import async_playwright, TimeoutError as PWTimeout
except ImportError:
    print("Playwright not installed. Run: pip install playwright && playwright install chromium")
    sys.exit(1)

KMHFL_URL = "https://kmhfr.health.go.ke/public/facilities"

# Facility type badge → our DB type
TYPE_MAP = {
    "national referral": "public",
    "county referral": "public",
    "county hospital": "public",
    "sub-county hospital": "public",
    "sub county hospital": "public",
    "dispensary": "public",
    "health centre": "public",
    "health center": "public",
    "primary care": "public",
    "basic primary": "public",
    "nursing home": "private",
    "medical clinic": "private",
    "medical centre": "private",
    "dental": "private",
    "eye": "private",
    "radiology": "private",
    "laboratory": "private",
}


def _map_type(facility_type: str, name: str) -> str:
    ft = (facility_type or "").lower()
    nm = (name or "").lower()

    for keyword, t in TYPE_MAP.items():
        if keyword in ft:
            return t

    # Name-based fallback
    if any(w in nm for w in ["national", "kenyatta", "pumwani", "county referral"]):
        return "public"
    if any(w in nm for w in ["mission", "catholic", "church", "methodist", "presbyterian",
                              "seventh day", "aga khan", "salvation"]):
        return "mission"
    return "private"


def _clean_phone(phone: str) -> str | None:
    p = re.sub(r"[\s\-\(\)]", "", phone or "")
    if p.startswith("0") and len(p) == 10:
        return f"+254{p[1:]}"
    if p.startswith("254") and not p.startswith("+"):
        return f"+{p}"
    return p or None


# JavaScript that extracts all facility cards from the current page
EXTRACT_JS = """
() => {
    const results = [];

    // Each facility card contains an <a> link to /public/facilities/{uuid}
    const links = document.querySelectorAll('a[href^="/public/facilities/"]');

    links.forEach(link => {
        const name = link.innerText.trim();
        if (!name || name.length < 3) return;

        // Walk up the DOM to find the outer card div (the one with border-b class)
        // Structure: a > div.flex-wrap > div.flex-col.gap-1.border-b (the card)
        let card = link.parentElement;
        for (let i = 0; i < 5; i++) {
            if (!card) break;
            if (card.classList.contains('border-b') || card.querySelector('label')) break;
            card = card.parentElement;
        }
        if (!card) return;

        // Badges
        const badges = Array.from(card.querySelectorAll('span[class*="rounded-full"]'))
            .map(s => s.innerText.trim());
        const facilityType = badges[0] || '';

        // Location labels — find label element then read its next sibling span
        function getLabelValue(labelText) {
            const labels = card.querySelectorAll('label');
            for (const lbl of labels) {
                if (lbl.innerText.trim() === labelText) {
                    const span = lbl.nextElementSibling;
                    return span ? span.innerText.trim() : '';
                }
            }
            return '';
        }

        const county    = getLabelValue('County:');
        const subCounty = getLabelValue('Sub-county:');
        const ward      = getLabelValue('Ward:');

        results.push({ name, facilityType, county, subCounty, ward });
    });

    return results;
}
"""

# Get total count from "30 of 17338" counter
COUNT_JS = """
() => {
    const els = document.querySelectorAll('p');
    for (const el of els) {
        const m = el.innerText.match(/\\d+ of ([\\d,]+)/);
        if (m) return parseInt(m[1].replace(',', ''));
    }
    return 0;
}
"""

# Check if Next button exists and is clickable
NEXT_BTN_JS = """
() => {
    // Look for a button or link with "Next" text that is not disabled
    const all = Array.from(document.querySelectorAll('button, a'));
    for (const el of all) {
        const text = el.innerText.trim().toLowerCase();
        if (text === 'next' || text === 'next page' || text === '>') {
            const disabled = el.disabled || el.getAttribute('aria-disabled') === 'true'
                             || el.classList.contains('disabled');
            if (!disabled) return true;
        }
    }
    return false;
}
"""

CLICK_NEXT_JS = """
() => {
    const all = Array.from(document.querySelectorAll('button, a'));
    for (const el of all) {
        const text = el.innerText.trim().toLowerCase();
        if (text === 'next' || text === 'next page' || text === '>') {
            const disabled = el.disabled || el.getAttribute('aria-disabled') === 'true'
                             || el.classList.contains('disabled');
            if (!disabled) { el.click(); return true; }
        }
    }
    return false;
}
"""


async def scrape(max_pages: int | None) -> list[dict]:
    all_records: list[dict] = []
    seen: set[str] = set()

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1280, "height": 900})

        print(f"Loading {KMHFL_URL} …")
        await page.goto(KMHFL_URL, wait_until="domcontentloaded", timeout=60_000)

        # Wait for facility links to appear in the DOM
        print("Waiting for facility list to render…")
        try:
            await page.wait_for_selector('a[href^="/public/facilities/"]', timeout=20_000)
        except PWTimeout:
            print("ERROR: Facility links never appeared. The page structure may have changed.")
            await browser.close()
            return []

        await page.wait_for_timeout(1_000)

        total = await page.evaluate(COUNT_JS)
        if total:
            est_pages = (total // 30) + 1
            print(f"Total on site: {total:,} facilities (~{est_pages} pages)")

        page_num = 1
        while True:
            if max_pages and page_num > max_pages:
                break

            items = await page.evaluate(EXTRACT_JS)
            new_this_page = 0

            for item in items:
                name = item.get("name", "").strip()
                if not name or len(name) < 3:
                    continue
                key = name.lower()
                if key in seen:
                    continue
                seen.add(key)
                new_this_page += 1

                county = item.get("county", "")
                sub_county = item.get("subCounty", "")
                addr_parts = [p for p in [sub_county, county, "Kenya"] if p]

                all_records.append({
                    "name": name,
                    "type": _map_type(item.get("facilityType", ""), name),
                    "address": ", ".join(dict.fromkeys(addr_parts)),
                    "phone": None,
                    "lat": None,
                    "lng": None,
                })

            print(f"  Page {page_num}: +{new_this_page} facilities (total: {len(all_records)})")

            if not items:
                print("  No items found on this page — stopping.")
                break

            # Try to go to next page
            has_next = await page.evaluate(NEXT_BTN_JS)
            if not has_next:
                print("  Last page reached.")
                break

            clicked = await page.evaluate(CLICK_NEXT_JS)
            if not clicked:
                print("  Could not click Next — stopping.")
                break

            # Wait for the page to update (new links to load)
            await page.wait_for_timeout(2_500)
            page_num += 1

        await browser.close()

    print(f"\nTotal unique facilities scraped: {len(all_records):,}")
    return all_records


def seed_to_db(records: list[dict]) -> None:
    from supabase import create_client
    db = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_KEY"])
    print(f"Upserting {len(records):,} facilities (skipping duplicates by name)…")
    inserted = errors = 0
    batch_size = 50
    for i in range(0, len(records), batch_size):
        batch = records[i:i + batch_size]
        try:
            # ignore_duplicates=True → INSERT ... ON CONFLICT (name) DO NOTHING
            db.table("hospitals").upsert(batch, on_conflict="name", ignore_duplicates=True).execute()
            inserted += len(batch)
            print(f"  Processed {min(inserted, len(records))}/{len(records)}", end="\r")
        except Exception as exc:
            print(f"\n  Batch error: {exc} — trying one by one")
            for h in batch:
                try:
                    db.table("hospitals").upsert(h, on_conflict="name", ignore_duplicates=True).execute()
                    inserted += 1
                except Exception:
                    errors += 1
        time.sleep(0.1)
    print(f"\nDone. {errors} errors.")
    print("Any existing facilities were left unchanged; new ones were inserted.")


async def main_async(args):
    # Load from saved JSON instead of re-scraping
    if args.from_json:
        with open(args.from_json, encoding="utf-8") as f:
            records = json.load(f)
        print(f"Loaded {len(records):,} facilities from {args.from_json}")
    else:
        records = await scrape(max_pages=args.pages if not args.dry_run else 1)
        if not records:
            print("\nNo data scraped. Check your internet connection.")
            sys.exit(1)

    if args.dry_run:
        print(f"\n[DRY RUN] First 20 of {len(records)} scraped:")
        for r in records[:20]:
            print(f"  {r['name'][:55]:<55} | {r['type']:<8} | {r['address'][:35]}")
        return

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(records, f, indent=2, ensure_ascii=False)
        print(f"Saved {len(records):,} facilities → {args.output}")

    if args.seed:
        seed_to_db(records)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Scrape page 1 only, preview results")
    parser.add_argument("--pages", type=int, default=None, help="Max pages to scrape")
    parser.add_argument("--output", type=str, help="Save scraped data to JSON file")
    parser.add_argument("--from-json", type=str, help="Load from a previously saved JSON instead of scraping")
    parser.add_argument("--seed", action="store_true", help="Insert into Supabase DB")
    args = parser.parse_args()
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
