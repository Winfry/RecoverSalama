"""
Recovery routes — daily check-ins, diet plans, mood tracking, dashboard.

This is where the core recovery logic lives:
1. Patient submits daily check-in (pain, symptoms, mood) from Flutter Screen 04
2. Backend runs the ML risk classifier on the symptoms
3. If risk = HIGH/EMERGENCY → triggers alert to hospital
4. Returns updated recovery plan to the Flutter app

Diet endpoint returns surgery-specific meal plans from the Kenya
Nutrition Manual, filtered by the patient's allergies.
"""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user, get_patient_id
from app.database import get_supabase_client
from app.schemas.recovery import (
    CheckInRequest,
    CheckInResponse,
    DietResponse,
    DashboardResponse,
    MoodRequest,
    MoodResponse,
)
from app.services.ml.risk_scorer import RiskScorer
from app.services.ml.diet_engine import DietEngine
from app.services.ml.mood_classifier import MoodClassifier
from app.services.alert_service import AlertService
from app.services.ai.gemini_service import GeminiService

router = APIRouter()
risk_scorer = RiskScorer()
diet_engine = DietEngine()
alert_service = AlertService()


@router.post("/checkin", response_model=CheckInResponse)
async def submit_checkin(
    checkin: CheckInRequest,
    patient_id: str = Depends(get_patient_id),
):
    """
    Daily check-in from Flutter app.
    1. Save check-in data to Supabase
    2. Run ML risk classifier
    3. Trigger alert if risk is HIGH or EMERGENCY
    4. Return risk level + recovery recommendations
    """
    db = get_supabase_client()

    # Fetch patient profile to pass surgery_type, age, gender to risk scorer
    patient_row = (
        db.table("patients")
        .select("phone, surgery_type, age, gender")
        .eq("id", patient_id)
        .maybe_single()
        .execute()
    )
    patient_data = patient_row.data or {}
    surgery_type = patient_data.get("surgery_type", "Unknown") or "Unknown"
    gender = patient_data.get("gender", "") or ""

    # Use age directly from the patients table (stored as integer)
    age = patient_data.get("age") or 0
    try:
        age = int(age)
    except (TypeError, ValueError):
        age = 0

    # Validation: Ensure days_since_surgery is non-negative
    current_days = max(0, checkin.days_since_surgery)

    # Score risk using two-layer system (rules + Gemini)
    risk_result = await risk_scorer.assess_risk(
        pain_level=checkin.pain_level,
        symptoms=checkin.symptoms,
        mood=checkin.mood,
        days_since_surgery=current_days,
        surgery_type=surgery_type,
        age=age,
        gender=gender,
    )

    risk_level = risk_result.get("risk_level", "LOW")

    # Prevent duplicate check-ins on the same calendar day.
    # If the patient already checked in today, return the existing result
    # instead of creating a second record and firing duplicate alerts.
    today_str = date.today().isoformat()
    existing = (
        db.table("recovery_logs")
        .select("risk_level, days_since_surgery")
        .eq("patient_id", patient_id)
        .gte("created_at", today_str)
        .limit(1)
        .execute()
    )
    if existing.data:
        existing_risk = existing.data[0].get("risk_level", "LOW")
        return CheckInResponse(
            risk_level=existing_risk,
            message=_get_risk_message(existing_risk),
            reasoning="Check-in already submitted today.",
            recommendation="You have already checked in today. See you tomorrow!",
        )

    # Save to database
    record = {
        "patient_id": patient_id,
        "pain_level": checkin.pain_level,
        "symptoms": checkin.symptoms,
        "mood": checkin.mood,
        "risk_level": risk_level,
        "days_since_surgery": checkin.days_since_surgery,
    }
    db.table("recovery_logs").insert(record).execute()

    patient_phone = patient_data.get("phone", "") or ""

    # AlertService handles everything: WhatsApp to patient,
    # caregiver alert, hospital emergency alert, and DB alert record.
    # Replaces the inline alert block that was here before.
    await alert_service.process_checkin(
        patient_id=patient_id,
        phone=patient_phone,
        pain_level=checkin.pain_level,
        risk_level=risk_level,
        symptom=", ".join(checkin.symptoms) if checkin.symptoms else "none",
        ai_tip=risk_result.get("recommendation", ""),
        channel="app",
    )

    return CheckInResponse(
        risk_level=risk_level,
        message=_get_risk_message(risk_level),
        reasoning=risk_result.get("reasoning", ""),
        recommendation=risk_result.get("recommendation", _get_risk_message(risk_level)),
    )


@router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(patient_id: str = Depends(get_patient_id)):
    """
    Dashboard data for Flutter Screen 05.
    Returns recovery stage, activities, AI tip, and latest check-in.
    """
    db = get_supabase_client()

    # Get patient info
    patient = db.table("patients").select("*").eq("id", patient_id).execute()
    if not patient.data:
        raise HTTPException(status_code=404, detail="Patient not found")

    p = patient.data[0]
    surgery_date = p.get("surgery_date")

    # Calculate days since surgery — slice to 10 chars handles both
    # "2025-04-01" and "2025-04-01T00:00:00" formats from Supabase
    if surgery_date:
        try:
            days = (date.today() - date.fromisoformat(str(surgery_date)[:10])).days
        except (ValueError, TypeError):
            days = 0
    else:
        days = 0

    # Get latest check-in
    latest_log = (
        db.table("recovery_logs")
        .select("*")
        .eq("patient_id", patient_id)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )

    latest_checkin = latest_log.data[0] if latest_log.data else None
    risk_level = latest_checkin.get("risk_level", "LOW") if latest_checkin else "LOW"

    # Determine recovery stage
    stage = _get_recovery_stage(days)

    return DashboardResponse(
        patient_name=p.get("name", ""),
        surgery_type=p.get("surgery_type", ""),
        surgery_date=surgery_date or "",
        days_since_surgery=days,
        recovery_day=days,
        total_recovery_days=_get_total_recovery_days(p.get("surgery_type", "")),
        stage_name=stage["name"],
        stage_description=stage["description"],
        allowed_activities=stage["allowed"],
        restricted_activities=stage["restricted"],
        risk_level=risk_level,
        ai_tip=_get_ai_tip(days, p.get("surgery_type", "")),
        latest_pain=latest_checkin.get("pain_level", 0) if latest_checkin else 0,
        latest_mood=latest_checkin.get("mood", "") if latest_checkin else "",
    )


@router.get("/history")
async def get_history(
    patient_id: str = Depends(get_patient_id),
    limit: int = 14,
):
    """Get recent check-in history for the patient."""
    db = get_supabase_client()
    result = (
        db.table("recovery_logs")
        .select("*")
        .eq("patient_id", patient_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )
    return result.data


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


@router.post("/mood", response_model=MoodResponse)
async def submit_mood(
    mood_data: MoodRequest,
    patient_id: str = Depends(get_patient_id),
):
    """Save mental health check-in from Flutter Screen 07.

    Combines rule-based trend detection (MoodClassifier) with Gemini AI
    to understand both mood patterns AND complex emotions the patient
    describes in their own words."""
    db = get_supabase_client()

    # Fetch history BEFORE saving the new mood so the classifier
    # sees the previous trend, not the current mood counted twice.
    history = (
        db.table("mood_logs")
        .select("mood")
        .eq("patient_id", patient_id)
        .order("created_at", desc=True)
        .limit(7)
        .execute()
    )
    recent_moods = [row["mood"] for row in (history.data or [])]

    # Now save the new mood log
    db.table("mood_logs").insert({
        "patient_id": patient_id,
        "mood": mood_data.mood,
        "notes": mood_data.notes,
    }).execute()

    # Fetch patient context for personalised AI response
    patient_result = db.table("patients").select("name, surgery_type, surgery_date").eq("id", patient_id).execute()
    patient = patient_result.data[0] if patient_result.data else {}
    surgery_date = patient.get("surgery_date")
    try:
        days_since_surgery = (date.today() - date.fromisoformat(str(surgery_date)[:10])).days if surgery_date else 0
    except (ValueError, TypeError):
        days_since_surgery = 0

    # Rule-based classification for mental health level (stable/monitor/needs_support)
    classifier = MoodClassifier()
    assessment = classifier.classify(mood_data.mood, recent_moods)

    # Gemini AI for a personalised, nuanced support message that understands
    # whatever the patient wrote — complex emotions, Kiswahili, or mixed language
    gemini = GeminiService()
    support_message = await gemini.support_mood(
        mood=mood_data.mood,
        patient_context={
            "name": patient.get("name", ""),
            "surgery_type": patient.get("surgery_type", ""),
            "days_since_surgery": days_since_surgery,
        },
        mood_history=recent_moods,
        notes=mood_data.notes,
    )

    return MoodResponse(
        status="saved",
        support_message=support_message,
        mental_health_level=assessment["level"],
    )


# ── Helper functions ──────────────────────────────────────────

def _get_risk_message(risk_level: str) -> str:
    messages = {
        "LOW": "Looking good! Keep up your recovery routine.",
        "MEDIUM": "Monitor your symptoms. Contact your doctor if they worsen.",
        "HIGH": "Your symptoms need attention. Please contact your hospital.",
        "EMERGENCY": "Seek immediate medical help. Call 999 or go to the nearest hospital.",
    }
    return messages.get(risk_level, "Check-in recorded.")


# Expected total recovery days per surgery type.
# Source: Kenya MOH clinical guidelines + WHO surgical safety standards.
# Used for the Flutter progress bar so patients see accurate timelines.
_RECOVERY_DAYS: dict[str, int] = {
    "Caesarean Section": 42,
    "Appendectomy": 21,
    "Hernia Repair": 21,
    "Inguinal Hernia Repair": 21,
    "Cholecystectomy": 28,
    "Knee Replacement": 90,
    "Knee Replacement (TKR)": 90,
    "Hip Replacement": 90,
    "Hip Replacement (THR)": 90,
    "Laparotomy": 42,
    "Hysterectomy": 42,
    "Open Fracture Repair": 84,
    "Tubal Ligation": 14,
    "Prostatectomy": 42,
    "Thyroidectomy": 21,
    "Mastectomy": 42,
    "Myomectomy": 42,
    "Cardiac Surgery": 180,
}


def _get_total_recovery_days(surgery_type: str) -> int:
    """Return expected recovery days for a surgery type. Defaults to 42."""
    return _RECOVERY_DAYS.get(surgery_type, 42)


def _get_recovery_stage(days: int) -> dict:
    if days <= 3:
        return {
            "name": "Stage 1 — Acute Recovery",
            "description": "Your body is in the critical healing phase. Rest is essential.",
            "allowed": ["Gentle walking to bathroom", "Deep breathing exercises", "Light stretching in bed"],
            "restricted": ["Lifting anything heavy", "Driving", "Strenuous exercise", "Bending at waist"],
        }
    elif days <= 14:
        return {
            "name": "Stage 2 — Early Healing",
            "description": "Wound healing is underway. Gradually increase light activity.",
            "allowed": ["Short walks (10-15 min)", "Light household tasks", "Reading and gentle stretching"],
            "restricted": ["Lifting over 5kg", "Running or jogging", "Swimming", "Sexual activity"],
        }
    elif days <= 30:
        return {
            "name": "Stage 3 — Progressive Recovery",
            "description": "Strength is returning. You can do more, but listen to your body.",
            "allowed": ["Longer walks (30 min)", "Light cooking", "Return to desk work", "Gentle yoga"],
            "restricted": ["Heavy lifting", "Contact sports", "High-intensity exercise"],
        }
    else:
        return {
            "name": "Stage 4 — Full Recovery",
            "description": "Most activities can be resumed. Follow up with your surgeon.",
            "allowed": ["Most normal activities", "Moderate exercise", "Driving (if comfortable)", "Return to work"],
            "restricted": ["Extreme sports (check with doctor)", "Very heavy lifting"],
        }


def _get_ai_tip(days: int, surgery_type: str) -> str:
    if days <= 3:
        return "Focus on hydration and rest. Drink at least 8 glasses of water today. Your body is using extra energy to heal."
    elif days <= 7:
        return "Try a 10-minute walk today. Movement helps prevent blood clots and speeds up healing. Start slow and increase gradually."
    elif days <= 14:
        return "You're doing great! This week, focus on protein-rich foods like eggs, beans, and lentils to support wound healing."
    elif days <= 30:
        return "Your strength is returning. Gentle stretching and short walks will help rebuild your energy. Keep attending follow-up appointments."
    else:
        return "You've come a long way! Continue eating well and staying active. Schedule your final follow-up with your surgeon if you haven't already."
