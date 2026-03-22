"""
WhatsApp Daily Check-In Flow — Phase 4 (Weeks 7-9).

Collects daily check-in data from patients via WhatsApp messages.
Same data as Flutter Screen 04 but through chat conversation.

Flow:
  Bot: "Habari Amina! Check-in ya leo:
        Kiwango cha maumivu (0-10)?"
  Patient: "5"
  Bot: "Una dalili yoyote?
        1. Homa  2. Kutokwa damu  3. Kichefuchefu  4. Hakuna"
  Patient: "4"
  Bot: "Unajisikiaje?
        1. Vizuri  2. Nimechoka  3. Wasiwasi  4. Huzuni"
  Patient: "1"
  Bot: "Asante! Risk: LOW ✅  Pona Salama!"

If critical symptoms are detected, the response changes immediately
to an emergency message with hospital contact numbers.

The collected data is sent to the same backend endpoint as the
Flutter app — one brain, two channels.
"""


class CheckInFlow:
    """State machine for WhatsApp daily check-in."""

    SYMPTOM_OPTIONS = {
        "1": "Fever above 38°C",
        "2": "Wound bleeding",
        "3": "Nausea",
        "4": "Dizziness",
        "5": "Swelling",
        "6": "Redness around wound",
        "7": "None",
    }

    MOOD_OPTIONS = {
        "1": "Good",
        "2": "Tired",
        "3": "Anxious",
        "4": "Low",
    }

    # Symptoms that trigger immediate escalation
    CRITICAL_SYMPTOMS = {"Fever above 38°C", "Wound bleeding"}

    def __init__(self):
        # phone_number → {"step": "pain|symptoms|mood", "data": {...}}
        self.sessions = {}

    def is_active(self, phone: str) -> bool:
        """Check if a check-in session is in progress."""
        return phone in self.sessions

    def start_checkin(self, phone: str, patient_name: str) -> str:
        """
        Initiate a daily check-in for a patient.
        Called by the system (scheduled job or manual trigger).

        Args:
            phone: Patient's phone number
            patient_name: Patient's name for personalisation

        Returns:
            The opening message to send via WhatsApp
        """
        self.sessions[phone] = {
            "step": "pain",
            "data": {"patient_name": patient_name},
        }
        return (
            f"Habari {patient_name}!\n"
            "Check-in ya leo ya SalamaRecover:\n\n"
            "Kiwango cha maumivu yako leo ni ngapi?\n"
            "Jibu na nambari 0 (hakuna maumivu) hadi 10 (maumivu makali sana)"
        )

    def handle(self, phone: str, message: str) -> str:
        """
        Process an incoming check-in response.

        Args:
            phone: Patient's phone number
            message: Their response text

        Returns:
            The next question or the final summary
        """
        if phone not in self.sessions:
            return (
                "Huna check-in inayoendelea.\n"
                "Tuma 'Check-in' kuanza check-in mpya."
            )

        session = self.sessions[phone]
        step = session["step"]

        # Step 1: Pain level (0-10)
        if step == "pain":
            text = message.strip()
            if text.isdigit() and 0 <= int(text) <= 10:
                pain = int(text)
            else:
                return (
                    "Tafadhali jibu na nambari kati ya 0 na 10.\n"
                    "0 = hakuna maumivu, 10 = maumivu makali sana"
                )

            session["data"]["pain_level"] = pain
            session["step"] = "symptoms"

            return (
                f"Maumivu: {pain}/10. Sawa.\n\n"
                "Una dalili yoyote hizi?\n"
                "(Unaweza chagua zaidi ya moja, tenganisha na koma)\n\n"
                "1. Homa juu ya 38°C\n"
                "2. Kidonda kinatoka damu\n"
                "3. Kichefuchefu\n"
                "4. Kizunguzungu\n"
                "5. Uvimbe\n"
                "6. Kidonda chekundu\n"
                "7. Hakuna dalili\n\n"
                "Jibu na nambari (mfano: 1,3 au 7)"
            )

        # Step 2: Symptoms (can select multiple)
        elif step == "symptoms":
            selections = [s.strip() for s in message.split(",")]
            symptoms = []

            for sel in selections:
                symptom = self.SYMPTOM_OPTIONS.get(sel)
                if symptom and symptom != "None":
                    symptoms.append(symptom)

            session["data"]["symptoms"] = symptoms
            session["step"] = "mood"

            # If critical symptoms detected, show warning but still ask mood
            warning = ""
            has_critical = any(s in self.CRITICAL_SYMPTOMS for s in symptoms)
            if has_critical:
                warning = "⚠️ Dalili muhimu zimegunduliwa.\n\n"

            return (
                f"{warning}"
                "Unajisikiaje kihisia leo?\n\n"
                "1. Vizuri 😊\n"
                "2. Nimechoka 😐\n"
                "3. Nina wasiwasi 😟\n"
                "4. Huzuni 😢\n\n"
                "Jibu na nambari (1-4)"
            )

        # Step 3: Mood — then calculate risk and respond
        elif step == "mood":
            mood_selection = message.strip()
            mood = self.MOOD_OPTIONS.get(mood_selection, "Good")
            session["data"]["mood"] = mood

            # Extract collected data
            pain = session["data"]["pain_level"]
            symptoms = session["data"]["symptoms"]
            patient_name = session["data"].get("patient_name", "")

            # Calculate risk (simplified — matches rule-based Layer 1)
            risk_level, risk_response = self._assess_risk(pain, symptoms)
            session["data"]["risk_level"] = risk_level

            # TODO: POST session["data"] to FastAPI /api/recovery/checkin
            # This runs the full two-layer risk scorer and saves to database.

            # Clean up session
            checkin_data = session["data"].copy()
            del self.sessions[phone]

            # Build response based on risk level
            return self._build_response(
                patient_name, pain, symptoms, mood, risk_level, risk_response
            )

        return "Tuma 'Check-in' kuanza check-in mpya."

    def _assess_risk(self, pain: int, symptoms: list[str]) -> tuple[str, str]:
        """
        Simplified risk assessment for WhatsApp.
        The full two-layer assessment happens in the backend when we POST the data.
        This gives the patient an immediate response.
        """
        critical_count = sum(1 for s in symptoms if s in self.CRITICAL_SYMPTOMS)

        if critical_count >= 2:
            return "EMERGENCY", (
                "🚨 DHARURA — HATARI KUBWA!\n"
                "Dalili zako zinaonyesha hatari ya haraka.\n\n"
                "FANYA HIVI SASA:\n"
                "📞 Piga 999 au 112\n"
                "📞 KNH: 020-2726300\n"
                "🏥 Nenda hospitali ya karibu HARAKA\n\n"
                "USIENDELEE KUSUBIRI."
            )

        if critical_count == 1:
            symptom_name = next(s for s in symptoms if s in self.CRITICAL_SYMPTOMS)
            return "HIGH", (
                f"⚠️ HATARI — Dalili muhimu: {symptom_name}\n\n"
                "Tafadhali wasiliana na hospitali yako LEO.\n"
                "📞 KNH: 020-2726300\n"
                "📞 Nairobi Hospital: 020-2846000\n\n"
                "Usisubiri hadi kesho."
            )

        if pain >= 8:
            return "HIGH", (
                f"⚠️ Maumivu makali ({pain}/10).\n"
                "Wasiliana na daktari wako leo kwa ushauri\n"
                "wa kudhibiti maumivu."
            )

        if pain >= 6 or len(symptoms) >= 3:
            return "MEDIUM", (
                "Angalia dalili zako kwa makini leo.\n"
                "Kama zinazidi au mpya zinaonekana,\n"
                "wasiliana na daktari wako."
            )

        return "LOW", (
            "Kupona kwako kunaendelea vizuri! ✅\n"
            "Endelea na mlo wako, pumzika, na kunywa maji mengi."
        )

    def _build_response(
        self,
        patient_name: str,
        pain: int,
        symptoms: list[str],
        mood: str,
        risk_level: str,
        risk_response: str,
    ) -> str:
        """Build the final check-in response message."""

        # Mood acknowledgment
        mood_messages = {
            "Good": "Vizuri kusikia uko sawa! 😊",
            "Tired": "Kupumzika ni sehemu ya kupona. Pumzika leo. 💤",
            "Anxious": "Wasiwasi ni kawaida. Vuta pumzi pole pole. 🙏",
            "Low": "Pole sana. Huhitaji kupitia hii peke yako. ❤️",
        }
        mood_msg = mood_messages.get(mood, "Asante kwa kujiangalia.")

        # Risk level icons
        risk_icons = {
            "LOW": "🟢 LOW",
            "MEDIUM": "🟡 MEDIUM",
            "HIGH": "🔴 HIGH",
            "EMERGENCY": "🚨 EMERGENCY",
        }
        risk_display = risk_icons.get(risk_level, risk_level)

        response = (
            f"Asante{f' {patient_name}' if patient_name else ''}! "
            f"Check-in imekamilika.\n\n"
            f"📊 Muhtasari:\n"
            f"  Maumivu: {pain}/10\n"
            f"  Dalili: {', '.join(symptoms) if symptoms else 'Hakuna'}\n"
            f"  Hali: {mood}\n"
            f"  Risk: {risk_display}\n\n"
            f"{mood_msg}\n\n"
            f"{risk_response}\n\n"
            "Pona Salama! 💚"
        )

        # Add helpline for low mood
        if mood in ("Low", "Anxious"):
            response += (
                "\n\nUkihitaji mtu wa kuzungumza naye:\n"
                "📞 Befrienders Kenya: 0722 178 177"
            )

        return response

    def get_checkin_data(self, phone: str) -> dict | None:
        """Get the collected check-in data (after completion)."""
        # Data is cleared after completion, so this is for mid-session access
        if phone in self.sessions:
            return self.sessions[phone]["data"]
        return None
