"""
scrape_kmhfl.py — Scrape all health facilities from the Kenya Master Health Facility
List Register public website (https://kmhfr.health.go.ke/public/facilities).

The KMHFL REST API requires auth, but the website is public. This script uses
Playwright to drive a headless browser, intercept the API calls the site makes,
and collect all 17,000+ facilities with their coordinates.

Prerequisites:
    pip install playwright
    playwright install chromium

Usage:
    python ml/scripts/scrape_kmhfl.py

    # Dry run — preview first 20 results
    python ml/scripts/scrape_kmhfl.py --dry-run

    # Save to JSON (for manual inspection before DB insert)
    python ml/scripts/scrape_kmhfl.py --output facilities.json

    # Insert into Supabase after scraping
    python ml/scripts/scrape_kmhfl.py --seed
"""

import asyncio
import json
import os
import sys
import time
import argparse
from pathlib import Path

# Load .env
env_path = Path(__file__).parent.parent.parent / ".env"
if env_path.exists():
    from dotenv import load_dotenv
    load_dotenv(env_path)

try:
    from playwright.async_api import async_playwright, Route, Request
except ImportError:
    print("Playwright not installed. Run: pip install playwright && playwright install chromium")
    sys.exit(1)

KMHFL_PUBLIC_URL = "https://kmhfr.health.go.ke/public/facilities"
PAGE_SIZE = 100  # request large pages to reduce round trips


def _map_type(owner: str, facility_type: str = "") -> str:
    o = (owner or "").lower()
    f = (facility_type or "").lower()
    if any(w in o for w in ["ministry", "county government", "government", "national",
                             "armed forces", "public institution", "academic"]):
        return "public"
    if any(w in o for w in ["faith", "church", "catholic", "protestant", "seventh",
                             "aga khan", "religious", "fbo", "episcopal", "christian health",
                             "mission", "salvation"]):
        return "mission"
    if "emergency" in f:
        return "emergency"
    return "private"


def _transform(raw: dict) -> dict | None:
    name = (raw.get("name") or "").strip()
    if not name or len(name) < 3:
        return None

    lat_raw = raw.get("lat") or raw.get("latitude")
    lng_raw = raw.get("long") or raw.get("lon") or raw.get("longitude")
    try:
        lat = float(lat_raw) if lat_raw not in (None, "", "null", 0) else None
        lng = float(lng_raw) if lng_raw not in (None, "", "null", 0) else None
    except (ValueError, TypeError):
        lat = lng = None

    owner = raw.get("owner_name") or raw.get("owner") or ""
    if isinstance(owner, dict):
        owner = owner.get("name", "")
    ftype_raw = raw.get("facility_type_details") or raw.get("facility_type") or ""
    if isinstance(ftype_raw, dict):
        ftype_raw = ftype_raw.get("name", "")

    county = raw.get("county_name") or raw.get("county") or ""
    if isinstance(county, dict):
        county = county.get("name", "")
    sub_county = raw.get("sub_county_name") or raw.get("sub_county") or ""
    if isinstance(sub_county, dict):
        sub_county = sub_county.get("name", "")
    town = raw.get("town_name") or raw.get("town") or ""

    addr_parts = [p for p in [town, sub_county, county, "Kenya"] if p]
    address = ", ".join(dict.fromkeys(addr_parts))

    phone_raw = raw.get("phone") or raw.get("contacts") or ""
    if isinstance(phone_raw, list):
        phone_raw = next((c.get("contact") for c in phone_raw
                         if c.get("contact_type") in ("PHONE", "phone")), "") or ""
    phone = str(phone_raw).strip().replace(" ", "").replace("-", "")
    if phone.startswith("0") and len(phone) == 10:
        phone = f"+254{phone[1:]}"
    elif phone.startswith("254") and not phone.startswith("+"):
        phone = f"+{phone}"

    return {
        "name": name,
        "type": _map_type(owner, ftype_raw),
        "address": address,
        "phone": phone or None,
        "lat": lat,
        "lng": lng,
    }


async def scrape() -> list[dict]:
    """Intercept KMHFL API calls made by the browser and collect all facilities."""
    collected_raw: list[dict] = []
    api_responses: list[dict] = []

    print("Starting Playwright browser…")
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        page = await context.new_page()

        # Intercept API responses
        async def handle_response(response):
            url = response.url
            if "facilities" in url and "api." in url:
                try:
                    body = await response.json()
                    results = body.get("results") or body.get("data") or []
                    if results:
                        api_responses.append({
                            "url": url,
                            "count": body.get("count", len(results)),
                            "results": results,
                        })
                        print(f"  Intercepted: {len(results)} facilities from {url[:80]}")
                except Exception:
                    pass

        page.on("response", handle_response)

        print(f"Navigating to {KMHFL_PUBLIC_URL}…")
        await page.goto(KMHFL_PUBLIC_URL, wait_until="networkidle", timeout=60_000)
        await page.wait_for_timeout(3000)

        # Try to trigger a larger page size via URL params if pagination is URL-based
        total = api_responses[0]["count"] if api_responses else 0
        print(f"Total facilities reported: {total}")

        if total > 0 and api_responses:
            first_url = api_responses[0]["url"]
            import re
            # Extract base API URL and try fetching all pages directly
            base = re.sub(r'[?&]page=\d+', '', first_url)
            base = re.sub(r'[?&]page_size=\d+', '', base)
            sep = "&" if "?" in base else "?"

            # Check if we got a token in the intercepted request
            all_pages_url = f"{base}{sep}page_size={PAGE_SIZE}&page=1"
            print(f"Will try paginated fetch via: {all_pages_url}")

            # Collect all intercepted results first
            for resp in api_responses:
                collected_raw.extend(resp["results"])

            # Try to navigate through pagination in the browser
            pages_needed = (total // PAGE_SIZE) + 2
            for pg in range(2, min(pages_needed, 200)):
                await page.evaluate(f"""
                    window.__fetch_page = {pg};
                """)
                # Try clicking next page if visible
                try:
                    next_btn = await page.query_selector('button:has-text("Next"), a:has-text("Next")')
                    if next_btn:
                        prev_count = len(collected_raw)
                        await next_btn.click()
                        await page.wait_for_timeout(2000)
                        new_items = sum(len(r["results"]) for r in api_responses) - len(collected_raw)
                        if new_items > 0:
                            for resp in api_responses[-2:]:
                                collected_raw.extend(resp["results"])
                        if len(collected_raw) >= total:
                            break
                    else:
                        break
                except Exception as e:
                    print(f"  Pagination stopped at page {pg}: {e}")
                    break

        await browser.close()

    if not collected_raw:
        print("No data intercepted. The site may have changed its API structure.")
        print("Try visiting https://kmhfr.health.go.ke/public/facilities in a browser")
        print("and check Network tab for the API URL, then update this script.")
        return []

    # Transform + deduplicate
    results = []
    seen = set()
    for raw in collected_raw:
        r = _transform(raw)
        if r:
            key = r["name"].lower().strip()
            if key not in seen:
                results.append(r)
                seen.add(key)

    print(f"\nTransformed: {len(results)} unique facilities")
    return results


def seed_to_db(records: list[dict]) -> None:
    import time as _time
    from supabase import create_client

    db = create_client(
        os.environ["SUPABASE_URL"],
        os.environ["SUPABASE_SERVICE_KEY"],
    )

    existing = db.table("hospitals").select("name").execute()
    existing_names = {r["name"].lower() for r in (existing.data or [])}
    new = [h for h in records if h["name"].lower() not in existing_names]

    print(f"DB existing: {len(existing_names)} | New to insert: {len(new)}")
    inserted = errors = 0
    for i in range(0, len(new), 50):
        batch = new[i:i + 50]
        try:
            db.table("hospitals").insert(batch).execute()
            inserted += len(batch)
            print(f"  Inserted {inserted}/{len(new)}", end="\r")
        except Exception as exc:
            print(f"\n  Batch error: {exc}")
            for h in batch:
                try:
                    db.table("hospitals").insert(h).execute()
                    inserted += 1
                except Exception:
                    errors += 1
        _time.sleep(0.2)

    print(f"\nDone: {inserted} inserted, {errors} errors")


async def main_async(args):
    records = await scrape()

    if not records:
        sys.exit(1)

    if args.dry_run:
        print("\n[DRY RUN] First 20 facilities:")
        for r in records[:20]:
            coords = f"{r['lat']:.4f},{r['lng']:.4f}" if r["lat"] else "no coords"
            print(f"  {r['name'][:50]:<50} {r['type']:<8} {coords}")
        print(f"\n  … {len(records)} total")
        return

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(records, f, indent=2, ensure_ascii=False)
        print(f"Saved {len(records)} facilities to {args.output}")

    if args.seed:
        seed_to_db(records)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output", type=str, help="Save to JSON file")
    parser.add_argument("--seed", action="store_true", help="Insert into Supabase DB")
    args = parser.parse_args()

    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
