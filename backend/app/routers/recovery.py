"""
Recovery routes — daily check-ins, diet plans, mood tracking.

This is where the core recovery logic lives:
1. Patient submits daily check-in (pain, symptoms, mood) from Flutter Screen 04
2. Backend runs the ML risk classifier on the symptoms
3. If risk = HIGH/EMERGENCY → triggers alert to hospital
4. Returns updated recovery plan to the Flutter app

Diet endpoint returns surgery-specific meal plans from the Kenya
Nutrition Manual, filtered by the patient's allergies.
"""

from fastapi import APIRouter, HTTPException

from app.database import get_supabase_client
from app.schemas.recovery import CheckInRequest, CheckInResponse, DietResponse
from app.services.ml.risk_scorer import RiskScorer
from app.services.ml.diet_engine import DietEngine

router = APIRouter()
risk_scorer = RiskScorer()
diet_engine = DietEngine()


@router.post("/checkin", response_model=CheckInResponse)
async def submit_checkin(checkin: CheckInRequest):
    """
    Daily check-in from Flutter app.
    1. Save check-in data to Supabase
    2. Run ML risk classifier
    3. Trigger alert if risk is HIGH or EMERGENCY
    4. Return risk level + recovery recommendations
    """
    db = get_supabase_client()

    # Score risk using ML model
    risk_level = risk_scorer.predict(
        pain_level=checkin.pain_level,
        symptoms=checkin.symptoms,
        mood=checkin.mood,
        days_since_surgery=checkin.days_since_surgery,
    )

    # Save to database
    record = {
        "patient_id": checkin.patient_id,
        "pain_level": checkin.pain_level,
        "symptoms": checkin.symptoms,
        "mood": checkin.mood,
        "risk_level": risk_level,
        "days_since_surgery": checkin.days_since_surgery,
    }
    db.table("recovery_logs").insert(record).execute()

    # Trigger alert if critical
    if risk_level in ("HIGH", "EMERGENCY"):
        db.table("alerts").insert({
            "patient_id": checkin.patient_id,
            "risk_level": risk_level,
            "symptoms": checkin.symptoms,
            "message": f"Patient reported {risk_level} risk symptoms",
        }).execute()

    return CheckInResponse(
        risk_level=risk_level,
        message=_get_risk_message(risk_level),
    )


@router.get("/diet", response_model=DietResponse)
async def get_diet_plan(
    surgery_type: str,
    day: int,
    allergies: str = "",
):
    """
    Get diet recommendations for today.
    Uses the Kenya National Clinical Nutrition Manual (MOH 2010)
    surgical diet progression table.
    """
    allergy_list = [a.strip() for a in allergies.split(",") if a.strip()]

    plan = diet_engine.get_plan(
        surgery_type=surgery_type,
        day=day,
        allergies=allergy_list,
    )

    return plan


@router.post("/mood")
async def submit_mood(patient_id: str, mood: str, notes: str | None = None):
    """Save mental health check-in from Flutter Screen 07."""
    db = get_supabase_client()
    db.table("mood_logs").insert({
        "patient_id": patient_id,
        "mood": mood,
        "notes": notes,
    }).execute()
    return {"status": "saved"}


def _get_risk_message(risk_level: str) -> str:
    messages = {
        "LOW": "Looking good! Keep up your recovery routine.",
        "MEDIUM": "Monitor your symptoms. Contact your doctor if they worsen.",
        "HIGH": "Your symptoms need attention. Please contact your hospital.",
        "EMERGENCY": "Seek immediate medical help. Call 999 or go to the nearest hospital.",
    }
    return messages.get(risk_level, "Check-in recorded.")
