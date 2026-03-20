"""
USSD Service — handles menu-based interactions for feature phones.

USSD works on ANY phone — even a Nokia 3310. No internet required.
The patient dials *384*SALAMA# and navigates text menus.

USSD is menu-based (not free text), so it uses the rule-based
risk scorer instead of the LLM. The menus are in Kiswahili
since most feature phone users in Kenya prefer it.

Flow:
1. Patient dials the USSD code
2. Africa's Talking sends session data to /api/webhooks/ussd
3. This service returns menu text based on the navigation state
4. Patient responds with number selections (1, 2, 3...)

Example session:
  *384*SALAMA# →
  "Karibu SalamaRecover
   1. Check-In ya Leo
   2. Ushauri wa Mlo
   3. Piga Simu Hospitali"
  User presses 1 →
  "Kiwango cha Maumivu (0-10)?
   Jibu na nambari"
  User types 5 →
  "Dalili? 1. Homa 2. Kutokwa Damu 3. Hakuna"
  ...etc
"""


class USSDService:
    def handle_session(
        self, session_id: str, phone: str, text: str
    ) -> str:
        """
        Process a USSD session. Returns menu text to display.
        The 'text' parameter contains the user's accumulated inputs
        separated by '*'. Example: "" → "1" → "1*5" → "1*5*3"
        """
        inputs = text.split("*") if text else []
        level = len(inputs)

        # Level 0 — Main menu (first dial)
        if level == 0:
            return (
                "CON Karibu SalamaRecover\n"
                "1. Check-In ya Leo\n"
                "2. Ushauri wa Mlo\n"
                "3. Piga Simu Hospitali\n"
                "4. Msaada"
            )

        choice = inputs[0]

        # ── Branch 1: Daily Check-In ──
        if choice == "1":
            return self._checkin_flow(inputs[1:], phone)

        # ── Branch 2: Diet Advice ──
        elif choice == "2":
            return self._diet_flow(inputs[1:])

        # ── Branch 3: Call Hospital ──
        elif choice == "3":
            return (
                "END Piga simu:\n"
                "KNH: 020-2726300\n"
                "Dharura: 999 / 112"
            )

        # ── Branch 4: Help ──
        elif choice == "4":
            return (
                "END SalamaRecover inakusaidia kupona "
                "baada ya upasuaji. Piga *384*SALAMA# "
                "kila siku kwa check-in."
            )

        return "END Chaguo batili. Jaribu tena."

    def _checkin_flow(self, inputs: list[str], phone: str) -> str:
        """Handle the check-in sub-menu."""
        if len(inputs) == 0:
            return (
                "CON Kiwango cha Maumivu?\n"
                "Jibu 0 (hakuna) hadi 10 (kali sana)"
            )

        if len(inputs) == 1:
            return (
                "CON Dalili?\n"
                "1. Homa juu ya 38°C\n"
                "2. Kidonda kinatoka damu\n"
                "3. Kichefuchefu\n"
                "4. Hakuna dalili"
            )

        if len(inputs) == 2:
            pain = int(inputs[0]) if inputs[0].isdigit() else 0
            symptom = inputs[1]

            # Simple risk assessment
            if symptom in ("1", "2") or pain >= 8:
                return (
                    "END ⚠ HATARI KUBWA\n"
                    "Nenda hospitali haraka!\n"
                    "Piga: 999 au 020-2726300"
                )
            elif pain >= 5:
                return (
                    "END Angalia dalili zako.\n"
                    "Kama zinazidi, piga simu daktari.\n"
                    "Check-in yako imehifadhiwa."
                )
            else:
                return (
                    "END Vizuri! Endelea kupona.\n"
                    "Check-in yako imehifadhiwa.\n"
                    "Piga *384*SALAMA# kesho."
                )

        return "END Asante. Check-in imekamilika."

    def _diet_flow(self, inputs: list[str]) -> str:
        """Handle the diet advice sub-menu."""
        if len(inputs) == 0:
            return (
                "CON Siku ngapi tangu upasuaji?\n"
                "Jibu na nambari (mfano: 5)"
            )

        day = int(inputs[0]) if inputs[0].isdigit() else 5

        if day <= 2:
            return (
                "END Siku 1-2: Vinywaji tu\n"
                "- Chai bila maziwa\n"
                "- Supu safi\n"
                "- Maji mengi\n"
                "(MOH Kenya p.66)"
            )
        elif day <= 4:
            return (
                "END Siku 3-4: Vinywaji vizito\n"
                "- Uji wa unga\n"
                "- Maziwa\n"
                "- Mtindi\n"
                "(MOH Kenya p.67)"
            )
        elif day <= 7:
            return (
                "END Siku 5-7: Chakula laini\n"
                "- Ugali laini\n"
                "- Mayai\n"
                "- Ndizi\n"
                "- Papai\n"
                "(MOH Kenya p.69)"
            )
        else:
            return (
                "END Siku 8+: Protini nyingi\n"
                "- Ugali + maharagwe\n"
                "- Samaki/kuku\n"
                "- Sukuma wiki\n"
                "(MOH Kenya p.75)"
            )
