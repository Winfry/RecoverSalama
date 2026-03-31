"""
Hospitals route — powers Flutter Screen 09 (Hospital Connect)
and the hospital React dashboard analytics page.

Returns a list of hospitals near the patient. In MVP, this is
a static list of Nairobi hospitals. Later, it can integrate
with Kenya's Master Health Facility List (KMHFL) API.
"""

from datetime import date, timedelta

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


@router.get("/analytics")
async def get_analytics(hospital_id: str | None = None):
    """
    Analytics summary for the hospital React dashboard.

    Returns patient counts, risk breakdown, alert stats, and
    pain averages for the past 7 days — filtered by hospital.
    """
    db = get_supabase_client()

    today = date.today().isoformat()
    week_ago = (date.today() - timedelta(days=7)).isoformat()

    # ── 1. Patient count ──────────────────────────────────────
    patient_query = db.table("patients").select("id", count="exact")
    if hospital_id:
        patient_query = patient_query.eq("hospital_id", hospital_id)
    patients_result = patient_query.execute()
    total_patients = patients_result.count or 0

    # Collect patient IDs for scoped sub-queries
    patient_ids = [p["id"] for p in (patients_result.data or [])]

    # ── 2. Risk level breakdown (last 7 days) ─────────────────
    risk_breakdown = {"LOW": 0, "MEDIUM": 0, "HIGH": 0, "EMERGENCY": 0}
    avg_pain = 0.0
    checkins_today = 0

    if patient_ids:
        logs_result = (
            db.table("recovery_logs")
            .select("risk_level, pain_level, created_at")
            .in_("patient_id", patient_ids)
            .gte("created_at", week_ago)
            .execute()
        )
        logs = logs_result.data or []

        pain_values = []
        for log in logs:
            level = log.get("risk_level", "LOW")
            if level in risk_breakdown:
                risk_breakdown[level] += 1
            if log.get("pain_level") is not None:
                pain_values.append(log["pain_level"])
            if log.get("created_at", "").startswith(today):
                checkins_today += 1

        avg_pain = round(sum(pain_values) / len(pain_values), 1) if pain_values else 0.0

    # ── 3. Active alerts ──────────────────────────────────────
    alerts_query = (
        db.table("alerts")
        .select("id, risk_level, symptoms, message, created_at")
        .eq("status", "active")
        .order("created_at", desc=True)
        .limit(10)
    )
    if hospital_id:
        alerts_query = alerts_query.eq("hospital_id", hospital_id)
    alerts_result = alerts_query.execute()
    active_alerts = alerts_result.data or []

    return {
        "total_patients": total_patients,
        "risk_breakdown": risk_breakdown,
        "active_alert_count": len(active_alerts),
        "recent_alerts": active_alerts,
        "avg_pain_this_week": avg_pain,
        "checkins_today": checkins_today,
    }


@router.get("/{hospital_id}")
async def get_hospital(hospital_id: str):
    """Get a single hospital's details."""
    db = get_supabase_client()
    result = (
        db.table("hospitals").select("*").eq("id", hospital_id).execute()
    )
    return result.data[0] if result.data else {"error": "Hospital not found"}
