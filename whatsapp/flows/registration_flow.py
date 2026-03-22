"""
WhatsApp Registration Flow — Phase 4 (Weeks 7-9).

Guides a new patient through registration via WhatsApp messages
in Kiswahili. Collects: name, surgery type, surgery date, hospital.

This is a conversation state machine. Each patient's phone number
maps to a session tracking their current step and collected data.

Flow:
  Bot: "Karibu SalamaRecover! Jina lako ni nani?"
  Patient: "Amina Wanjiru"
  Bot: "Asante Amina! Ulifanyiwa upasuaji gani?
        1. Caesarean  2. Appendectomy  3. Hernia..."
  Patient: "1"
  Bot: "Lini ulifanyiwa upasuaji?"
  Patient: "10/03/2026"
  Bot: "Hospitali gani?"
  Patient: "KNH"
  Bot: "Asante Amina! Umesajiliwa. Pona Salama!"

Once complete, the collected data is sent to the FastAPI backend
to create a patient profile — same as if they used the Flutter app.
"""


class RegistrationFlow:
    """State machine for WhatsApp patient registration."""

    # Maps number selections to surgery type names
    SURGERY_OPTIONS = {
        "1": "Caesarean Section",
        "2": "Appendectomy",
        "3": "Hernia Repair",
        "4": "Cholecystectomy",
        "5": "Knee Replacement",
        "6": "Hip Replacement",
    }

    def __init__(self):
        # phone_number → {"step": "name|surgery|date|hospital|complete", "data": {...}}
        self.sessions = {}

    def is_active(self, phone: str) -> bool:
        """Check if a registration session is in progress for this phone."""
        return phone in self.sessions and self.sessions[phone]["step"] != "complete"

    def handle(self, phone: str, message: str) -> str:
        """
        Process an incoming message and return the next prompt.

        Args:
            phone: Patient's phone number (e.g., "+254712345678")
            message: The text they sent

        Returns:
            The response text to send back via WhatsApp
        """
        # New patient — start registration
        if phone not in self.sessions:
            self.sessions[phone] = {"step": "name", "data": {}}
            return (
                "Karibu SalamaRecover!\n"
                "Nitakusaidia kupona baada ya upasuaji.\n\n"
                "Jina lako ni nani?"
            )

        session = self.sessions[phone]
        step = session["step"]

        # Step 1: Collect name
        if step == "name":
            name = message.strip().title()
            session["data"]["name"] = name
            session["step"] = "surgery_type"
            return (
                f"Asante {name}! Ulifanyiwa upasuaji gani?\n\n"
                "1. Caesarean Section\n"
                "2. Appendectomy\n"
                "3. Hernia Repair\n"
                "4. Cholecystectomy\n"
                "5. Knee Replacement\n"
                "6. Hip Replacement\n\n"
                "Jibu na nambari (1-6)"
            )

        # Step 2: Collect surgery type
        elif step == "surgery_type":
            surgery = self.SURGERY_OPTIONS.get(message.strip())
            if not surgery:
                # Invalid selection — ask again
                return (
                    "Samahani, chagua nambari sahihi (1-6):\n\n"
                    "1. Caesarean Section\n"
                    "2. Appendectomy\n"
                    "3. Hernia Repair\n"
                    "4. Cholecystectomy\n"
                    "5. Knee Replacement\n"
                    "6. Hip Replacement"
                )
            session["data"]["surgery_type"] = surgery
            session["step"] = "surgery_date"
            return (
                f"Sawa, {surgery}.\n\n"
                "Lini ulifanyiwa upasuaji?\n"
                "(mfano: 15/03/2026)"
            )

        # Step 3: Collect surgery date
        elif step == "surgery_date":
            date_text = message.strip()
            # Basic validation — accept any format, backend will parse
            if len(date_text) < 4:
                return "Tafadhali andika tarehe kamili (mfano: 15/03/2026)"
            session["data"]["surgery_date"] = date_text
            session["step"] = "hospital"
            return "Hospitali gani ulifanyiwa upasuaji?"

        # Step 4: Collect hospital
        elif step == "hospital":
            hospital = message.strip().title()
            session["data"]["hospital"] = hospital
            session["step"] = "phone_confirm"
            return (
                f"Nambari yako ya simu ni {phone}.\n"
                "Ni sahihi? (Ndio/Hapana)"
            )

        # Step 5: Confirm phone number
        elif step == "phone_confirm":
            response = message.strip().lower()
            if response in ("ndio", "yes", "sawa", "1"):
                session["data"]["phone"] = phone
            else:
                session["data"]["phone"] = phone  # Use it anyway for now
                # TODO: Ask for correct number

            session["step"] = "complete"
            name = session["data"]["name"]

            # TODO: POST session["data"] to FastAPI /api/patients/profile
            # This creates the patient profile in Supabase, same as
            # the Flutter app's profile setup screen.

            return (
                f"Asante {name}! Umesajiliwa kwenye SalamaRecover.\n\n"
                "Nitakutumia check-in kila siku asubuhi.\n"
                "Jibu tu maswali mafupi kuhusu maumivu na dalili.\n\n"
                "Ukihitaji msaada, tuma 'Msaada' wakati wowote.\n\n"
                "Pona Salama!"
            )

        # Completed or unknown state
        return (
            "Umeshasajiliwa! Tuma 'Check-in' kufanya check-in ya leo,\n"
            "au tuma 'Msaada' kwa usaidizi."
        )

    def get_patient_data(self, phone: str) -> dict | None:
        """Get the collected registration data for a phone number."""
        if phone in self.sessions and self.sessions[phone]["step"] == "complete":
            return self.sessions[phone]["data"]
        return None

    def reset(self, phone: str):
        """Clear a patient's registration session."""
        if phone in self.sessions:
            del self.sessions[phone]
