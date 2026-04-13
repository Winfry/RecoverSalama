"""
Alert Service — the safety coordinator for all check-in responses.

This is the single decision-making layer that determines what happens
after every patient check-in, regardless of which channel it came from
(Flutter app, USSD feature phone, or WhatsApp).

WHAT IT DOES:
  After a check-in is saved, this service is called with the result.
  It looks up the patient's full profile, determines who needs to be
  notified based on the risk level, and triggers the right messages
  through WhatsAppService.

  This centralised design means all three channels (Flutter, USSD,
  WhatsApp) share one consistent safety response. When Phase 4 adds
  new channels, only this file needs to be updated.

RISK LEVELS AND RESPONSES:
  LOW      → WhatsApp summary to patient only
  MEDIUM   → WhatsApp summary to patient only
  HIGH     → Summary to patient + alert to caregiver + DB alert record
  EMERGENCY→ Summary to patient + alert to caregiver + alert to hospital
             + EMERGENCY DB alert record

WHY THIS MATTERS:
  A patient who checks in via USSD on a feature phone with no internet
  receives the exact same safety response as one using the Flutter app.
  Their caregiver gets notified. Their hospital gets alerted. Their data
  appears on the hospital dashboard. No patient is a second-class user
  because of the device they own.
"""

import datetime
import logging

from app.database import get_supabase_client
from app.services.channels.whatsapp_service import WhatsAppService

logger = logging.getLogger(__name__)


class AlertService:

    def __init__(self):
        self._whatsapp = WhatsAppService()

    # ── Main Entry Point ───────────────────────────────────────

    async def process_checkin(
        self,
        patient_id: str | None,
        phone: str,
        pain_level: int,
        risk_level: str,
        symptom: str,
        ai_tip: str = "",
        channel: str = "app",
    ) -> dict:
        """
        Called after every check-in from any channel.

        This is the single function all three channels call after
        saving a check-in. It handles all downstream notifications.

        Parameters:
          patient_id  — Supabase patient UUID (None if not yet registered)
          phone       — patient's Kenyan phone number (+254...)
          pain_level  — numeric pain score 0-10
          risk_level  — LOW | MEDIUM | HIGH | EMERGENCY
          symptom     — primary symptom reported
          ai_tip      — personalised AI tip from Gemini (if available)
          channel     — app | ussd | whatsapp (for logging)

        Returns a dict summarising what actions were taken.
        """
        actions_taken = []

        # Step 1: Look up full patient profile from Supabase
        patient = await self._get_patient_profile(patient_id, phone)

        # Step 2: Build human-readable pain label
        pain_label = self._pain_label(pain_level)
        recovery_day = patient.get("recovery_day", 1)

        # Step 3: Always send the patient their own summary
        # Every patient deserves acknowledgement and their AI tip,
        # no matter what risk level they reported.
        patient_phone = patient.get("phone", phone)
        if patient_phone:
            await self._whatsapp.send_daily_summary(
                phone=patient_phone,
                patient_name=patient.get("name", "Mgonjwa"),
                recovery_day=recovery_day,
                pain_label=pain_label,
                risk_level=risk_level,
                ai_tip=ai_tip or self._default_tip(recovery_day, risk_level),
            )
            actions_taken.append("patient_summary_sent")

        # Step 4: HIGH or EMERGENCY — notify caregiver
        # The caregiver registered during profile setup now serves
        # their purpose: they are the first human safety net.
        if risk_level in ("HIGH", "EMERGENCY"):
            caregiver_phone = patient.get("caregiver_phone")
            if caregiver_phone:
                await self._whatsapp.send_caregiver_alert(
                    caregiver_phone=caregiver_phone,
                    patient_name=patient.get("name", "Mgonjwa"),
                    patient_phone=patient_phone,
                    risk_level=risk_level,
                    pain_label=pain_label,
                    symptom=symptom,
                )
                actions_taken.append("caregiver_alerted")

            # Create alert record in Supabase for hospital dashboard
            await self._create_db_alert(
                patient=patient,
                patient_id=patient_id,
                phone=phone,
                pain_level=pain_level,
                symptom=symptom,
                risk_level=risk_level,
                channel=channel,
            )
            actions_taken.append("db_alert_created")

        # Step 5: EMERGENCY only — notify hospital contact directly
        # This closes the full clinical safety chain. The hospital
        # is mobilised without the patient needing to make a call.
        if risk_level == "EMERGENCY":
            hospital_phone = patient.get("hospital_phone")
            if hospital_phone:
                await self._whatsapp.send_emergency_alert(
                    hospital_phone=hospital_phone,
                    patient_name=patient.get("name", "Mgonjwa"),
                    patient_phone=patient_phone,
                    pain_score=pain_level,
                    symptom=symptom,
                    surgery_type=patient.get("surgery_type", ""),
                )
                actions_taken.append("hospital_alerted")

        return {
            "risk_level": risk_level,
            "actions": actions_taken,
            "patient_name": patient.get("name"),
            "channel": channel,
        }

    # ── Patient Profile Lookup ─────────────────────────────────

    async def _get_patient_profile(
        self, patient_id: str | None, phone: str
    ) -> dict:
        """
        Fetch the patient's full profile from Supabase.

        Tries patient_id first (fastest). Falls back to phone lookup
        for USSD patients who may not have a patient_id in the session.

        Also calculates recovery_day (days since surgery date) and
        fetches the hospital contact phone from the hospitals table.

        Returns an empty dict with safe defaults if nothing is found —
        the alert chain still runs, just without personalisation.
        """
        try:
            db = get_supabase_client()

            # Build query
            query = db.table("patients").select(
                "id, name, phone, caregiver_phone, surgery_type, "
                "surgery_date, hospital_id"
            )

            if patient_id:
                result = query.eq("id", patient_id).maybe_single().execute()
            else:
                result = query.eq("phone", phone).maybe_single().execute()

            if not result.data:
                return {}

            patient = dict(result.data)

            # Calculate recovery day from surgery date
            if patient.get("surgery_date"):
                try:
                    surgery = datetime.date.fromisoformat(
                        str(patient["surgery_date"])[:10]
                    )
                    patient["recovery_day"] = (
                        datetime.date.today() - surgery
                    ).days + 1
                except Exception:
                    patient["recovery_day"] = 1

            # Fetch hospital contact phone if hospital is linked
            if patient.get("hospital_id"):
                hosp_result = (
                    db.table("hospitals")
                    .select("contact_phone")
                    .eq("id", patient["hospital_id"])
                    .maybe_single()
                    .execute()
                )
                if hosp_result.data:
                    patient["hospital_phone"] = hosp_result.data.get(
                        "contact_phone"
                    )

            return patient

        except Exception:
            return {}

    # ── Create Database Alert ──────────────────────────────────

    async def _create_db_alert(
        self,
        patient: dict,
        patient_id: str | None,
        phone: str,
        pain_level: int,
        symptom: str,
        risk_level: str,
        channel: str,
    ) -> None:
        """
        Write an alert record to the Supabase alerts table.

        This is what the hospital dashboard reads in Phase 3.
        Clinical staff see a real-time list of patients who need
        attention, ranked by risk level, with full context.

        Both Flutter and USSD check-ins create alerts here so
        the hospital has one unified view of all their patients
        regardless of which channel they used to check in.
        """
        try:
            db = get_supabase_client()
            db.table("alerts").insert({
                "patient_id": patient_id or patient.get("id"),
                "hospital_id": patient.get("hospital_id"),
                "channel": channel,
                "risk_level": risk_level,
                "pain_level": pain_level,
                "symptom": symptom,
                "phone": phone,
                "status": "active",
                "message": (
                    f"{patient.get('name', phone)} reported "
                    f"pain={pain_level}/10, symptom={symptom} "
                    f"via {channel}. Risk: {risk_level}"
                ),
                "created_at": datetime.datetime.utcnow().isoformat(),
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to create DB alert for patient {patient_id or phone}: {e}")

    # ── Helper: Pain Label ─────────────────────────────────────

    def _pain_label(self, pain_level: int) -> str:
        """
        Convert numeric pain score to a human-readable Kiswahili label.
        Used in WhatsApp messages so patients see plain language,
        not medical numbers.
        """
        if pain_level == 0:
            return "Hakuna maumivu"
        if pain_level <= 2:
            return "Maumivu madogo sana"
        if pain_level <= 4:
            return "Maumivu kidogo"
        if pain_level <= 6:
            return "Maumivu ya wastani"
        if pain_level <= 8:
            return "Maumivu makali"
        return "Maumivu yasiyovumilika"

    # ── Helper: Default AI Tip ─────────────────────────────────

    def _default_tip(self, recovery_day: int, risk_level: str) -> str:
        """
        Fallback tip when Gemini AI tip is not available.

        Used when the AI service is slow or the check-in came from
        USSD where Gemini is not called. Based on Kenya MOH guidelines
        and standard post-surgical recovery protocols.
        """
        if risk_level == "EMERGENCY":
            return "Nenda hospitali SASA. Piga 999 au 0800 723 253."

        if risk_level == "HIGH":
            return (
                "Maumivu makali si ya kawaida. "
                "Piga simu daktari wako leo bila kuchelewa."
            )

        if recovery_day <= 2:
            return (
                "Pumzika kabisa. Kunywa maji mengi. "
                "Dawa zako ni muhimu sana siku hizi mbili za kwanza."
            )
        if recovery_day <= 7:
            return (
                "Tembea kidogo ndani ya nyumba — dakika 5 tu. "
                "Inasaidia damu kusambaa na kupona kwa haraka."
            )
        if recovery_day <= 14:
            return (
                "Kula protini nyingi: mayai, maharagwe, samaki. "
                "Mwili unahitaji protini kujenga upya tishu."
            )
        if recovery_day <= 30:
            return (
                "Unapona vizuri. Ongeza polepole shughuli zako. "
                "Sikiliza mwili wako — usifanye nguvu kupita kiasi."
            )
        return (
            "Uko karibu kupona kabisa. Hongera! "
            "Endelea na mazoezi ya upole na lishe bora."
        )
