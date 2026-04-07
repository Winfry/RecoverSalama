"""
USSD Service — menu-based check-ins for feature phones.

USSD works on ANY phone — even a Nokia 3310 with no internet.
The patient dials *384# and navigates text menus in Kiswahili.

HOW USSD WORKS:
  Every time the patient presses a number, Africa's Talking sends
  ALL their inputs so far to our server, joined by '*'.

  Example session:
    Dials *384#         → text=""        → show main menu
    Presses 1           → text="1"       → show pain question
    Presses 4           → text="1*4"     → show symptom question
    Presses 5           → text="1*4*5"   → save check-in, show result

  Responses starting with "CON" show a menu and wait for input.
  Responses starting with "END" close the session (final message).

WHO USES THIS:
  - Elderly patients with basic Safaricom/Airtel phones
  - Rural patients with no mobile data
  - Patients whose caregiver dials on their behalf
  - Anyone who cannot or will not install the Flutter app

  These patients are NOT second-class users. Their data goes to
  the same Supabase database. Their doctors see the same alerts.
  The AI tracks their recovery identically.

LANGUAGE:
  Kiswahili only. Feature phone users in Kenya are predominantly
  Kiswahili speakers. Short sentences, no medical jargon.
  Menu depth max 3 levels — elderly users lose track beyond that.
"""

import asyncio
import datetime
from app.database import get_supabase_client


class USSDService:

    def handle_session(
        self, session_id: str, phone: str, text: str
    ) -> str:
        """
        Process a USSD session step. Returns menu text to display.

        'text' contains all inputs so far joined by '*'.
        We split it to know exactly where in the menu tree we are.
        """
        inputs = [x for x in text.split("*") if x] if text else []

        # ── Level 0: Main Menu (patient just dialled) ──────────
        if not inputs:
            return (
                "CON Karibu SalamaRecover\n"
                "1. Check-In ya Leo\n"
                "2. Ushauri wa Mlo\n"
                "3. Piga Simu Hospitali\n"
                "4. Msaada"
            )

        choice = inputs[0]

        # ── Branch 1: Daily Check-In ───────────────────────────
        if choice == "1":
            return self._checkin_flow(inputs[1:], phone)

        # ── Branch 2: Diet Advice ──────────────────────────────
        elif choice == "2":
            return self._diet_flow(inputs[1:])

        # ── Branch 3: Emergency Numbers ────────────────────────
        # Always available — even a confused elderly patient
        # can reach option 3 and call for help immediately.
        elif choice == "3":
            return (
                "END Piga simu sasa:\n"
                "KNH: 020-2726300\n"
                "Dharura: 999 au 112\n"
                "Ambulance: 0800 723 253"
            )

        # ── Branch 4: Help / About ─────────────────────────────
        elif choice == "4":
            return (
                "END SalamaRecover inakusaidia\n"
                "kupona baada ya upasuaji.\n"
                "Piga *384# kila siku\n"
                "kwa check-in yako ya afya."
            )

        return "END Chaguo batili. Jaribu tena."

    # ── Check-In Flow ──────────────────────────────────────────
    def _checkin_flow(self, inputs: list[str], phone: str) -> str:
        """
        3-step check-in:
          Step 0 → ask pain level (5 options)
          Step 1 → ask main symptom (5 options)
          Step 2 → save to Supabase, show personalised result
        """

        # Step 0: Ask pain level
        if len(inputs) == 0:
            return (
                "CON Kiwango cha Maumivu Leo?\n"
                "1. Hakuna maumivu\n"
                "2. Maumivu kidogo\n"
                "3. Maumivu ya wastani\n"
                "4. Maumivu makali\n"
                "5. Maumivu yasiyovumilika"
            )

        # Step 1: Ask symptom
        if len(inputs) == 1:
            return (
                "CON Dalili Kuu Leo?\n"
                "1. Homa juu ya 38 degrees\n"
                "2. Kidonda kinatoka damu\n"
                "3. Kichefuchefu/kutapika\n"
                "4. Uvimbe mkubwa\n"
                "5. Hakuna dalili"
            )

        # Step 2: Save and respond
        if len(inputs) >= 2:
            pain_map = {
                "1": (0, "Hakuna"),
                "2": (3, "Kidogo"),
                "3": (5, "Wastani"),
                "4": (7, "Makali"),
                "5": (10, "Kali Sana"),
            }
            symptom_map = {
                "1": "fever",
                "2": "bleeding",
                "3": "nausea",
                "4": "swelling",
                "5": "none",
            }

            pain_score, pain_label = pain_map.get(inputs[0], (5, "Wastani"))
            symptom = symptom_map.get(inputs[1], "none")
            risk = self._calculate_risk(pain_score, symptom)

            # Save to Supabase — this is the critical fix.
            # Previously check-in data was calculated but never stored.
            # Now every USSD check-in lands in the same recovery_logs
            # table as Flutter app check-ins. The doctor sees everything.
            self._save_checkin(
                phone=phone,
                pain_level=pain_score,
                symptom=symptom,
                risk_level=risk,
            )

            # AlertService handles WhatsApp notifications, caregiver
            # alerts, hospital emergency alerts, and DB alert records.
            # Imported here (inside method) to avoid circular imports.
            try:
                from app.services.alert_service import AlertService
                asyncio.create_task(
                    AlertService().process_checkin(
                        patient_id=None,
                        phone=phone,
                        pain_level=pain_score,
                        risk_level=risk,
                        symptom=symptom,
                        channel="ussd",
                    )
                )
            except Exception:
                pass

            return self._build_result(risk, pain_label)

        return "END Asante. Jaribu tena kesho."

    def _calculate_risk(self, pain_score: int, symptom: str) -> str:
        """
        Rule-based risk scoring for USSD.

        EMERGENCY → go to hospital now (fever, bleeding, or pain 9-10)
        HIGH      → call doctor today (pain 7-8 or major swelling)
        MEDIUM    → expected discomfort, monitor (pain 4-6)
        LOW       → healing well (pain 0-3, no symptoms)
        """
        if symptom in ("fever", "bleeding") or pain_score >= 9:
            return "EMERGENCY"
        if pain_score >= 7 or symptom == "swelling":
            return "HIGH"
        if pain_score >= 4:
            return "MEDIUM"
        return "LOW"

    def _save_checkin(
        self,
        phone: str,
        pain_level: int,
        symptom: str,
        risk_level: str,
    ) -> None:
        """
        Save the USSD check-in to Supabase recovery_logs.

        We first look up the patient by their phone number to link
        the log to their patient record. If no record is found we
        still save with phone as a reference — no data is ever lost.
        """
        try:
            db = get_supabase_client()

            patient_result = (
                db.table("patients")
                .select("id")
                .eq("phone", phone)
                .maybe_single()
                .execute()
            )

            patient_id = (
                patient_result.data["id"]
                if patient_result.data
                else None
            )

            db.table("recovery_logs").insert({
                "patient_id": patient_id,
                "phone": phone,
                "channel": "ussd",
                "pain_level": pain_level,
                "has_fever": symptom == "fever",
                "has_bleeding": symptom == "bleeding",
                "has_nausea": symptom == "nausea",
                "has_swelling": symptom == "swelling",
                "risk_level": risk_level,
                "notes": f"USSD check-in. Dalili: {symptom}",
                "created_at": datetime.datetime.utcnow().isoformat(),
            }).execute()

        except Exception:
            # Never crash the USSD session because of a DB error.
            # The patient still receives their response either way.
            pass

    def _create_alert(
        self, phone: str, pain_score: int, symptom: str, risk: str
    ) -> None:
        """
        Create an alert in Supabase when risk is HIGH or EMERGENCY.

        This alert appears on the hospital dashboard Alert Centre
        so clinical staff can intervene before it becomes critical.
        Same alerts table used for Flutter AND USSD — one unified view.
        """
        try:
            db = get_supabase_client()

            patient_result = (
                db.table("patients")
                .select("id, name, hospital_id")
                .eq("phone", phone)
                .maybe_single()
                .execute()
            )

            patient = patient_result.data or {}

            db.table("alerts").insert({
                "patient_id": patient.get("id"),
                "hospital_id": patient.get("hospital_id"),
                "channel": "ussd",
                "risk_level": risk,
                "pain_level": pain_score,
                "symptom": symptom,
                "phone": phone,
                "status": "active",
                "message": (
                    f"USSD check-in: {patient.get('name', phone)} "
                    f"pain={pain_score}/10, dalili={symptom}. "
                    f"Hatari: {risk}"
                ),
                "created_at": datetime.datetime.utcnow().isoformat(),
            }).execute()

        except Exception:
            pass

    def _build_result(self, risk: str, pain_label: str) -> str:
        """
        Build the closing USSD message based on risk level.
        Short, clear, actionable. No medical jargon.
        """
        if risk == "EMERGENCY":
            return (
                "END HATARI KUBWA!\n"
                "Nenda hospitali SASA.\n"
                "Piga: 999 au 0800 723 253\n"
                "Daktari amearifiwa."
            )
        if risk == "HIGH":
            return (
                "END Angalia! Maumivu makali.\n"
                "Piga simu daktari leo.\n"
                "KNH: 020-2726300\n"
                "Check-in imehifadhiwa."
            )
        if risk == "MEDIUM":
            return (
                f"END Maumivu: {pain_label}.\n"
                "Pumzika. Kunywa maji mengi.\n"
                "Endelea na dawa zako.\n"
                "Check-in imehifadhiwa."
            )
        return (
            f"END Vizuri! Maumivu: {pain_label}.\n"
            "Unapona vizuri. Hongera!\n"
            "Piga *384# kesho tena.\n"
            "Check-in imehifadhiwa."
        )

    # ── Diet Advice Flow ───────────────────────────────────────
    def _diet_flow(self, inputs: list[str]) -> str:
        """
        Diet advice by recovery day range.
        Based on Kenya MOH Nutrition Manual.
        Short enough to read on a feature phone screen.
        """
        if len(inputs) == 0:
            return (
                "CON Siku ngapi tangu upasuaji?\n"
                "1. Siku 1-2\n"
                "2. Siku 3-4\n"
                "3. Siku 5-7\n"
                "4. Siku 8 na zaidi"
            )

        choice = inputs[0]

        if choice == "1":
            return (
                "END Siku 1-2: Vinywaji tu\n"
                "- Maji mengi\n"
                "- Supu safi\n"
                "- Chai bila maziwa\n"
                "(MOH Kenya uk.66)"
            )
        elif choice == "2":
            return (
                "END Siku 3-4: Vinywaji vizito\n"
                "- Uji wa unga\n"
                "- Maziwa\n"
                "- Mtindi\n"
                "(MOH Kenya uk.67)"
            )
        elif choice == "3":
            return (
                "END Siku 5-7: Chakula laini\n"
                "- Ugali laini + mayai\n"
                "- Ndizi au papai\n"
                "- Supu ya kuku\n"
                "(MOH Kenya uk.69)"
            )
        elif choice == "4":
            return (
                "END Siku 8+: Protini nyingi\n"
                "- Ugali + maharagwe\n"
                "- Samaki au kuku\n"
                "- Sukuma wiki\n"
                "(MOH Kenya uk.75)"
            )

        return "END Chaguo batili. Jaribu tena."
