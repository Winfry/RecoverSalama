"""
Hospitals route — powers Flutter Screen 09 (Hospital Connect).

Returns a list of hospitals near the patient. In MVP, this is
a static list of Nairobi hospitals. Later, it can integrate
with Kenya's Master Health Facility List (KMHFL) API.
"""

from fastapi import APIRouter

from app.database import get_supabase_client

router = APIRouter()


@router.get("/")
async def list_hospitals(
    lat: float | None = None,
    lng: float | None = None,
    hospital_type: str | None = None,
):
    """List hospitals — optionally filtered by type and location."""
    db = get_supabase_client()
    query = db.table("hospitals").select("*")

    if hospital_type:
        query = query.eq("type", hospital_type)

    result = query.execute()
    return result.data


@router.get("/{hospital_id}")
async def get_hospital(hospital_id: str):
    """Get a single hospital's details."""
    db = get_supabase_client()
    result = (
        db.table("hospitals").select("*").eq("id", hospital_id).execute()
    )
    return result.data[0] if result.data else {"error": "Hospital not found"}
