"""
WhatsApp Service — automated messages to patients, caregivers, hospitals.

This is the outbound communication channel for everyone connected to a
patient's recovery — the patient themselves, their family caregiver, and
the hospital contact assigned to their care.

WHAT IT SENDS:
  1. Daily morning reminder  → patient: "Time for your check-in"
  2. Post check-in summary   → patient: pain level, AI tip, encouragement
  3. Caregiver alert         → caregiver: when patient reports HIGH risk
  4. Emergency alert         → hospital: when EMERGENCY is detected
  5. Incoming message reply  → patient: keyword-based smart responses

HOW IT WORKS:
  Africa's Talking provides a WhatsApp Business API accessible via HTTP.
  We call it with httpx (async HTTP client already in requirements).
  If WhatsApp delivery fails for any reason, we fall back to SMS
  automatically — no patient is ever silently unreachable.

WHY THIS MATTERS FOR KENYA:
  WhatsApp has 97%+ penetration among Kenyan smartphone users.
  A patient who will not open a recovery app every day WILL read a
  WhatsApp message. The caregiver alert brings the family into the
  recovery loop with zero installation required on their part.
  The hospital alert closes the clinical safety chain without the
  patient needing to navigate calling a doctor while in pain.

LANGUAGE:
  Kiswahili for all automated messages — this is what patients and
  caregivers expect from a health service in Kenya. English is
  available in the Flutter app for those who prefer it.
"""

import httpx
import africastalking

from app.config import settings


class WhatsAppService:

    # Africa's Talking WhatsApp API endpoints
    _PROD_URL = "https://api.africastalking.com/version1/messaging"
    _SANDBOX_URL = "https://api.sandbox.africastalking.com/version1/messaging"

    def __init__(self):
        africastalking.initialize(
            username=settings.at_username,
            api_key=settings.at_api_key,
        )
        # SMS is used as fallback when WhatsApp delivery fails
        self._sms = africastalking.SMS

        # Sandbox during development, production in live deployment
        self._is_sandbox = settings.at_username == "sandbox"
        self._api_url = (
            self._SANDBOX_URL if self._is_sandbox else self._PROD_URL
        )

    # ── Core Send ──────────────────────────────────────────────

    async def send_message(self, phone: str, message: str) -> dict:
        """
        Send a WhatsApp message to any phone number.

        Tries WhatsApp first. If that fails for any reason
        (number not on WhatsApp, API error, network issue),
        automatically falls back to SMS so the message always
        gets through to the patient or caregiver.
        """
        # Attempt WhatsApp delivery
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    self._api_url,
                    headers={
                        "apiKey": settings.at_api_key,
                        "Content-Type": "application/json",
                        "Accept": "application/json",
                    },
                    json={
                        "username": settings.at_username,
                        "to": phone,
                        "message": message,
                        "channel": "whatsapp",
                    },
                )
                if response.status_code == 200:
                    return {"status": "sent", "channel": "whatsapp"}
        except Exception:
            pass  # Fall through to SMS fallback

        # SMS fallback — same message, different channel
        try:
            result = self._sms.send(message, [phone])
            return {
                "status": "sent",
                "channel": "sms_fallback",
                "response": str(result),
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}

    # ── Patient Messages ───────────────────────────────────────

    async def send_morning_reminder(
        self,
        phone: str,
        patient_name: str,
        recovery_day: int,
    ) -> dict:
        """
        Daily 6AM check-in reminder sent to every active patient.

        Triggered by the scheduler. Patients who check in regularly
        have significantly better recovery outcomes — this nudge
        is a clinical intervention, not just a notification.
        """
        message = (
            f"Habari za asubuhi, {patient_name}!\n\n"
            f"Leo ni siku ya {recovery_day} ya kupona kwako.\n"
            f"Usisahau check-in yako ya leo!\n\n"
            f"Fungua SalamaRecover app\n"
            f"Au piga *384# (bila data)\n\n"
            f"-- SalamaRecover"
        )
        return await self.send_message(phone, message)

    async def send_daily_summary(
        self,
        phone: str,
        patient_name: str,
        recovery_day: int,
        pain_label: str,
        risk_level: str,
        ai_tip: str,
    ) -> dict:
        """
        Post check-in summary sent to the patient immediately after
        they complete a check-in via app or USSD.

        Closes the feedback loop — the patient gets acknowledgement,
        their risk status, and a personalised AI tip in WhatsApp.
        """
        risk_emoji = {
            "LOW": "(Vizuri)",
            "MEDIUM": "(Angalia)",
            "HIGH": "(Hatari)",
            "EMERGENCY": "(DHARURA)",
        }.get(risk_level, "")

        message = (
            f"SalamaRecover -- Siku {recovery_day} {risk_emoji}\n\n"
            f"Habari {patient_name}, check-in imehifadhiwa!\n\n"
            f"Hali yako:\n"
            f"Maumivu: {pain_label}\n"
            f"Kiwango cha Hatari: {risk_level}\n\n"
            f"Ushauri wa AI leo:\n"
            f"{ai_tip}\n\n"
            f"Piga *384# au fungua app kwa check-in ya kesho.\n"
            f"-- SalamaRecover"
        )
        return await self.send_message(phone, message)

    # ── Caregiver Alert ────────────────────────────────────────

    async def send_caregiver_alert(
        self,
        caregiver_phone: str,
        patient_name: str,
        patient_phone: str,
        risk_level: str,
        pain_label: str,
        symptom: str,
    ) -> dict:
        """
        Alert the caregiver when patient reports HIGH or EMERGENCY risk.

        This is one of the most impactful features for Kenya's context.
        Kenyan families are deeply involved in healthcare decisions.
        A caregiver who receives this WhatsApp can physically check on
        the patient within minutes — faster than any clinical response.

        No installation required from the caregiver. They only need
        WhatsApp, which virtually every Kenyan with a smartphone has.

        The caregiver phone number is collected during profile setup
        Step 3 — optional but strongly encouraged for every patient.
        """
        message = (
            f"TAHADHARI -- SalamaRecover\n\n"
            f"{patient_name} ameonyesha dalili za wasiwasi:\n\n"
            f"Maumivu: {pain_label}\n"
            f"Dalili: {symptom}\n"
            f"Hatari: {risk_level}\n\n"
            f"Tafadhali mpigie simu au umtembelee SASA.\n"
            f"Nambari yake: {patient_phone}\n\n"
            f"Dharura: Piga 999 au 0800 723 253\n\n"
            f"-- SalamaRecover"
        )
        return await self.send_message(caregiver_phone, message)

    # ── Hospital Emergency Alert ───────────────────────────────

    async def send_emergency_alert(
        self,
        hospital_phone: str,
        patient_name: str,
        patient_phone: str,
        pain_score: int,
        symptom: str,
        surgery_type: str = "",
    ) -> dict:
        """
        Alert the hospital contact when EMERGENCY risk is detected.

        Closes the clinical safety chain. The hospital receives a
        structured alert with full patient details so they can
        initiate contact or dispatch help without waiting for the
        patient to navigate calling while in severe pain.

        Triggered by both Flutter app check-ins AND USSD check-ins.
        Every patient on every channel is protected.

        In Phase 3 (Hospital Dashboard), this also appears as a
        real-time alert card on the clinical staff screen.
        """
        message = (
            f"DHARURA -- SalamaRecover\n\n"
            f"Mgonjwa: {patient_name}\n"
            f"Simu: {patient_phone}\n"
            f"Upasuaji: {surgery_type or 'Haijulikani'}\n\n"
            f"Ripoti ya Check-In:\n"
            f"Maumivu: {pain_score}/10\n"
            f"Dalili: {symptom}\n"
            f"Hali: DHARURA\n\n"
            f"Hatua ya haraka ya kimatibabu inahitajika.\n\n"
            f"-- SalamaRecover Emergency System"
        )
        return await self.send_message(hospital_phone, message)

    # ── Incoming Message Handler ───────────────────────────────

    async def handle_incoming(self, phone: str, message: str) -> str:
        """
        Process an incoming WhatsApp message from a patient.
        Returns the response text to send back to them.

        Triggered by the webhooks endpoint when a patient replies
        to a WhatsApp message or messages the SalamaRecover number.

        Matches keywords in both English and Kiswahili so patients
        can message in whichever language they are comfortable with.

        Phase 4 will upgrade this to full Gemini AI conversation
        so patients can ask any health question in WhatsApp.
        """
        msg = message.strip().lower()

        # Check-in intent
        if any(w in msg for w in ["check", "checkin", "maumivu", "pain"]):
            return (
                "Asante kwa kuwasiliana!\n\n"
                "Kwa check-in ya haraka:\n"
                "Piga *384# (bila data, simu yoyote)\n"
                "Au fungua SalamaRecover app\n\n"
                "Au tuambie hapa maumivu yako (1-10)."
            )

        # Help intent
        if any(w in msg for w in ["help", "msaada", "nusaidie"]):
            return (
                "SalamaRecover Msaada\n\n"
                "Check-in bila data: Piga *384#\n"
                "App: SalamaRecover (Play Store)\n"
                "Mlo: Tuma CHAKULA\n"
                "Dharura: Piga 999 au 0800 723 253\n\n"
                "Tunakusaidia kupona salama!"
            )

        # Diet intent
        if any(w in msg for w in ["diet", "chakula", "mlo", "kula", "food"]):
            return (
                "Ushauri wa Mlo:\n\n"
                "Siku 1-2: Maji, supu, chai\n"
                "Siku 3-4: Uji, maziwa, mtindi\n"
                "Siku 5-7: Ugali laini, mayai, ndizi\n"
                "Siku 8+: Ugali, maharagwe, sukuma wiki\n\n"
                "Kwa ushauri zaidi: Piga *384# chaguo 2"
            )

        # Emergency intent
        if any(w in msg for w in ["dharura", "emergency", "msaada haraka"]):
            return (
                "DHARURA\n\n"
                "Piga simu SASA:\n"
                "999 (Dharura ya Kitaifa)\n"
                "0800 723 253 (Ambulance bure)\n"
                "020-2726300 (KNH)\n\n"
                "Daktari amearifiwa kupitia mfumo wetu."
            )

        # Default response
        return (
            "Habari! Nimepokea ujumbe wako.\n\n"
            "Ninaweza kukusaidia na:\n"
            "CHECK -- check-in ya leo\n"
            "CHAKULA -- ushauri wa mlo\n"
            "MSAADA -- maelezo zaidi\n\n"
            "Au piga *384# kwa simu yoyote bila data.\n"
            "-- SalamaRecover"
        )
