"""
Patient routes — profile creation, retrieval, discharge, and check-in history.

Flutter app POSTs patient profiles here on first setup.
Hospital dashboard POSTs discharge data here when a patient is sent home.
"""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user
from app.database import get_supabase_client
from app.schemas.patient import PatientCreate, PatientResponse, DischargeRequest
from app.services.channels.whatsapp_service import WhatsAppService

router = APIRouter()


@router.post("/profile", response_model=PatientResponse)
async def create_profile(
    patient: PatientCreate,
    user: dict = Depends(get_current_user),
):
    """Save patient profile from Flutter app's 3-step setup."""
    db = get_supabase_client()
    data = patient.model_dump()
    data["user_id"] = user["id"]
    result = db.table("patients").insert(data).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to save profile")
    return result.data[0]


@router.get("/me", response_model=PatientResponse)
async def get_my_profile(user: dict = Depends(get_current_user)):
    """Get the current user's patient profile — used by Flutter app."""
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


@router.get("/")
async def list_patients(
    hospital_id: str | None = None,
    _user: dict = Depends(get_current_user),
):
    """List patients — filtered by hospital for the dashboard."""
    db = get_supabase_client()
    query = db.table("patients").select("*")
    if hospital_id:
        query = query.eq("hospital_id", hospital_id)
    result = query.order("created_at", desc=True).execute()
    return result.data


@router.get("/{patient_id}/history")
async def get_patient_history(
    patient_id: str,
    limit: int = 14,
    _user: dict = Depends(get_current_user),
):
    """
    Check-in history for a patient — used by the hospital dashboard's
    PatientDetail screen to show pain trend and symptom log.
    Returns the last `limit` check-ins, newest first.
    """
    db = get_supabase_client()
    result = (
        db.table("recovery_logs")
        .select("pain_level, symptoms, mood, risk_level, days_since_surgery, created_at")
        .eq("patient_id", patient_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )
    return result.data or []


@router.post("/{patient_id}/discharge", response_model=PatientResponse)
async def discharge_patient(
    patient_id: str,
    discharge_data: DischargeRequest,
    _user: dict = Depends(get_current_user),
):
    """
    Formally discharge a patient from hospital.

    Records the discharge date, assigned doctor, and doctor's notes.
    Sends a WhatsApp message to the patient notifying them that their
    SalamaRecover recovery plan has started.

    Called by the hospital dashboard DischargeForm (H7).
    """
    db = get_supabase_client()

    # Verify patient exists
    check = db.table("patients").select("id, name, phone").eq("id", patient_id).execute()
    if not check.data:
        raise HTTPException(status_code=404, detail="Patient not found")

    patient = check.data[0]

    # Update patient record with discharge info
    result = (
        db.table("patients")
        .update({
            "is_discharged": True,
            "discharge_date": discharge_data.discharge_date.isoformat(),
            "assigned_doctor": discharge_data.assigned_doctor,
            "discharge_notes": discharge_data.discharge_notes,
        })
        .eq("id", patient_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to record discharge")

    # Send WhatsApp notification to patient (non-blocking — don't fail if WhatsApp fails)
    phone = patient.get("phone", "")
    if phone:
        try:
            whatsapp = WhatsAppService()
            days_since = (date.today() - discharge_data.discharge_date).days
            message = (
                f"*SalamaRecover — You Have Been Discharged* 🏥\n\n"
                f"Hello {patient['name']},\n\n"
                f"You have been officially discharged by Dr. {discharge_data.assigned_doctor}.\n\n"
                f"*Your recovery plan has started.* Open the SalamaRecover app to see:\n"
                f"• Your doctor's personal instructions\n"
                f"• Your daily diet plan\n"
                f"• How to do your daily check-ins\n\n"
                f"*Doctor's notes:*\n{discharge_data.discharge_notes or 'See your app for instructions.'}\n\n"
                f"Check in every day — it helps your care team monitor your recovery. "
                f"Pona salama! 💚"
            )
            await whatsapp.send_message(phone=phone, message=message)
        except Exception:
            # WhatsApp failure must never block discharge recording
            pass

    return result.data[0]


@router.get("/{patient_id}", response_model=PatientResponse)
async def get_patient(
    patient_id: str,
    _user: dict = Depends(get_current_user),
):
    """Get a single patient — used by Flutter app and hospital dashboard."""
    db = get_supabase_client()
    result = db.table("patients").select("*").eq("id", patient_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Patient not found")
    return result.data[0]
