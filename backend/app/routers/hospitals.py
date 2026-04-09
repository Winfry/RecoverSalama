"""
Hospitals route — powers Flutter Screen 09 (Hospital Connect)
and the hospital React dashboard analytics page.
"""

from collections import defaultdict
from datetime import date, timedelta

from fastapi import APIRouter

from app.database import get_supabase_client
from app.services.ml.readmission_predictor import ReadmissionPredictor, _categorize

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
    Analytics for the hospital React dashboard (H6).

    Returns:
    - Summary cards: total patients, high risk count, avg pain, compliance rate
    - Risk breakdown: count per level for bar chart
    - Pain trend: 7-day daily averages for line chart
    - Readmission risks: top 5 patients by predicted 30-day readmission probability
    """
    db = get_supabase_client()
    today = date.today()
    week_ago_str = (today - timedelta(days=7)).isoformat()
    today_str = today.isoformat()

    # ── 1. Fetch all patients ─────────────────────────────────────────────
    patient_query = db.table("patients").select(
        "id, name, age, surgery_type, surgery_date"
    )
    if hospital_id:
        patient_query = patient_query.eq("hospital_id", hospital_id)
    patients_result = patient_query.execute()
    patients = patients_result.data or []
    patient_ids = [p["id"] for p in patients]
    total_patients = len(patients)

    # ── 2. Recovery logs (last 7 days) ───────────────────────────────────
    daily_pain: dict[str, list] = defaultdict(list)
    patient_latest_risk: dict[str, str] = {}   # first (latest) risk per patient
    patient_stats: dict[str, dict] = defaultdict(
        lambda: {"checkin_count": 0, "pain_values": [], "critical_count": 0}
    )
    patients_checked_in_today: set = set()

    if patient_ids:
        logs_result = (
            db.table("recovery_logs")
            .select("patient_id, risk_level, pain_level, created_at")
            .in_("patient_id", patient_ids)
            .gte("created_at", week_ago_str)
            .order("created_at", desc=True)   # latest first → used for current risk
            .execute()
        )
        for log in (logs_result.data or []):
            pid = log.get("patient_id")
            level = log.get("risk_level", "LOW")
            pain = log.get("pain_level")
            created = log.get("created_at", "")

            # Latest risk per patient (desc order → first occurrence = latest)
            if pid and pid not in patient_latest_risk:
                patient_latest_risk[pid] = level

            if pid:
                patient_stats[pid]["checkin_count"] += 1
                if level in ("HIGH", "EMERGENCY"):
                    patient_stats[pid]["critical_count"] += 1

            if pain is not None and pid:
                patient_stats[pid]["pain_values"].append(pain)
                daily_pain[created[:10]].append(pain)

            if created.startswith(today_str) and pid:
                patients_checked_in_today.add(pid)

    # ── 3. Risk breakdown (current state per patient) ─────────────────────
    risk_breakdown = {"LOW": 0, "MEDIUM": 0, "HIGH": 0, "EMERGENCY": 0}
    for level in patient_latest_risk.values():
        if level in risk_breakdown:
            risk_breakdown[level] += 1
    high_risk_count = risk_breakdown["HIGH"] + risk_breakdown["EMERGENCY"]

    # ── 4. Aggregate pain & compliance ────────────────────────────────────
    all_pain = [v for vals in daily_pain.values() for v in vals]
    avg_pain = round(sum(all_pain) / len(all_pain), 1) if all_pain else 0.0
    compliance_rate = (
        round(len(patients_checked_in_today) / total_patients * 100)
        if total_patients else 0
    )

    # ── 5. 7-day pain trend (daily averages) ──────────────────────────────
    pain_trend = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        values = daily_pain.get(day.isoformat(), [])
        pain_trend.append({
            "date": day.isoformat(),
            "day": day.strftime("%a"),          # "Mon", "Tue", ...
            "avg_pain": round(sum(values) / len(values), 1) if values else None,
            "checkins": len(values),
        })

    # ── 6. Active alerts ──────────────────────────────────────────────────
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

    # ── 7. Readmission risk (rules-only, all patients, sorted top 5) ──────
    predictor = ReadmissionPredictor()
    readmission_risks = []

    for patient in patients:
        pid = patient["id"]
        surgery_date = patient.get("surgery_date")
        days = (
            (today - date.fromisoformat(surgery_date)).days
            if surgery_date else 0
        )
        stats = patient_stats[pid]
        avg_p = (
            sum(stats["pain_values"]) / len(stats["pain_values"])
            if stats["pain_values"] else 0.0
        )
        prob = predictor.predict(
            age=patient.get("age") or 30,
            surgery_type=patient.get("surgery_type") or "Unknown",
            checkin_count=stats["checkin_count"],
            avg_pain=avg_p,
            critical_symptom_count=stats["critical_count"],
            days_since_surgery=days,
        )
        readmission_risks.append({
            "patient_id": pid,
            "patient_name": patient.get("name", "Unknown"),
            "surgery_type": patient.get("surgery_type", ""),
            "days_since_surgery": days,
            "probability": prob,
            "risk_category": _categorize(prob),
        })

    readmission_risks.sort(key=lambda x: x["probability"], reverse=True)

    return {
        "total_patients": total_patients,
        "high_risk_count": high_risk_count,
        "risk_breakdown": risk_breakdown,
        "active_alert_count": len(active_alerts),
        "recent_alerts": active_alerts,
        "avg_pain_this_week": avg_pain,
        "checkins_today": len(patients_checked_in_today),
        "compliance_rate": compliance_rate,
        "pain_trend": pain_trend,
        "readmission_risks": readmission_risks[:5],
    }


@router.get("/{hospital_id}")
async def get_hospital(hospital_id: str):
    """Get a single hospital's details."""
    db = get_supabase_client()
    result = db.table("hospitals").select("*").eq("id", hospital_id).execute()
    return result.data[0] if result.data else {"error": "Hospital not found"}
