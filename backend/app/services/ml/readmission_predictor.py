"""
Readmission Predictor — Predicts 30-day Hospital Readmission Risk.

This system helps hospitals answer one critical question:
"Which of my discharged patients is most likely to come back?"

By identifying high-risk patients BEFORE they deteriorate, hospitals
can call them, adjust their care plan, or schedule an early follow-up
— preventing the readmission entirely.

Powers the Analytics screen on the hospital React dashboard.

TWO-LAYER ARCHITECTURE:
━━━━━━━━━━━━━━━━━━━━━━

Layer 1 — RULES (instant, deterministic, always runs):
    Scores based on known clinical readmission risk factors.
    Each factor adds to a cumulative risk score (0.0 to 1.0).
    Factors include:
    - Patient demographics (age, surgery complexity)
    - Pain trajectory (is pain going UP or DOWN over time?)
    - Symptom frequency (how often are warning symptoms reported?)
    - Check-in compliance (missed check-ins = invisible patient = danger)
    - Critical event history (any HIGH/EMERGENCY alerts in the past?)
    - Recovery stage vs expectations (is the patient behind schedule?)

Layer 2 — GEMINI (pattern recognition across full patient history):
    Given the patient's COMPLETE check-in history (not just today),
    Gemini identifies patterns that isolated rules can't catch:
    - "Pain was improving but reversed direction 3 days ago"
    - "Patient stopped reporting symptoms but mood keeps declining"
    - "Compliance dropped after Day 10 — patient may be disengaged"
    - "This combination of surgery type + age + symptom pattern
       matches profiles that typically get readmitted"

KEY DIFFERENCE FROM RISK SCORER:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Risk Scorer → looks at ONE check-in → "Is this patient in danger NOW?"
    Readmission Predictor → looks at ALL check-ins → "Will this patient
    end up back in hospital within 30 days?"

    The risk scorer is reactive (respond to today's data).
    The readmission predictor is predictive (forecast future outcomes).

OUTPUT:
    {
        "probability": 0.72,        # 0.0 = very unlikely, 1.0 = very likely
        "risk_category": "HIGH",    # LOW (<0.3), MEDIUM (0.3-0.6), HIGH (>0.6)
        "factors": [...],           # What's driving the risk up
        "recommendation": "...",    # What the hospital should do
        "source": "combined"        # "rules", "gemini", or "combined"
    }
"""

import json
import logging

from google import genai
from google.genai import types

from app.config import settings

logger = logging.getLogger(__name__)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLINICAL CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Surgery complexity tiers — affects baseline readmission risk
# Source: general surgical literature on 30-day readmission rates
SURGERY_COMPLEXITY = {
    # ── Existing ──────────────────────────────────────────────────────────────
    "Caesarean Section": 2,           # Moderate — abdominal, but common; common in Kenya
    "Appendectomy": 1,                # Low — routine, short recovery
    "Hernia Repair": 1,               # Low — usually outpatient
    "Cholecystectomy": 2,             # Moderate — bile leak risk
    "Knee Replacement": 3,            # High — long recovery, DVT risk
    "Hip Replacement": 3,             # High — long recovery, DVT risk; AVN common in Kenya
    "Mastectomy": 3,                  # High — complex; late-stage at presentation in Kenya
    # ── New surgery types ─────────────────────────────────────────────────────
    "Inguinal Hernia Repair": 1,      # Alias — same complexity as Hernia Repair
    "Knee Replacement (TKR)": 3,      # Alias
    "Hip Replacement (THR)": 3,       # Alias
    "Laparotomy": 2,                  # Moderate — wide range of pathology; adhesion risk
    "Hysterectomy": 2,                # Moderate — abdominal; DVT, vault dehiscence risk
    "Open Fracture Repair": 2,        # Moderate — infection / osteomyelitis risk; RTA common
    "Tubal Ligation": 1,              # Low — minor procedure; short recovery
    "Prostatectomy": 2,               # Moderate — anastomotic leak; incontinence monitoring
    "Thyroidectomy": 2,               # Moderate — hypocalcaemia + RLN injury monitoring
    "Myomectomy": 2,                  # Moderate — haemorrhage risk; common in Kenya (fibroids)
    "Cardiac Surgery": 3,             # High — highest complexity; ICU recovery; RHD dominant
}

# Risk category thresholds
def _categorize(probability: float) -> str:
    if probability >= 0.6:
        return "HIGH"
    elif probability >= 0.3:
        return "MEDIUM"
    return "LOW"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GEMINI READMISSION ASSESSMENT PROMPT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

READMISSION_PROMPT = """You are a clinical analytics system predicting 30-day hospital
readmission risk for post-surgical patients in Kenya.

PATIENT PROFILE:
- Age: {age}, Gender: {gender}
- Surgery: {surgery_type}
- Days since surgery: {days_since_surgery}
- Hospital: {hospital}

CHECK-IN HISTORY (most recent first):
{checkin_history}

TREND SUMMARY:
- Total check-ins completed: {checkin_count} out of {expected_checkins} expected
- Compliance rate: {compliance_pct}%
- Pain trend: {pain_trend}
- Average pain: {avg_pain}/10
- Critical alerts triggered: {critical_alert_count}
- Most common symptoms: {common_symptoms}
- Mood pattern: {mood_pattern}

CLINICAL FACTORS THAT PREDICT READMISSION:
1. Pain trajectory — increasing pain after initial improvement is a red flag
2. Low compliance — patients who stop checking in often deteriorate silently
3. Repeated critical symptoms — even if individual events resolved
4. Mood decline — depression/anxiety impairs healing and self-care
5. Surgery complexity — major surgeries have inherently higher readmission rates
6. Age — older patients have more complications
7. Early warning signs that were flagged but not acted on

Based on the complete patient history above, predict the probability of
30-day hospital readmission.

You MUST respond with ONLY valid JSON in this exact format, nothing else:
{{
    "probability": 0.0 to 1.0,
    "key_factors": ["factor 1", "factor 2", "factor 3"],
    "reasoning": "2-3 sentence clinical reasoning",
    "recommendation": "What the hospital should do for this patient"
}}
"""


class ReadmissionPredictor:
    """
    Two-layer readmission risk predictor: Rules + Gemini.

    Usage:
        predictor = ReadmissionPredictor()

        # Quick rules-only score (for dashboards, batch processing)
        score = predictor.predict(age=65, surgery_type="Knee Replacement", ...)

        # Full assessment with Gemini (for detailed patient review)
        result = await predictor.assess_readmission_risk(
            patient_profile={...},
            checkin_history=[...],
        )
    """

    def __init__(self):
        """Initialize Gemini client for Layer 2 pattern analysis."""
        try:
            self._client = genai.Client(api_key=settings.gemini_api_key)
            self.gemini_available = True
        except Exception as e:
            logger.warning(f"Gemini initialization failed: {e}. Using rules-only mode.")
            self.gemini_available = False

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # PUBLIC API
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def assess_readmission_risk(
        self,
        patient_profile: dict,
        checkin_history: list[dict],
    ) -> dict:
        """
        Full two-layer readmission risk assessment.

        Args:
            patient_profile: {name, age, gender, surgery_type,
                              surgery_date, hospital, days_since_surgery}
            checkin_history: List of past check-ins, each containing:
                            {date, pain_level, symptoms, mood, risk_level}

        Returns:
            {probability, risk_category, factors, reasoning,
             recommendation, source}
        """
        # ── Extract trend data from check-in history ──
        trends = self._analyze_trends(checkin_history, patient_profile)

        # ── Layer 1: Rules-based scoring ──
        rules_result = self._apply_rules(patient_profile, trends)

        # ── Layer 2: Gemini pattern analysis ──
        gemini_result = await self._gemini_assess(
            patient_profile, checkin_history, trends
        )

        # ── Combine: Take the higher probability ──
        if gemini_result is None:
            return rules_result

        if gemini_result["probability"] > rules_result["probability"]:
            # Gemini saw patterns the rules missed
            gemini_result["source"] = "gemini"
            return gemini_result
        else:
            rules_result["source"] = "combined"
            return rules_result

    def predict(
        self,
        age: int,
        surgery_type: str,
        checkin_count: int,
        avg_pain: float,
        critical_symptom_count: int,
        days_since_surgery: int,
    ) -> float:
        """
        Synchronous rules-only prediction.
        Returns just the probability float (0.0 to 1.0).
        Used for batch processing, hospital dashboard stats, sorting.
        """
        profile = {
            "age": age,
            "surgery_type": surgery_type,
            "days_since_surgery": days_since_surgery,
        }
        trends = {
            "checkin_count": checkin_count,
            "expected_checkins": max(days_since_surgery, 1),
            "avg_pain": avg_pain,
            "critical_alert_count": critical_symptom_count,
            "pain_trend": "unknown",
            "compliance_rate": checkin_count / max(days_since_surgery, 1),
            "mood_pattern": "unknown",
            "common_symptoms": [],
            "pain_values": [],
        }
        result = self._apply_rules(profile, trends)
        return result["probability"]

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # TREND ANALYSIS — Extracts patterns from check-in history
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _analyze_trends(
        self, checkin_history: list[dict], patient_profile: dict
    ) -> dict:
        """
        Extract meaningful trends from raw check-in history.
        This pre-processing is used by BOTH Layer 1 and Layer 2.
        """
        days_since_surgery = patient_profile.get("days_since_surgery", 1)
        expected_checkins = max(days_since_surgery, 1)
        checkin_count = len(checkin_history)

        if checkin_count == 0:
            return {
                "checkin_count": 0,
                "expected_checkins": expected_checkins,
                "compliance_rate": 0.0,
                "avg_pain": 0.0,
                "pain_values": [],
                "pain_trend": "no_data",
                "critical_alert_count": 0,
                "mood_pattern": "no_data",
                "common_symptoms": [],
            }

        # ── Pain analysis ──
        pain_values = [
            c.get("pain_level", 0) for c in checkin_history
        ]
        avg_pain = sum(pain_values) / len(pain_values)

        # Pain trend: compare last 3 check-ins to first 3
        pain_trend = "stable"
        if len(pain_values) >= 4:
            early_avg = sum(pain_values[:3]) / 3
            recent_avg = sum(pain_values[-3:]) / 3
            diff = recent_avg - early_avg
            if diff >= 1.5:
                pain_trend = "increasing"    # Bad — pain going up
            elif diff <= -1.5:
                pain_trend = "decreasing"    # Good — pain going down
            else:
                pain_trend = "stable"

        # ── Compliance ──
        compliance_rate = min(checkin_count / expected_checkins, 1.0)

        # ── Critical events ──
        critical_alert_count = sum(
            1 for c in checkin_history
            if c.get("risk_level") in ("HIGH", "EMERGENCY")
        )

        # ── Mood pattern ──
        moods = [c.get("mood", "Good") for c in checkin_history]
        negative_moods = {"Anxious", "Low", "Overwhelmed"}
        negative_count = sum(1 for m in moods if m in negative_moods)
        if len(moods) > 0 and negative_count / len(moods) >= 0.5:
            mood_pattern = "predominantly_negative"
        elif len(moods) >= 3 and all(m in negative_moods for m in moods[-3:]):
            mood_pattern = "recently_declining"
        else:
            mood_pattern = "mostly_positive"

        # ── Symptom frequency ──
        all_symptoms = []
        for c in checkin_history:
            all_symptoms.extend(c.get("symptoms", []))
        symptom_counts = {}
        for s in all_symptoms:
            symptom_counts[s] = symptom_counts.get(s, 0) + 1
        common_symptoms = sorted(
            symptom_counts.items(), key=lambda x: x[1], reverse=True
        )[:5]

        return {
            "checkin_count": checkin_count,
            "expected_checkins": expected_checkins,
            "compliance_rate": compliance_rate,
            "avg_pain": round(avg_pain, 1),
            "pain_values": pain_values,
            "pain_trend": pain_trend,
            "critical_alert_count": critical_alert_count,
            "mood_pattern": mood_pattern,
            "common_symptoms": common_symptoms,
        }

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # LAYER 1: RULE-BASED READMISSION SCORING
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _apply_rules(self, patient_profile: dict, trends: dict) -> dict:
        """
        Layer 1: Cumulative risk scoring based on known readmission factors.
        Each factor adds to a running score. Score is capped at 1.0.
        """
        score = 0.0
        factors = []

        age = patient_profile.get("age", 0)
        surgery_type = patient_profile.get("surgery_type", "Unknown")
        days_since_surgery = patient_profile.get("days_since_surgery", 1)

        # ── Factor 1: Age ──
        # Older patients have higher readmission rates across all surgeries
        if age >= 70:
            score += 0.15
            factors.append(f"Age {age} — significantly elevated readmission risk")
        elif age >= 60:
            score += 0.10
            factors.append(f"Age {age} — moderately elevated readmission risk")
        elif age >= 50:
            score += 0.05
            factors.append(f"Age {age} — slightly elevated readmission risk")

        # ── Factor 2: Surgery complexity ──
        complexity = SURGERY_COMPLEXITY.get(surgery_type, 2)
        if complexity == 3:
            score += 0.12
            factors.append(f"{surgery_type} is a high-complexity surgery")
        elif complexity == 2:
            score += 0.06
            factors.append(f"{surgery_type} is a moderate-complexity surgery")
        # complexity 1 adds nothing — low-risk surgery

        # ── Factor 3: Pain trajectory (most predictive factor) ──
        pain_trend = trends.get("pain_trend", "stable")
        avg_pain = trends.get("avg_pain", 0)

        if pain_trend == "increasing":
            # Pain going UP is the #1 readmission predictor
            score += 0.25
            factors.append(
                "CRITICAL: Pain is increasing over time "
                f"(avg {avg_pain}/10) — strongest readmission predictor"
            )
        elif avg_pain >= 7:
            score += 0.18
            factors.append(f"High average pain ({avg_pain}/10) throughout recovery")
        elif avg_pain >= 5:
            score += 0.08
            factors.append(f"Moderate average pain ({avg_pain}/10)")

        # Pain reversal — was improving, now getting worse
        pain_values = trends.get("pain_values", [])
        if len(pain_values) >= 5:
            # Check if there was a dip followed by a rise
            mid = len(pain_values) // 2
            first_half_avg = sum(pain_values[:mid]) / mid
            second_half_avg = sum(pain_values[mid:]) / (len(pain_values) - mid)
            min_pain = min(pain_values)
            if (
                first_half_avg > second_half_avg + 1  # Was improving
                and pain_values[-1] > min_pain + 2     # But now rising again
            ):
                score += 0.15
                factors.append(
                    "Pain reversal detected — was improving, now worsening again"
                )

        # ── Factor 4: Check-in compliance ──
        compliance = trends.get("compliance_rate", 1.0)

        if compliance == 0:
            # No check-ins at all — completely invisible patient
            score += 0.20
            factors.append(
                "CRITICAL: Zero check-ins completed — patient is invisible to care team"
            )
        elif compliance < 0.3:
            score += 0.15
            factors.append(
                f"Very low compliance ({compliance:.0%}) — patient rarely checks in"
            )
        elif compliance < 0.5:
            score += 0.10
            factors.append(
                f"Low compliance ({compliance:.0%}) — patient misses most check-ins"
            )
        elif compliance < 0.7:
            score += 0.05
            factors.append(
                f"Moderate compliance ({compliance:.0%}) — some check-ins missed"
            )

        # Compliance drop-off — was checking in, then stopped
        checkin_count = trends.get("checkin_count", 0)
        if days_since_surgery > 7 and checkin_count > 3:
            # Check if last check-in was more than 3 days ago
            # (we don't have exact dates here, but compliance rate dropping
            #  with high days_since_surgery suggests drop-off)
            if compliance < 0.4 and days_since_surgery > 10:
                score += 0.08
                factors.append("Patient appears to have stopped checking in recently")

        # ── Factor 5: Critical event history ──
        critical_count = trends.get("critical_alert_count", 0)

        if critical_count >= 3:
            score += 0.20
            factors.append(
                f"HIGH: {critical_count} critical alerts triggered during recovery"
            )
        elif critical_count == 2:
            score += 0.12
            factors.append(f"{critical_count} critical alerts during recovery")
        elif critical_count == 1:
            score += 0.06
            factors.append("1 critical alert triggered during recovery")

        # ── Factor 6: Mood pattern ──
        mood_pattern = trends.get("mood_pattern", "mostly_positive")

        if mood_pattern == "predominantly_negative":
            score += 0.10
            factors.append(
                "Predominantly negative mood — depression impairs healing and self-care"
            )
        elif mood_pattern == "recently_declining":
            score += 0.08
            factors.append("Mood declining recently — last 3 check-ins were negative")

        # ── Factor 7: Recurring symptoms ──
        common_symptoms = trends.get("common_symptoms", [])
        for symptom, count in common_symptoms:
            if count >= 3 and symptom in (
                "Fever above 38°C", "Wound bleeding", "Wound discharge",
                "Vomiting", "Redness around wound",
            ):
                score += 0.10
                factors.append(
                    f"Recurring symptom: {symptom} reported {count} times"
                )
                break  # Only count the top recurring serious symptom

        # ── Factor 8: Recovery timeline ──
        # If patient is significantly behind expected recovery progress
        if days_since_surgery > 14 and avg_pain > 5:
            score += 0.08
            factors.append(
                f"Behind expected recovery — Day {days_since_surgery} "
                f"with avg pain {avg_pain}/10 (should be <3 by now)"
            )

        # ── Cap at 1.0 and build result ──
        probability = min(score, 1.0)
        probability = round(probability, 2)

        # If no risk factors found, explicitly say so
        if not factors:
            factors.append("No significant readmission risk factors identified")

        return {
            "probability": probability,
            "risk_category": _categorize(probability),
            "factors": factors,
            "reasoning": self._build_reasoning(probability, factors),
            "recommendation": self._build_recommendation(probability, factors),
            "source": "rules",
        }

    def _build_reasoning(self, probability: float, factors: list[str]) -> str:
        """Build a human-readable reasoning summary from the risk factors."""
        category = _categorize(probability)
        factor_count = len(factors)

        if category == "HIGH":
            return (
                f"Readmission risk is HIGH ({probability:.0%}). "
                f"{factor_count} risk factor(s) identified. "
                f"Primary concern: {factors[0]}"
            )
        elif category == "MEDIUM":
            return (
                f"Readmission risk is MODERATE ({probability:.0%}). "
                f"{factor_count} risk factor(s) worth monitoring. "
                f"Top concern: {factors[0]}"
            )
        else:
            return (
                f"Readmission risk is LOW ({probability:.0%}). "
                "Recovery appears to be progressing normally."
            )

    def _build_recommendation(self, probability: float, factors: list[str]) -> str:
        """Build an actionable recommendation for hospital staff."""
        category = _categorize(probability)

        if category == "HIGH":
            return (
                "RECOMMEND: Schedule a phone call or follow-up visit within 48 hours. "
                "Review pain management plan. Consider early clinic appointment."
            )
        elif category == "MEDIUM":
            return (
                "RECOMMEND: Monitor this patient's check-ins closely over the next "
                "3-5 days. Send a WhatsApp check-in if compliance drops. "
                "Flag for review at next team meeting."
            )
        else:
            return (
                "No immediate action needed. Continue routine monitoring. "
                "Patient appears to be recovering well."
            )

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # LAYER 2: GEMINI PATTERN ANALYSIS
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def _gemini_assess(
        self,
        patient_profile: dict,
        checkin_history: list[dict],
        trends: dict,
    ) -> dict | None:
        """
        Layer 2: Gemini analyzes full patient history for patterns.
        Returns None if Gemini is unavailable (graceful fallback to rules).
        """
        if not self.gemini_available:
            return None

        # Don't call Gemini if there's no history to analyze
        if len(checkin_history) < 2:
            return None

        # Format check-in history for the prompt (last 14 check-ins max)
        recent_history = checkin_history[-14:]
        history_text = "\n".join(
            f"  Day {c.get('days_since_surgery', '?')}: "
            f"Pain {c.get('pain_level', '?')}/10, "
            f"Symptoms: {', '.join(c.get('symptoms', [])) or 'None'}, "
            f"Mood: {c.get('mood', '?')}, "
            f"Risk: {c.get('risk_level', '?')}"
            for c in recent_history
        )

        # Format common symptoms
        common_symptoms_text = ", ".join(
            f"{s} ({count}x)" for s, count in trends.get("common_symptoms", [])
        ) or "None recurring"

        compliance_pct = round(trends.get("compliance_rate", 0) * 100)

        prompt = READMISSION_PROMPT.format(
            age=patient_profile.get("age", "Unknown"),
            gender=patient_profile.get("gender", "Unknown"),
            surgery_type=patient_profile.get("surgery_type", "Unknown"),
            days_since_surgery=patient_profile.get("days_since_surgery", "Unknown"),
            hospital=patient_profile.get("hospital", "Unknown"),
            checkin_history=history_text or "  No check-in data available",
            checkin_count=trends.get("checkin_count", 0),
            expected_checkins=trends.get("expected_checkins", 1),
            compliance_pct=compliance_pct,
            pain_trend=trends.get("pain_trend", "unknown"),
            avg_pain=trends.get("avg_pain", 0),
            critical_alert_count=trends.get("critical_alert_count", 0),
            common_symptoms=common_symptoms_text,
            mood_pattern=trends.get("mood_pattern", "unknown"),
        )

        try:
            response = self._client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.2,
                    top_p=0.8,
                    max_output_tokens=512,
                    response_mime_type="application/json",
                ),
            )
            result = json.loads(response.text)

            probability = float(result.get("probability", 0))
            probability = max(0.0, min(1.0, probability))  # Clamp to 0-1

            key_factors = result.get("key_factors", [])
            reasoning = result.get("reasoning", "AI pattern analysis")
            recommendation = result.get("recommendation", "Monitor patient.")

            return {
                "probability": round(probability, 2),
                "risk_category": _categorize(probability),
                "factors": key_factors,
                "reasoning": reasoning,
                "recommendation": recommendation,
                "source": "gemini",
            }

        except json.JSONDecodeError as e:
            logger.warning(f"Gemini returned invalid JSON for readmission: {e}")
            return None
        except Exception as e:
            logger.warning(f"Gemini readmission assessment failed: {e}")
            return None
