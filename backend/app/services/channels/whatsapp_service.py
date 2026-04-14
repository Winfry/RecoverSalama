"""
WhatsApp Service — automated messages to patients, caregivers, hospitals.
"""

import datetime
import httpx
import africastalking

from app.config import settings


class WhatsAppService:

    _PROD_URL = "https://api.africastalking.com/version1/messaging"
    _SANDBOX_URL = "https://api.sandbox.africastalking.com/version1/messaging"

    def __init__(self):
        africastalking.initialize(
            username=settings.at_username,
            api_key=settings.at_api_key,
        )
        self._sms = africastalking.SMS
        self._is_sandbox = settings.at_username == "sandbox"
        self._api_url = (
            self._SANDBOX_URL if self._is_sandbox else self._PROD_URL
        )

    async def send_message(self, phone: str, message: str) -> dict:
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
            pass

        try:
            result = self._sms.send(message, [phone])
            return {"status": "sent", "channel": "sms_fallback", "response": str(result)}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    async def send_morning_reminder(self, phone: str, patient_name: str, recovery_day: int) -> dict:
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
        self, phone: str, patient_name: str, recovery_day: int,
        pain_label: str, risk_level: str, ai_tip: str,
    ) -> dict:
        risk_emoji = {"LOW": "(Vizuri)", "MEDIUM": "(Angalia)", "HIGH": "(Hatari)", "EMERGENCY": "(DHARURA)"}.get(risk_level, "")
        message = (
            f"SalamaRecover -- Siku {recovery_day} {risk_emoji}\n\n"
            f"Habari {patient_name}, check-in imehifadhiwa!\n\n"
            f"Hali yako:\nMaumivu: {pain_label}\nKiwango cha Hatari: {risk_level}\n\n"
            f"Ushauri wa AI leo:\n{ai_tip}\n\n"
            f"Piga *384# au fungua app kwa check-in ya kesho.\n-- SalamaRecover"
        )
        return await self.send_message(phone, message)

    async def send_caregiver_alert(
        self, caregiver_phone: str, patient_name: str, patient_phone: str,
        risk_level: str, pain_label: str, symptom: str,
    ) -> dict:
        message = (
            f"TAHADHARI -- SalamaRecover\n\n"
            f"{patient_name} ameonyesha dalili za wasiwasi:\n\n"
            f"Maumivu: {pain_label}\nDalili: {symptom}\nHatari: {risk_level}\n\n"
            f"Tafadhali mpigie simu au umtembelee SASA.\nNambari yake: {patient_phone}\n\n"
            f"Dharura: Piga 999 au 0800 723 253\n\n-- SalamaRecover"
        )
        return await self.send_message(caregiver_phone, message)

    async def send_emergency_alert(
        self, hospital_phone: str, patient_name: str, patient_phone: str,
        pain_score: int, symptom: str, surgery_type: str = "",
    ) -> dict:
        message = (
            f"DHARURA -- SalamaRecover\n\n"
            f"Mgonjwa: {patient_name}\nSimu: {patient_phone}\n"
            f"Upasuaji: {surgery_type or 'Haijulikani'}\n\n"
            f"Ripoti ya Check-In:\nMaumivu: {pain_score}/10\nDalili: {symptom}\nHali: DHARURA\n\n"
            f"Hatua ya haraka ya kimatibabu inahitajika.\n\n-- SalamaRecover Emergency System"
        )
        return await self.send_message(hospital_phone, message)

    async def handle_incoming(self, phone: str, message: str) -> str:
        """
        Process an incoming WhatsApp message from a patient.

        Tries Gemini AI first for a grounded clinical response in the
        patient's language (English or Kiswahili). Falls back to
        keyword matching if Gemini is unavailable or quota is exhausted.
        """
        # ── Gemini AI response (Phase 4) ──────────────────────────
        try:
            from app.services.ai.gemini_service import GeminiService
            from app.services.ai.rag_service import RAGService
            from app.database import get_supabase_client

            db = get_supabase_client()

            # Look up patient by phone for personalised context
            patient_result = (
                db.table("patients")
                .select("id, name, surgery_type, surgery_date, allergies")
                .eq("phone", phone)
                .maybe_single()
                .execute()
            )
            patient_data = patient_result.data or {}

            # Calculate days since surgery
            days_since = 0
            surgery_date = patient_data.get("surgery_date")
            if surgery_date:
                try:
                    days_since = (
                        datetime.date.today()
                        - datetime.date.fromisoformat(str(surgery_date)[:10])
                    ).days
                except Exception:
                    days_since = 0

            # Load last 5 messages for conversation context
            patient_id = patient_data.get("id")
            conversation_history = []
            if patient_id:
                history_result = (
                    db.table("chat_messages")
                    .select("role, content")
                    .eq("patient_id", patient_id)
                    .order("created_at", desc=True)
                    .limit(5)
                    .execute()
                )
                if history_result.data:
                    conversation_history = list(reversed(history_result.data))

            # RAG retrieval for clinical grounding
            rag = RAGService()
            context_chunks = await rag.retrieve(query=message, top_k=3)

            # Gemini response
            gemini = GeminiService()
            result = await gemini.chat(
                message=message,
                rag_context=context_chunks,
                patient_context={
                    "name": patient_data.get("name", ""),
                    "surgery_type": patient_data.get("surgery_type", ""),
                    "days_since_surgery": days_since,
                    "allergies": patient_data.get("allergies", []),
                },
                conversation_history=conversation_history,
            )

            reply = result.get("reply", "")

            # Save to chat history if patient is registered
            if patient_id and reply:
                db.table("chat_messages").insert([
                    {"patient_id": patient_id, "role": "user", "content": message},
                    {"patient_id": patient_id, "role": "assistant", "content": reply},
                ]).execute()

            if reply:
                return reply

        except Exception:
            pass  # Fall through to keyword fallback

        # ── Keyword fallback — used when Gemini is unavailable ────
        msg = message.strip().lower()

        if any(w in msg for w in ["check", "checkin", "maumivu", "pain"]):
            return (
                "Asante kwa kuwasiliana!\n\n"
                "Kwa check-in ya haraka:\n"
                "Piga *384# (bila data, simu yoyote)\n"
                "Au fungua SalamaRecover app\n\n"
                "Au tuambie hapa maumivu yako (1-10)."
            )
        if any(w in msg for w in ["help", "msaada", "nusaidie"]):
            return (
                "SalamaRecover Msaada\n\n"
                "Check-in bila data: Piga *384#\n"
                "App: SalamaRecover (Play Store)\n"
                "Mlo: Tuma CHAKULA\n"
                "Dharura: Piga 999 au 0800 723 253\n\n"
                "Tunakusaidia kupona salama!"
            )
        if any(w in msg for w in ["diet", "chakula", "mlo", "kula", "food"]):
            return (
                "Ushauri wa Mlo:\n\n"
                "Siku 1-2: Maji, supu, chai\n"
                "Siku 3-4: Uji, maziwa, mtindi\n"
                "Siku 5-7: Ugali laini, mayai, ndizi\n"
                "Siku 8+: Ugali, maharagwe, sukuma wiki\n\n"
                "Kwa ushauri zaidi: Piga *384# chaguo 2"
            )
        if any(w in msg for w in ["dharura", "emergency", "msaada haraka"]):
            return (
                "DHARURA\n\n"
                "Piga simu SASA:\n"
                "999 (Dharura ya Kitaifa)\n"
                "0800 723 253 (Ambulance bure)\n"
                "020-2726300 (KNH)\n\n"
                "Daktari amearifiwa kupitia mfumo wetu."
            )
        return (
            "Habari! Nimepokea ujumbe wako.\n\n"
            "Ninaweza kukusaidia na:\n"
            "CHECK -- check-in ya leo\n"
            "CHAKULA -- ushauri wa mlo\n"
            "MSAADA -- maelezo zaidi\n\n"
            "Au piga *384# kwa simu yoyote bila data.\n"
            "-- SalamaRecover"
        )
