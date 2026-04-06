"""
Patient routes — profile creation, retrieval, update.

When a patient completes the 3-step profile setup in Flutter,
the app POSTs their data here. This stores it in Supabase and
returns the patient profile with a unique ID.

The hospital dashboard also GETs patient lists from here.
"""

from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user
from app.database import get_supabase_client
from app.schemas.patient import PatientCreate, PatientResponse

router = APIRouter()


@router.post("/profile", response_model=PatientResponse)
async def create_profile(
    patient: PatientCreate,
    user: dict = Depends(get_current_user),
):
    """Save patient profile from Flutter app's 3-step setup."""
    db = get_supabase_client()

    # Link patient to the authenticated user
    data = patient.model_dump()
    data["user_id"] = user["id"]

    result = db.table("patients").insert(data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to save profile")

    return result.data[0]


@router.get("/me", response_model=PatientResponse)
async def get_my_profile(user: dict = Depends(get_current_user)):
    """Get the current user's patient profile."""
    db = get_supabase_client()
    result = (
        db.table("patients")
        .select("*")
        .eq("user_id", user["id"])
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=404, detail="No profile found")

    return result.data[0]


@router.get("/{patient_id}", response_model=PatientResponse)
async def get_patient(patient_id: str):
    """Get a single patient — used by both Flutter app and hospital dashboard."""
    db = get_supabase_client()
    result = db.table("patients").select("*").eq("id", patient_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Patient not found")

    return result.data[0]


@router.get("/")
async def list_patients(hospital_id: str | None = None):
    """List patients — filtered by hospital for the dashboard."""
    db = get_supabase_client()
    query = db.table("patients").select("*")

    if hospital_id:
        query = query.eq("hospital_id", hospital_id)

    result = query.order("created_at", desc=True).execute()
    return result.data
