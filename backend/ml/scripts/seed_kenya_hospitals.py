"""
seed_kenya_hospitals.py — Seed ALL Kenya health facilities into SalamaRecover.

Sources (in priority order):
  1. Kenya Master Health Facility List Register (KMHFL) — official MOH database,
     12,000+ facilities, all 47 counties.  https://kmhfr.health.go.ke
  2. OpenStreetMap (Overpass API) — gap-fill for facilities missing from KMHFL.

Usage:
    cd backend
    python ml/scripts/seed_kenya_hospitals.py

    # Dry run (preview without inserting):
    python ml/scripts/seed_kenya_hospitals.py --dry-run

    # Skip KMHFL, use OSM only:
    python ml/scripts/seed_kenya_hospitals.py --osm-only

    # Skip OSM, use KMHFL only:
    python ml/scripts/seed_kenya_hospitals.py --kmhfl-only

    # Filter to specific area (OSM path only):
    python ml/scripts/seed_kenya_hospitals.py --area "Nairobi"
"""

import os
import sys
import time
import argparse
from pathlib import Path
from unicodedata import normalize

# Load .env
env_path = Path(__file__).parent.parent.parent / ".env"
if env_path.exists():
    from dotenv import load_dotenv
    load_dotenv(env_path)

import httpx
from supabase import create_client

# ── KMHFL ──────────────────────────────────────────────────────────────────
KMHFL_BASE = "https://api.kmhfr.health.go.ke/api/facilities/facilities/"
KMHFL_PAGE_SIZE = 100

# ── OpenStreetMap ───────────────────────────────────────────────────────────
OVERPASS_URL = "https://overpass-api.de/api/interpreter"
# Kenya bounding box: south, west, north, east
KENYA_BBOX = "-4.67,33.91,4.62,41.90"


# ── helpers ─────────────────────────────────────────────────────────────────

def _normalise(name: str) -> str:
    """Lowercase + strip accents for fuzzy dedup."""
    return normalize("NFKD", name).encode("ascii", "ignore").decode().lower().strip()


def _map_type(owner: str, facility_type: str) -> str:
    """Map KMHFL owner/type strings to our schema's 4-value enum."""
    o = owner.lower()
    f = facility_type.lower()
    if any(w in o for w in ["ministry", "county", "government", "national", "armed"]):
        return "public"
    if any(w in o for w in ["faith", "church", "mission", "catholic", "protestant",
                             "seventh", "aga khan", "religious", "fbo"]):
        return "mission"
    if "emergency" in f:
        return "emergency"
    return "private"


def _normalise_phone(phone: str) -> str:
    phone = phone.replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
    if phone.startswith("0") and len(phone) == 10:
        return f"+254{phone[1:]}"
    if phone.startswith("254") and not phone.startswith("+"):
        return f"+{phone}"
    return phone


# ── KMHFL source ─────────────────────────────────────────────────────────────

def fetch_kmhfl(active_only: bool = True) -> list[dict]:
    """
    Fetch all facilities from the Kenya Master Health Facility List Register.
    Returns transformed records ready for our hospitals table.
    """
    print("Fetching from Kenya Master Health Facility List Register (KMHFL)…")
    results = []
    page = 1

    params: dict = {
        "format": "json",
        "page_size": KMHFL_PAGE_SIZE,
        "fields": "name,code,facility_type_details,owner_name,keph_level_name,"
                  "county_name,sub_county_name,ward_name,town_name,"
                  "lat,long,phone,is_published",
    }
    if active_only:
        params["is_published"] = "true"

    with httpx.Client(timeout=60.0) as client:
        while True:
            params["page"] = page
            try:
                r = client.get(KMHFL_BASE, params=params)
                r.raise_for_status()
                data = r.json()
            except Exception as exc:
                print(f"  KMHFL page {page} error: {exc}")
                break

            batch = data.get("results") or data.get("data") or []
            if not batch:
                break

            for raw in batch:
                rec = _transform_kmhfl(raw)
                if rec:
                    results.append(rec)

            total = data.get("count", 0)
            fetched = (page - 1) * KMHFL_PAGE_SIZE + len(batch)
            print(f"  KMHFL: {fetched}/{total} fetched…", end="\r")

            if not data.get("next"):
                break
            page += 1
            time.sleep(0.1)

    print(f"\n  KMHFL: {len(results)} facilities transformed")
    return results


def _transform_kmhfl(raw: dict) -> dict | None:
    name = (raw.get("name") or "").strip()
    if not name or len(name) < 3:
        return None

    lat_raw = raw.get("lat")
    lng_raw = raw.get("long") or raw.get("lng")

    try:
        lat = float(lat_raw) if lat_raw not in (None, "", "null") else None
        lng = float(lng_raw) if lng_raw not in (None, "", "null") else None
    except (ValueError, TypeError):
        lat = lng = None

    owner = raw.get("owner_name") or raw.get("owner") or ""
    ftype = raw.get("facility_type_details") or raw.get("facility_type") or ""
    if isinstance(ftype, dict):
        ftype = ftype.get("name", "")

    addr_parts = filter(None, [
        raw.get("town_name"),
        raw.get("ward_name"),
        raw.get("sub_county_name"),
        raw.get("county_name"),
        "Kenya",
    ])
    address = ", ".join(dict.fromkeys(addr_parts))

    phone = _normalise_phone((raw.get("phone") or "").strip())

    return {
        "name": name,
        "type": _map_type(owner, ftype),
        "address": address,
        "phone": phone,
        "lat": lat,
        "lng": lng,
    }


# ── OSM source ───────────────────────────────────────────────────────────────

def fetch_osm(area: str | None = None) -> list[dict]:
    """
    Fetch health facilities from OpenStreetMap via Overpass API.
    Covers: hospitals, health centres, clinics, dispensaries, health posts.
    """
    print("Fetching from OpenStreetMap (Overpass API)…")

    healthcare_values = '"hospital","clinic","health_centre","health_center","dispensary","health_post"'
    amenity_values = '"hospital","clinic","health_centre"'

    if area:
        query = f"""
[out:json][timeout:120];
area["name"="{area}"]["admin_level"~"4|5|6|7"]->.searchArea;
(
  node["amenity"~{amenity_values}](area.searchArea);
  way["amenity"~{amenity_values}](area.searchArea);
  node["healthcare"~{healthcare_values}](area.searchArea);
  way["healthcare"~{healthcare_values}](area.searchArea);
);
out center tags;
"""
    else:
        query = f"""
[out:json][timeout:240];
(
  node["amenity"~{amenity_values}]({KENYA_BBOX});
  way["amenity"~{amenity_values}]({KENYA_BBOX});
  node["healthcare"~{healthcare_values}]({KENYA_BBOX});
  way["healthcare"~{healthcare_values}]({KENYA_BBOX});
);
out center tags;
"""

    try:
        with httpx.Client(timeout=240.0) as client:
            r = client.post(
                OVERPASS_URL,
                content=query.strip().encode(),
                headers={"Content-Type": "text/plain"},
            )
            r.raise_for_status()
            elements = r.json().get("elements", [])
            print(f"  OSM: {len(elements)} raw elements")
    except Exception as exc:
        print(f"  OSM error: {exc}")
        return []

    results = []
    seen: set[str] = set()
    for el in elements:
        rec = _transform_osm(el)
        if rec:
            key = _normalise(rec["name"])
            if key not in seen:
                results.append(rec)
                seen.add(key)

    print(f"  OSM: {len(results)} unique facilities transformed")
    return results


def _transform_osm(element: dict) -> dict | None:
    tags = element.get("tags", {})
    name = (
        tags.get("name") or tags.get("name:en") or tags.get("official_name") or ""
    ).strip()

    if not name or len(name) < 3:
        return None

    # Skip non-health-facility entries
    skip = ["pharmacy", "chemist", "dental", "veterinary", "vet", "optician"]
    if any(kw in name.lower() for kw in skip):
        return None

    if element["type"] == "node":
        lat, lng = element.get("lat"), element.get("lon")
    else:
        c = element.get("center", {})
        lat, lng = c.get("lat"), c.get("lon")

    operator = (tags.get("operator") or tags.get("operator:type") or "").lower()
    if any(w in operator for w in ["government", "ministry", "county", "public", "national"]):
        ftype = "public"
    elif any(w in operator for w in ["mission", "church", "catholic", "protestant", "aga khan", "faith", "fbo"]):
        ftype = "mission"
    elif any(w in name.lower() for w in ["national", "kenyatta", "pumwani", "mbagathi", "county referral"]):
        ftype = "public"
    elif any(w in name.lower() for w in ["mission", "catholic", "church", "methodist", "presbyterian", "seventh"]):
        ftype = "mission"
    else:
        ftype = "private"

    phone = _normalise_phone(
        (tags.get("phone") or tags.get("contact:phone") or tags.get("telephone") or "").strip()
    )

    addr_parts = [tags.get(k, "").strip() for k in
                  ["addr:street", "addr:suburb", "addr:city", "addr:county"]]
    addr_parts = [p for p in addr_parts if p]
    if not addr_parts:
        addr_parts = [tags.get(k, "").strip() for k in ["addr:city", "is_in:city", "is_in:county"] if tags.get(k)]
    addr_parts.append("Kenya")
    address = ", ".join(dict.fromkeys(addr_parts))

    return {
        "name": name,
        "type": ftype,
        "address": address,
        "phone": phone,
        "lat": float(lat) if lat is not None else None,
        "lng": float(lng) if lng is not None else None,
    }


# ── DB seeding ────────────────────────────────────────────────────────────────

def seed(records: list[dict], dry_run: bool = False) -> None:
    if dry_run:
        print(f"\n[DRY RUN] Would upsert {len(records)} facilities")
        for h in records[:20]:
            coords = f"{h['lat']:.4f},{h['lng']:.4f}" if h["lat"] else "no coords"
            print(f"  {h['name'][:50]:<50} {h['type']:<8} {coords}")
        if len(records) > 20:
            print(f"  … and {len(records) - 20} more")
        return

    db = create_client(
        os.environ["SUPABASE_URL"],
        os.environ["SUPABASE_SERVICE_KEY"],
    )

    existing = db.table("hospitals").select("name").execute()
    existing_names = {_normalise(r["name"]) for r in (existing.data or [])}
    print(f"\nExisting in DB: {len(existing_names)}")

    new = [h for h in records if _normalise(h["name"]) not in existing_names]
    print(f"New to insert: {len(new)}")

    inserted = errors = 0
    for i in range(0, len(new), 50):
        batch = new[i:i + 50]
        try:
            db.table("hospitals").insert(batch).execute()
            inserted += len(batch)
            print(f"  Inserted {inserted}/{len(new)}", end="\r")
        except Exception as exc:
            print(f"\n  Batch error: {exc} — trying one by one")
            for h in batch:
                try:
                    db.table("hospitals").insert(h).execute()
                    inserted += 1
                except Exception:
                    errors += 1
        time.sleep(0.2)

    print(f"\nDone: {inserted} inserted, {errors} errors")
    print(f"Total in DB: {len(existing_names) + inserted}")


# ── entrypoint ────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Seed Kenya health facilities")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--osm-only", action="store_true", help="Skip KMHFL, use OSM only")
    parser.add_argument("--kmhfl-only", action="store_true", help="Skip OSM, use KMHFL only")
    parser.add_argument("--area", type=str, help="OSM area filter e.g. 'Nairobi'")
    args = parser.parse_args()

    all_records: list[dict] = []
    seen_names: set[str] = set()

    def add_records(source: list[dict]):
        for r in source:
            key = _normalise(r["name"])
            if key not in seen_names:
                all_records.append(r)
                seen_names.add(key)

    # 1. KMHFL (primary — authoritative MOH data)
    if not args.osm_only:
        kmhfl_records = fetch_kmhfl()
        if kmhfl_records:
            add_records(kmhfl_records)
        else:
            print("  KMHFL returned no data — check connectivity or API status")

    # 2. OSM (gap-fill)
    if not args.kmhfl_only:
        osm_records = fetch_osm(area=args.area)
        add_records(osm_records)  # only adds facilities not already in KMHFL

    if not all_records:
        print("\nNo facilities found. Check internet connection.")
        sys.exit(1)

    print(f"\nTotal unique facilities: {len(all_records)}")
    seed(all_records, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
