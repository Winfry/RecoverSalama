"""
Scheduler — daily 6 AM morning reminders for active patients.

Runs inside the FastAPI process using APScheduler (no separate server needed).
Starts when FastAPI starts. Stops when FastAPI stops.

WHAT IT DOES:
  Every morning at exactly 6:00 AM Nairobi time (EAT, UTC+3):
    1. Fetch all patients from Supabase who qualify for a reminder
    2. For each qualifying patient, send a WhatsApp morning check-in prompt
    3. Log how many were sent, skipped, or failed

THE 5 FILTERS (a patient must pass ALL of them to receive a message):
    1. Still in recovery      — surgery was within the last 42 days
    2. Not yet checked in     — no check-in submitted yet today (Nairobi date)
    3. Notifications on       — notifications_enabled = true in their profile
    4. Has a phone number     — can't send WhatsApp to a null phone
    5. Account is active      — is_active = true (not deleted or test account)

TIMEZONE DESIGN:
    APScheduler is initialised with Africa/Nairobi timezone.
    This means "hour=6" literally means 6 AM Nairobi, regardless of
    what timezone the server runs in (usually UTC).
    APScheduler converts to UTC internally — we never think about it.

    "Today" for date comparisons is also computed in Nairobi time,
    not server local time, so the check-in boundary is always correct
    for the patient's day.

MISFIRE GRACE TIME:
    Render.com free tier sometimes restarts the server. If the server
    was down at 6 AM and comes back up within 60 minutes, APScheduler
    will still run the job rather than skip it silently.
"""

import logging
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from datetime import date as date_type
from zoneinfo import ZoneInfo

from apscheduler.schedulers.asyncio import AsyncIOScheduler

from app.database import get_supabase_client
from app.services.channels.whatsapp_service import WhatsAppService

logger = logging.getLogger(__name__)

# East Africa Time — Nairobi, Kenya
NAIROBI = ZoneInfo("Africa/Nairobi")


# ── The Job ────────────────────────────────────────────────────────────────

async def send_morning_reminders() -> dict:
    """
    The job that runs every morning at 6:00 AM Nairobi time.

    Queries Supabase for qualifying patients, applies all 5 filters,
    and sends a WhatsApp reminder to each one who needs it.
    """
    db = get_supabase_client()
    whatsapp = WhatsAppService()

    # ── Compute today in Nairobi time ─────────────────────────────────────
    # datetime.now(NAIROBI) gives the current moment with Nairobi timezone
    # attached. .date() strips the time, leaving just the calendar date.
    # This ensures "today" is April 8 Nairobi, even if the server's UTC
    # clock still shows April 7.
    now_nairobi = datetime.now(NAIROBI)
    today_nairobi = now_nairobi.date()

    # For the Supabase check-in query, we need "start of today Nairobi"
    # as a UTC timestamp string. Supabase stores all timestamps in UTC,
    # so we must convert the Nairobi midnight boundary to UTC before querying.
    #
    # Example: midnight April 8 Nairobi (00:00 EAT) = 21:00 April 7 UTC
    # So we query: created_at >= '2026-04-07T21:00:00+00:00'
    # This correctly captures any check-in done since midnight Nairobi.
    nairobi_midnight = now_nairobi.replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    today_start_utc = nairobi_midnight.astimezone(timezone.utc).isoformat()

    logger.info(
        f"[Scheduler] Running morning reminders for "
        f"{today_nairobi} (Nairobi). "
        f"UTC boundary: {today_start_utc}"
    )

    # ── Fetch candidates from Supabase (Filters 3, 4, 5 in DB) ───────────
    # Filters 1 and 2 need Python logic so they run per-patient below.
    # We apply filters 3, 4, 5 in the query to minimise rows returned.
    try:
        result = (
            db.table("patients")
            .select("id, name, phone, surgery_date")
            .eq("notifications_enabled", True)
            .eq("is_active", True)
            .not_.is_("phone", "null")
            .not_.is_("surgery_date", "null")
            .execute()
        )
        patients = result.data or []
    except Exception as e:
        logger.error(f"[Scheduler] Failed to fetch patients: {e}")
        return {"error": str(e)}

    logger.info(f"[Scheduler] {len(patients)} candidate(s) after DB filters.")

    # ── Per-patient filters and send ──────────────────────────────────────
    sent = 0
    skipped_recovered = 0
    skipped_checked_in = 0
    errors = 0

    for patient in patients:
        try:
            # ── Filter 1: Still within 42-day recovery window ─────────────
            surgery_date = date_type.fromisoformat(
                str(patient["surgery_date"])[:10]
            )
            days_since = (today_nairobi - surgery_date).days

            if days_since > 42:
                skipped_recovered += 1
                continue

            # ── Filter 2: No check-in yet today ───────────────────────────
            # Query recovery_logs for any entry since midnight Nairobi (UTC).
            checkin_today = (
                db.table("recovery_logs")
                .select("id")
                .eq("patient_id", patient["id"])
                .gte("created_at", today_start_utc)
                .limit(1)
                .execute()
            )

            if checkin_today.data:
                skipped_checked_in += 1
                continue

            # ── All 5 filters passed — send the reminder ──────────────────
            recovery_day = days_since + 1  # Day 0 of surgery = Day 1 of recovery

            await whatsapp.send_morning_reminder(
                phone=patient["phone"],
                patient_name=patient.get("name", "Mgonjwa"),
                recovery_day=recovery_day,
            )
            sent += 1
            logger.debug(
                f"[Scheduler] Sent to {patient.get('name')} "
                f"(Day {recovery_day})"
            )

        except Exception as e:
            logger.error(
                f"[Scheduler] Error processing patient "
                f"{patient.get('id', '?')}: {e}"
            )
            errors += 1

    # ── Summary log ───────────────────────────────────────────────────────
    logger.info(
        f"[Scheduler] Done. "
        f"Sent: {sent} | "
        f"Skipped (recovered): {skipped_recovered} | "
        f"Skipped (checked in): {skipped_checked_in} | "
        f"Errors: {errors}"
    )

    return {
        "sent": sent,
        "skipped_recovered": skipped_recovered,
        "skipped_checked_in": skipped_checked_in,
        "errors": errors,
        "date_nairobi": str(today_nairobi),
    }


# ── Scheduler Factory ──────────────────────────────────────────────────────

def create_scheduler() -> AsyncIOScheduler:
    """
    Build and configure the APScheduler instance.

    Called once at FastAPI startup via the lifespan handler in main.py.
    Returns a configured but not-yet-started scheduler.

    The timezone=NAIROBI argument means every cron expression in this
    scheduler is interpreted in Nairobi local time. "hour=6" = 6 AM
    Nairobi, no matter what the server clock says.

    misfire_grace_time=3600:
        If the server was down at 6 AM and restarts within 60 minutes,
        the job still runs. Without this, a missed job is silently dropped.
        3600 seconds = 1 hour grace window.
    """
    scheduler = AsyncIOScheduler(timezone=NAIROBI)

    scheduler.add_job(
        send_morning_reminders,
        trigger="cron",
        hour=6,
        minute=0,
        id="morning_reminders",
        replace_existing=True,
        misfire_grace_time=3600,
    )

    logger.info(
        "[Scheduler] Configured: morning reminders at 06:00 Africa/Nairobi"
    )

    return scheduler
