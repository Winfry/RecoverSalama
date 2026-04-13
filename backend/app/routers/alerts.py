"""
Alerts route — powers the hospital dashboard's Alert Centre.

When the ML risk classifier flags a patient as HIGH or EMERGENCY,
an alert record is created in the database. The hospital dashboard
polls this endpoint (or uses Supabase real-time) to show alerts
to clinical staff so they can intervene early.

This is how SalamaRecover prevents complications —
catching warning signs before they become emergencies.
"""

from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user
from app.database import get_supabase_client

router = APIRouter()


@router.get("/")
async def list_alerts(
    hospital_id: str | None = None,
    status: str = "active",
    _user: dict = Depends(get_current_user),
):
    """Get active alerts — used by React hospital dashboard Alert Centre."""
    db = get_supabase_client()
    query = db.table("alerts").select("*, patients(*)").eq("status", status)

    if hospital_id:
        query = query.eq("hospital_id", hospital_id)

    result = query.order("created_at", desc=True).execute()
    return result.data


@router.patch("/{alert_id}")
async def update_alert(
    alert_id: str,
    status: str,
    _user: dict = Depends(get_current_user),
):
    """Mark alert as acknowledged or resolved by hospital staff."""
    if status not in ("acknowledged", "resolved"):
        raise HTTPException(
            status_code=400,
            detail="Status must be 'acknowledged' or 'resolved'",
        )

    db = get_supabase_client()
    result = (
        db.table("alerts")
        .update({"status": status})
        .eq("id", alert_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=404, detail="Alert not found")

    return result.data[0]
