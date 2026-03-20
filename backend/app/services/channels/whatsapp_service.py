"""
WhatsApp Service — handles patient messages via Africa's Talking.

This is how SalamaRecover reaches patients who have a phone with
WhatsApp but don't want to (or can't) install the Flutter app.
Same AI brain, different channel.

Flow:
1. Patient sends a WhatsApp message to the SalamaRecover number
2. Africa's Talking forwards it to our /api/webhooks/whatsapp endpoint
3. This service processes it through the same AI pipeline
4. Response is sent back via Africa's Talking WhatsApp API

Supports both English and Kiswahili — auto-detects language.
"""

import africastalking

from app.config import settings


class WhatsAppService:
    def __init__(self):
        africastalking.initialize(
            username=settings.at_username,
            api_key=settings.at_api_key,
        )
        self.sms = africastalking.SMS

    async def handle_message(self, phone: str, message: str) -> str:
        """
        Process an incoming WhatsApp message.
        Returns the response text to send back.
        """
        # TODO: In Phase 4 (Weeks 7-9), implement:
        # 1. Look up patient by phone number
        # 2. Detect language (EN/SW)
        # 3. Route to AI chat or check-in flow
        # 4. Send response back via WhatsApp

        response = (
            "Habari! Mimi ni SalamaRecover AI. "
            "Nitakusaidia na kupona kwako. "
            "Tuma ujumbe wako kwa Kiswahili au English."
        )

        return response

    async def send_message(self, phone: str, message: str) -> dict:
        """Send a WhatsApp message to a patient."""
        try:
            response = self.sms.send(message, [phone])
            return {"status": "sent", "response": response}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    async def send_caregiver_summary(
        self, phone: str, patient_name: str, summary: dict
    ) -> dict:
        """
        Send daily recovery summary to a caregiver via WhatsApp.
        Keeps family members informed about the patient's progress.
        """
        message = (
            f"SalamaRecover Daily Update for {patient_name}:\n"
            f"Day {summary.get('day', '?')} of Recovery\n"
            f"Pain Level: {summary.get('pain', '?')}/10\n"
            f"Risk: {summary.get('risk', 'LOW')}\n"
            f"Mood: {summary.get('mood', 'Good')}\n"
        )
        return await self.send_message(phone, message)
