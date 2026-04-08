"""
Risk Scorer — Two-Layer Patient Risk Classification System.

This is the safety net of SalamaRecover. When a patient submits their
daily check-in (pain level, symptoms, mood), this system predicts their
risk level: LOW, MEDIUM, HIGH, or EMERGENCY.

TWO-LAYER ARCHITECTURE:
━━━━━━━━━━━━━━━━━━━━━━

Layer 1 — RULES (fires first, instant, free, works offline):
    Hard-coded clinical rules that catch obvious danger signals.
    These are non-negotiable — they ALWAYS fire, regardless of
    what Gemini thinks. Examples:
    - Fever + wound bleeding → EMERGENCY (always)
    - Pain 9-10 → at least HIGH (always)
    - Chest pain or difficulty breathing → EMERGENCY (always)

Layer 2 — GEMINI (fires second, catches subtle patterns):
    For cases where rules say LOW or MEDIUM, Gemini provides a
    clinical second opinion. Gemini can catch combinations that
    simple rules miss. Examples:
    - Pain 5 + nausea on Day 3 post-appendectomy → possible
      bowel obstruction → Gemini escalates to MEDIUM
    - Mild headache + dizziness + Day 1 post-surgery → possible
      anaesthesia reaction → Gemini escalates to MEDIUM
    - Pain 4 + no symptoms + Day 14 → Gemini confirms LOW

LOGIC FLOW:
━━━━━━━━━━━
    Patient check-in arrives
        → Run Layer 1 rules (instant, no API call)
        → If rules say HIGH or EMERGENCY → return immediately
        → If rules say LOW or MEDIUM → call Gemini for second opinion
        → Compare both assessments
        → Return the HIGHER of the two (always err on side of caution)
        → If Gemini call fails → fall back to rules-only result

WHY THIS DESIGN:
    - Rules guarantee safety (critical symptoms are NEVER missed)
    - Gemini adds clinical intelligence (subtle patterns ARE caught)
    - Patient always gets the more cautious assessment
    - If Gemini API is down, the system still works (rules-only fallback)
    - Free tier Gemini is only called when needed (not for obvious cases)
"""

import json
import logging

import google.generativeai as genai

from app.config import settings

logger = logging.getLogger(__name__)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLINICAL CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Symptoms that ALWAYS escalate — no exceptions, no AI override
CRITICAL_SYMPTOMS = {
    "Fever above 38°C",
    "Wound bleeding",
    "Chest pain",
    "Difficulty breathing",
    "Sudden severe headache",
    "Loss of consciousness",
    "Unable to urinate",
}

# Symptoms that are concerning but not immediately critical
WARNING_SYMPTOMS = {
    "Swelling",
    "Redness around wound",
    "Nausea",
    "Vomiting",
    "Dizziness",
    "Mild headache",
    "Constipation",
    "Loss of appetite",
    "Wound discharge",
    "Numbness or tingling",
}

# Risk level ordering — used for comparisons
RISK_LEVELS = {"LOW": 0, "MEDIUM": 1, "HIGH": 2, "EMERGENCY": 3}

# Mood to numeric score — used by both layers
MOOD_SCORES = {"Good": 1, "Tired": 2, "Anxious": 3, "Low": 4, "Overwhelmed": 4}

# Surgery types with their high-risk windows (days post-op where
# complications are most likely). Source: WHO surgical safety guidelines.
HIGH_RISK_WINDOWS = {
    # ── Existing ──────────────────────────────────────────────────────────────
    "Caesarean Section": (3, 7),       # SSI risk peaks Day 3-7
    "Appendectomy": (2, 5),            # Bowel obstruction / stump leak risk
    "Hernia Repair": (3, 7),           # Wound complication / mesh infection risk
    "Cholecystectomy": (1, 4),         # Bile leak risk peaks early
    "Knee Replacement": (2, 7),        # DVT risk window
    # ── New surgery types ─────────────────────────────────────────────────────
    "Inguinal Hernia Repair": (3, 7),  # Alias — same window as Hernia Repair
    "Knee Replacement (TKR)": (2, 7),  # Alias — same as Knee Replacement
    "Laparotomy": (2, 7),              # Ileus, wound dehiscence, intra-abdominal sepsis
    "Hysterectomy": (3, 7),            # Vault dehiscence, DVT, haemorrhage Day 3-7
    "Open Fracture Repair": (2, 14),   # Infection / osteomyelitis risk — extended window
    "Tubal Ligation": (1, 3),          # Low-risk minor procedure; early complication window
    "Prostatectomy": (2, 7),           # Anastomotic leak, urinary complications Day 2-7
    "Thyroidectomy": (1, 3),           # Haematoma (airway risk) + hypocalcaemia Day 1-3
    "Hip Replacement": (2, 7),         # DVT / dislocation risk window
    "Hip Replacement (THR)": (2, 7),   # Alias
    "Mastectomy": (2, 7),              # Seroma, wound infection, flap necrosis
    "Myomectomy": (3, 7),              # Haemorrhage, adhesion formation
    "Cardiac Surgery": (1, 14),        # Arrhythmia, sternal wound, low output — extended
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GEMINI RISK ASSESSMENT PROMPT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RISK_ASSESSMENT_PROMPT = """You are a clinical decision support system for post-surgical
recovery monitoring in Kenya. You are NOT making a diagnosis. You are assessing risk
level to determine if the patient needs clinical attention.

PATIENT CHECK-IN DATA:
- Surgery type: {surgery_type}
- Days since surgery: {days_since_surgery}
- Pain level: {pain_level}/10
- Reported symptoms: {symptoms}
- Current mood: {mood}
- Patient age: {age}
- Patient gender: {gender}

CLINICAL KNOWLEDGE:
- Day 1-2 post-op: Pain 4-6 is normal, mild nausea from anaesthesia is expected
- Day 3-7 post-op: Highest risk for surgical site infection (SSI)
  SSI signs: fever + wound redness/warmth/swelling/discharge
- Day 7-14: Pain should be decreasing. Persistent or increasing pain is a warning.
- Day 14+: Most patients should be significantly improved. High pain is abnormal.
- Nausea + abdominal distension after abdominal surgery = possible bowel obstruction
- Calf pain + swelling after lower limb surgery = possible DVT (deep vein thrombosis)
- Persistent low mood (3+ days) = post-surgical depression risk

RISK DEFINITIONS:
- LOW: Recovery is progressing normally. No intervention needed.
- MEDIUM: Something to watch. Patient should monitor symptoms and contact doctor if worsening.
- HIGH: Clinical attention recommended. Patient should contact their hospital today.
- EMERGENCY: Immediate medical help needed. Patient should call 999 or go to nearest hospital.

Based on the check-in data and clinical knowledge above, assess this patient's risk level.

You MUST respond with ONLY valid JSON in this exact format, nothing else:
{{"risk_level": "LOW|MEDIUM|HIGH|EMERGENCY", "reasoning": "Brief clinical reasoning (1-2 sentences)", "recommendation": "What the patient should do next"}}
"""


class RiskScorer:
    """
    Two-layer risk classification: Rules + Gemini.

    Usage:
        scorer = RiskScorer()
        result = await scorer.assess_risk(
            pain_level=7,
            symptoms=["Fever above 38°C", "Wound redness"],
            mood="Anxious",
            days_since_surgery=5,
            surgery_type="Caesarean Section",
            age=28,
            gender="Female",
        )
        # result = {
        #     "risk_level": "HIGH",
        #     "source": "rules",  # or "gemini" or "combined"
        #     "reasoning": "Critical symptom: Fever above 38°C",
        #     "recommendation": "Contact your hospital immediately."
        # }
    """

    def __init__(self):
        """Initialize Gemini for Layer 2 assessments."""
        try:
            genai.configure(api_key=settings.gemini_api_key)
            self.model = genai.GenerativeModel(
                model_name="gemini-2.0-flash",
                generation_config={
                    "temperature": 0.1,  # Low temp = more consistent clinical judgement
                    "top_p": 0.8,
                    "max_output_tokens": 256,
                    "response_mime_type": "application/json",  # Force JSON output
                },
            )
            self.gemini_available = True
        except Exception as e:
            logger.warning(f"Gemini initialization failed: {e}. Using rules-only mode.")
            self.gemini_available = False

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # PUBLIC API
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def assess_risk(
        self,
        pain_level: int,
        symptoms: list[str],
        mood: str,
        days_since_surgery: int,
        surgery_type: str = "Unknown",
        age: int = 0,
        gender: str = "",
    ) -> dict:
        """
        Full two-layer risk assessment.

        Returns dict with: risk_level, source, reasoning, recommendation
        """
        # ── Layer 1: Rules (instant, always runs) ──
        rules_result = self._apply_rules(
            pain_level=pain_level,
            symptoms=symptoms,
            mood=mood,
            days_since_surgery=days_since_surgery,
            surgery_type=surgery_type,
        )

        # If rules say HIGH or EMERGENCY, return immediately — no need for Gemini
        if RISK_LEVELS[rules_result["risk_level"]] >= RISK_LEVELS["HIGH"]:
            return rules_result

        # ── Layer 2: Gemini (clinical second opinion) ──
        gemini_result = await self._gemini_assess(
            pain_level=pain_level,
            symptoms=symptoms,
            mood=mood,
            days_since_surgery=days_since_surgery,
            surgery_type=surgery_type,
            age=age,
            gender=gender,
        )

        # If Gemini failed, fall back to rules-only
        if gemini_result is None:
            return rules_result

        # ── Combine: Take the HIGHER risk level ──
        rules_level = RISK_LEVELS[rules_result["risk_level"]]
        gemini_level = RISK_LEVELS[gemini_result["risk_level"]]

        if gemini_level > rules_level:
            # Gemini caught something the rules missed
            gemini_result["source"] = "gemini"
            return gemini_result
        else:
            # Rules and Gemini agree, or rules were more cautious
            rules_result["source"] = "combined"
            return rules_result

    def predict(
        self,
        pain_level: int,
        symptoms: list[str],
        mood: str,
        days_since_surgery: int,
    ) -> str:
        """
        Synchronous rules-only prediction.
        Used by endpoints that can't await (or when Gemini is unavailable).
        Returns just the risk level string.
        """
        result = self._apply_rules(
            pain_level=pain_level,
            symptoms=symptoms,
            mood=mood,
            days_since_surgery=days_since_surgery,
        )
        return result["risk_level"]

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # LAYER 1: RULE-BASED ASSESSMENT
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _apply_rules(
        self,
        pain_level: int,
        symptoms: list[str],
        mood: str,
        days_since_surgery: int,
        surgery_type: str = "Unknown",
    ) -> dict:
        """
        Layer 1: Hard-coded clinical rules.
        Instant, free, works offline. Non-negotiable safety catches.
        """
        reported_symptoms = set(symptoms)
        critical_found = reported_symptoms & CRITICAL_SYMPTOMS
        warning_found = reported_symptoms & WARNING_SYMPTOMS
        critical_count = len(critical_found)
        warning_count = len(warning_found)
        mood_score = MOOD_SCORES.get(mood, 2)

        # ── EMERGENCY triggers (immediate, non-negotiable) ──

        # 2+ critical symptoms = EMERGENCY
        if critical_count >= 2:
            return {
                "risk_level": "EMERGENCY",
                "source": "rules",
                "reasoning": f"Multiple critical symptoms: {', '.join(critical_found)}. "
                "This combination requires immediate medical attention.",
                "recommendation": "Go to the nearest hospital NOW or call 999/112.",
            }

        # Loss of consciousness or difficulty breathing = always EMERGENCY
        if "Loss of consciousness" in reported_symptoms:
            return {
                "risk_level": "EMERGENCY",
                "source": "rules",
                "reasoning": "Loss of consciousness after surgery is a medical emergency.",
                "recommendation": "Call 999/112 immediately. Do not wait.",
            }

        if "Difficulty breathing" in reported_symptoms:
            return {
                "risk_level": "EMERGENCY",
                "source": "rules",
                "reasoning": "Difficulty breathing after surgery could indicate "
                "pulmonary embolism or other serious complication.",
                "recommendation": "Call 999/112 immediately.",
            }

        # Chest pain = EMERGENCY (possible pulmonary embolism)
        if "Chest pain" in reported_symptoms:
            return {
                "risk_level": "EMERGENCY",
                "source": "rules",
                "reasoning": "Chest pain after surgery could indicate "
                "pulmonary embolism, especially within the first 2 weeks.",
                "recommendation": "Call 999/112 or go to the nearest hospital NOW.",
            }

        # Extreme pain (9-10) = EMERGENCY
        if pain_level >= 9:
            return {
                "risk_level": "EMERGENCY",
                "source": "rules",
                "reasoning": f"Extreme pain level ({pain_level}/10) after surgery "
                "indicates a possible serious complication.",
                "recommendation": "Contact your hospital immediately or call 999.",
            }

        # ── HIGH triggers ──

        # 1 critical symptom = HIGH
        if critical_count == 1:
            symptom_name = next(iter(critical_found))
            return {
                "risk_level": "HIGH",
                "source": "rules",
                "reasoning": f"Critical symptom detected: {symptom_name}. "
                "This needs clinical assessment.",
                "recommendation": "Contact your hospital today. Don't wait until tomorrow.",
            }

        # Pain 8 = HIGH
        if pain_level == 8:
            return {
                "risk_level": "HIGH",
                "source": "rules",
                "reasoning": f"High pain level ({pain_level}/10) is above expected "
                f"recovery range for Day {days_since_surgery}.",
                "recommendation": "Contact your hospital for pain management review.",
            }

        # Fever + any wound sign during high-risk window = HIGH (possible SSI)
        if "Fever above 38°C" in reported_symptoms and (
            "Redness around wound" in reported_symptoms
            or "Wound discharge" in reported_symptoms
            or "Swelling" in reported_symptoms
        ):
            return {
                "risk_level": "HIGH",
                "source": "rules",
                "reasoning": "Fever combined with wound signs suggests possible "
                "surgical site infection (SSI).",
                "recommendation": "Contact your hospital today for wound assessment.",
            }

        # ── MEDIUM triggers ──

        # Pain 6-7
        if pain_level >= 6:
            return {
                "risk_level": "MEDIUM",
                "source": "rules",
                "reasoning": f"Moderate-high pain ({pain_level}/10) on Day "
                f"{days_since_surgery}. This should be monitored.",
                "recommendation": "Monitor your pain. If it increases or doesn't "
                "improve with medication, contact your doctor.",
            }

        # 3+ warning symptoms at once
        if warning_count >= 3:
            return {
                "risk_level": "MEDIUM",
                "source": "rules",
                "reasoning": f"Multiple symptoms reported ({warning_count} symptoms). "
                "While none are individually critical, the combination warrants monitoring.",
                "recommendation": "Keep tracking your symptoms. If any worsen, "
                "contact your doctor.",
            }

        # High-risk window + elevated pain
        risk_window = HIGH_RISK_WINDOWS.get(surgery_type)
        if risk_window:
            window_start, window_end = risk_window
            if window_start <= days_since_surgery <= window_end and pain_level >= 4:
                return {
                    "risk_level": "MEDIUM",
                    "source": "rules",
                    "reasoning": f"Day {days_since_surgery} is within the high-risk window "
                    f"(Day {window_start}-{window_end}) for {surgery_type} complications. "
                    f"Pain level {pain_level}/10 warrants closer monitoring.",
                    "recommendation": "This is a critical period in your recovery. "
                    "Watch for any new symptoms and contact your doctor if concerned.",
                }

        # Early post-op + moderate pain
        if days_since_surgery <= 3 and pain_level >= 5:
            return {
                "risk_level": "MEDIUM",
                "source": "rules",
                "reasoning": f"Early recovery (Day {days_since_surgery}) with "
                f"moderate pain ({pain_level}/10). Early days carry higher risk.",
                "recommendation": "Rest, take prescribed medication, and monitor symptoms.",
            }

        # Persistent negative mood (this rule is basic — Gemini will do better)
        if mood_score >= 4:
            return {
                "risk_level": "MEDIUM",
                "source": "rules",
                "reasoning": f"Patient reports feeling '{mood}'. Emotional distress "
                "can impact physical recovery.",
                "recommendation": "Talk to someone you trust. Befrienders Kenya: 0722 178 177.",
            }

        # Late recovery + unexpected pain
        if days_since_surgery > 14 and pain_level >= 4:
            return {
                "risk_level": "MEDIUM",
                "source": "rules",
                "reasoning": f"Pain level {pain_level}/10 on Day {days_since_surgery} "
                "is higher than expected. By this stage, pain should be minimal.",
                "recommendation": "Mention this at your next follow-up appointment, "
                "or contact your doctor if the pain is new or worsening.",
            }

        # ── LOW — everything looks normal ──
        return {
            "risk_level": "LOW",
            "source": "rules",
            "reasoning": f"Day {days_since_surgery} recovery appears normal. "
            f"Pain {pain_level}/10, no critical symptoms.",
            "recommendation": "Keep up your recovery routine. Stay hydrated, "
            "eat well, and do your daily check-in tomorrow.",
        }

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # LAYER 2: GEMINI CLINICAL ASSESSMENT
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def _gemini_assess(
        self,
        pain_level: int,
        symptoms: list[str],
        mood: str,
        days_since_surgery: int,
        surgery_type: str,
        age: int,
        gender: str,
    ) -> dict | None:
        """
        Layer 2: Gemini clinical second opinion.
        Catches subtle symptom combinations that rules miss.
        Returns None if Gemini is unavailable (graceful fallback).
        """
        if not self.gemini_available:
            return None

        # Build the prompt with patient data
        prompt = RISK_ASSESSMENT_PROMPT.format(
            surgery_type=surgery_type,
            days_since_surgery=days_since_surgery,
            pain_level=pain_level,
            symptoms=", ".join(symptoms) if symptoms else "None reported",
            mood=mood,
            age=age if age > 0 else "Unknown",
            gender=gender or "Unknown",
        )

        try:
            response = self.model.generate_content(prompt)
            result = json.loads(response.text)

            # Validate the response has required fields
            risk_level = result.get("risk_level", "").upper()
            if risk_level not in RISK_LEVELS:
                logger.warning(f"Gemini returned invalid risk level: {risk_level}")
                return None

            return {
                "risk_level": risk_level,
                "source": "gemini",
                "reasoning": result.get("reasoning", "AI assessment"),
                "recommendation": result.get("recommendation", "Monitor your symptoms."),
            }

        except json.JSONDecodeError as e:
            logger.warning(f"Gemini returned invalid JSON: {e}")
            return None
        except Exception as e:
            logger.warning(f"Gemini risk assessment failed: {e}")
            return None
