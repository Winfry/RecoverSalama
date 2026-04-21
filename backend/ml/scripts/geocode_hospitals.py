"""
geocode_hospitals.py — Add GPS coordinates to hospitals that have NULL lat/lng.

Uses OpenStreetMap Nominatim (free, no API key needed).
Rate limit: 1 request/second (Nominatim ToS).

For 8,932 facilities this takes ~3 hours to complete.
Run it overnight, or use --limit to do it in batches.

Usage:
    cd backend

    # Dry run — show what would be geocoded
    python ml/scripts/geocode_hospitals.py --dry-run

    # Geocode first 100 facilities
    python ml/scripts/geocode_hospitals.py --limit 100

    # Geocode ALL (run overnight)
    python ml/scripts/geocode_hospitals.py

    # Resume from a specific offset (useful after interruption)
    python ml/scripts/geocode_hospitals.py --offset 500 --limit 500
"""

import os
import sys
import time
import argparse
from pathlib import Path

env_path = Path(__file__).parent.parent.parent / ".env"
if env_path.exists():
    from dotenv import load_dotenv
    load_dotenv(env_path)

import requests
from supabase import create_client

NOMINATIM = "https://nominatim.openstreetmap.org/search"
# Required by Nominatim ToS: identify your app
HEADERS = {"User-Agent": "RecoverSalama/1.0 (surgical recovery platform, Kenya)"}


def geocode(name: str, address: str) -> tuple[float, float] | None:
    """
    Try to find coordinates for a facility.
    Attempts in order:
      1. Full name + "Kenya"
      2. First word(s) of name + county extracted from address
    """
    county = ""
    if "County" in address:
        parts = address.split(",")
        for p in parts:
            if "County" in p:
                county = p.strip()
                break

    queries = [
        f"{name}, Kenya",
        f"{name}, {county}, Kenya" if county else None,
    ]

    for q in queries:
        if not q:
            continue
        try:
            r = requests.get(
                NOMINATIM,
                params={
                    "q": q,
                    "format": "json",
                    "limit": 1,
                    "countrycodes": "ke",
                    "featuretype": "settlement,amenity",
                },
                headers=HEADERS,
                timeout=15,
            )
            if r.status_code == 200:
                results = r.json()
                if results:
                    return float(results[0]["lat"]), float(results[0]["lon"])
        except Exception:
            pass
        time.sleep(1)  # Nominatim rate limit: 1 req/sec

    return None


def run(dry_run: bool, limit: int | None, offset: int):
    db = create_client(
        os.environ["SUPABASE_URL"],
        os.environ["SUPABASE_SERVICE_KEY"],
    )

    # Fetch facilities with no coordinates
    query = db.table("hospitals").select("id,name,address").is_("lat", "null")
    if offset:
        query = query.range(offset, offset + (limit or 9999) - 1)
    elif limit:
        query = query.limit(limit)

    resp = query.execute()
    facilities = resp.data or []

    print(f"Facilities to geocode: {len(facilities)}")
    if dry_run:
        print("\n[DRY RUN] First 10:")
        for f in facilities[:10]:
            print(f"  {f['name'][:55]:<55} | {f['address'][:40]}")
        return

    found = skipped = 0
    for i, f in enumerate(facilities):
        coords = geocode(f["name"], f.get("address") or "")
        if coords:
            lat, lng = coords
            db.table("hospitals").update({"lat": lat, "lng": lng}).eq("id", f["id"]).execute()
            found += 1
            print(f"[{i+1}/{len(facilities)}] ✓ {f['name'][:50]:<50} → {lat:.4f},{lng:.4f}")
        else:
            skipped += 1
            print(f"[{i+1}/{len(facilities)}] ✗ {f['name'][:50]:<50} (not found)")

        # Nominatim ToS: max 1 req/sec (geocode() already sleeps, add small buffer)
        time.sleep(0.2)

    print(f"\nDone: {found} geocoded, {skipped} not found")
    print(f"Remaining without coords: approx {skipped} — re-run to retry")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=None, help="Max facilities to geocode")
    parser.add_argument("--offset", type=int, default=0, help="Skip first N facilities")
    args = parser.parse_args()

    run(dry_run=args.dry_run, limit=args.limit, offset=args.offset)


if __name__ == "__main__":
    main()
