"""
geocode_hospitals.py — Add GPS coordinates to hospitals that have NULL lat/lng.

Strategy (3 attempts per facility, most to least precise):
  1. Nominatim search by full name + county → exact building match
  2. Nominatim search by sub-county name → place in correct sub-area
  3. Kenya county centroid → place in correct county (always succeeds)

So every facility will end up with *some* coordinates. Facilities geocoded via
strategy 2 or 3 are less precise but still useful for county-level routing.

Rate limit: 1 req/sec on Nominatim. For 8,932 facilities ~3 hours total.
Use --limit to run in safe batches (e.g. 500 at a time).

Usage:
    cd backend
    python ml/scripts/geocode_hospitals.py --dry-run
    python ml/scripts/geocode_hospitals.py --limit 500
    python ml/scripts/geocode_hospitals.py --offset 500 --limit 500
"""

import os
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
HEADERS = {"User-Agent": "RecoverSalama/1.0 (surgical recovery platform, Kenya)"}

# Approximate centroids for all 47 Kenya counties
# Used as last-resort fallback so no facility has NULL coords
COUNTY_CENTROIDS: dict[str, tuple[float, float]] = {
    "Mombasa":          (-4.0435,  39.6682),
    "Kwale":            (-4.1741,  39.4525),
    "Kilifi":           (-3.6305,  39.8499),
    "Tana River":       (-1.4551,  39.8523),
    "Lamu":             (-2.2686,  40.9020),
    "Taita Taveta":     (-3.3159,  38.4848),
    "Garissa":          (-0.4532,  39.6461),
    "Wajir":             (1.7471,  40.0573),
    "Mandera":           (3.9366,  41.8670),
    "Marsabit":          (2.3284,  37.9899),
    "Isiolo":            (0.3542,  38.0106),
    "Meru":             (-0.0474,  37.6490),
    "Tharaka-Nithi":    (-0.3009,  37.8893),
    "Embu":             (-0.5301,  37.4500),
    "Kitui":            (-1.3667,  38.0110),
    "Machakos":         (-1.5177,  37.2634),
    "Makueni":          (-2.2587,  37.8937),
    "Nyandarua":        (-0.1806,  36.5236),
    "Nyeri":            (-0.4167,  37.0833),
    "Kirinyaga":        (-0.6601,  37.3822),
    "Murang'a":         (-0.7176,  37.1531),
    "Kiambu":           (-1.0312,  36.8306),
    "Turkana":           (3.1185,  35.5975),
    "West Pokot":        (1.5477,  35.1180),
    "Samburu":           (1.0655,  36.9860),
    "Trans-Nzoia":       (1.0567,  35.0020),
    "Uasin Gishu":       (0.5143,  35.2698),
    "Elgeyo-Marakwet":   (0.6881,  35.4885),
    "Nandi":             (0.1838,  35.1000),
    "Baringo":           (0.8500,  36.0833),
    "Laikipia":          (0.3613,  36.7826),
    "Nakuru":           (-0.2833,  36.0667),
    "Narok":            (-1.0826,  35.8710),
    "Kajiado":          (-2.0981,  36.7820),
    "Kericho":          (-0.3686,  35.2863),
    "Bomet":            (-0.7871,  35.3419),
    "Kakamega":          (0.2827,  34.7519),
    "Vihiga":            (0.0764,  34.7237),
    "Bungoma":           (0.5635,  34.5606),
    "Busia":             (0.4608,  34.1116),
    "Siaya":            (-0.0617,  34.2880),
    "Kisumu":           (-0.0917,  34.7679),
    "Homa Bay":         (-0.5273,  34.4571),
    "Migori":           (-1.0634,  34.4733),
    "Kisii":            (-0.6817,  34.7660),
    "Nyamira":          (-0.5667,  34.9333),
    "Nairobi":          (-1.2864,  36.8172),
}


def _county_from_address(address: str) -> str:
    """Extract county name from address like 'Lurambi, Kakamega County, Kenya'.
    Skips 'Sub County' parts so it finds the real county name."""
    for part in address.split(","):
        part = part.strip()
        # "Sub County" in the sub-county name must not be mistaken for the county
        if "County" in part and "Sub County" not in part and "Sub county" not in part:
            return part.replace("County", "").strip()
    return ""


def _subcounty_from_address(address: str) -> str:
    """Extract first part of address (usually sub-county name)."""
    parts = [p.strip() for p in address.split(",") if p.strip()]
    return parts[0] if parts else ""


def _nominatim(query: str) -> tuple[float, float] | None:
    try:
        r = requests.get(
            NOMINATIM,
            params={"q": query, "format": "json", "limit": 1, "countrycodes": "ke"},
            headers=HEADERS,
            timeout=15,
        )
        if r.status_code == 200 and r.json():
            hit = r.json()[0]
            return float(hit["lat"]), float(hit["lon"])
    except Exception:
        pass
    finally:
        time.sleep(1.1)  # Nominatim: max 1 req/sec
    return None


def geocode(name: str, address: str) -> tuple[float, float, str]:
    """
    Returns (lat, lng, method) where method is 'exact', 'subcounty', or 'county'.
    Always returns coordinates — falls back to county centroid.
    """
    county = _county_from_address(address)
    subcounty = _subcounty_from_address(address)

    # 1. Exact name match
    coords = _nominatim(f"{name}, Kenya")
    if coords:
        return coords[0], coords[1], "exact"

    # 2. Sub-county centroid (skip if sub-county is just the county name repeated)
    if subcounty and subcounty.lower() != county.lower():
        coords = _nominatim(f"{subcounty}, {county}, Kenya")
        if coords:
            return coords[0], coords[1], "subcounty"

    # 3. County centroid (always succeeds for known counties)
    for key, latlon in COUNTY_CENTROIDS.items():
        if key.lower() in county.lower() or county.lower() in key.lower():
            return latlon[0], latlon[1], "county"

    # 4. Absolute fallback: centre of Kenya
    return -0.0236, 37.9062, "country"


def run(dry_run: bool, limit: int | None, offset: int):
    db = create_client(
        os.environ["SUPABASE_URL"],
        os.environ["SUPABASE_SERVICE_KEY"],
    )

    query = db.table("hospitals").select("id,name,address").is_("lat", "null")
    if limit:
        query = query.range(offset, offset + limit - 1)

    facilities = (query.execute().data or [])
    print(f"Facilities to geocode: {len(facilities)}")

    if dry_run:
        print("\n[DRY RUN] First 15:")
        for f in facilities[:15]:
            print(f"  {f['name'][:55]:<55} | {(f.get('address') or '')[:40]}")
        return

    exact = subcounty_hits = county_hits = country_hits = 0
    for i, f in enumerate(facilities):
        lat, lng, method = geocode(f["name"], f.get("address") or "")
        db.table("hospitals").update({"lat": lat, "lng": lng}).eq("id", f["id"]).execute()

        if method == "exact":
            exact += 1
            marker = "✓"
        elif method == "subcounty":
            subcounty_hits += 1
            marker = "~"
        elif method == "county":
            county_hits += 1
            marker = "○"
        else:
            country_hits += 1
            marker = "?"

        print(f"[{i+1}/{len(facilities)}] {marker} {f['name'][:50]:<50} ({method}) → {lat:.4f},{lng:.4f}")

    total = len(facilities)
    print(f"\nDone: {exact} exact  |  {subcounty_hits} sub-county  |  {county_hits} county  |  {country_hits} country fallback")
    print(f"All {total} facilities now have coordinates.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--offset", type=int, default=0)
    args = parser.parse_args()
    run(dry_run=args.dry_run, limit=args.limit, offset=args.offset)


if __name__ == "__main__":
    main()
