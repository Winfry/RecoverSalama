"""
ML Risk Scorer — classifies patient risk from daily check-in data.

This is the safety net of SalamaRecover. When a patient submits their
daily check-in (pain level, symptoms, mood), this model predicts their
risk level: LOW, MEDIUM, HIGH, or EMERGENCY.

How it works:
- Trained as an XGBoost classifier on synthetic check-in data (Phase 3)
- Input features: pain_level, symptom count, specific critical symptoms,
  days since surgery, mood score
- Output: risk category

Until the ML model is trained (Phase 3, Weeks 5-6), this uses
rule-based logic as a placeholder — which is actually how most
clinical decision support starts.

Critical symptoms that auto-escalate to HIGH/EMERGENCY:
- Fever above 38°C
- Wound bleeding
- Chest pain
- Difficulty breathing
"""

CRITICAL_SYMPTOMS = {
    "Fever above 38°C",
    "Wound bleeding",
    "Chest pain",
    "Difficulty breathing",
}


class RiskScorer:
    def __init__(self):
        self.model = None  # Will load XGBoost model in Phase 3
        # TODO: self.model = joblib.load("models/risk_classifier.pkl")

    def predict(
        self,
        pain_level: int,
        symptoms: list[str],
        mood: str,
        days_since_surgery: int,
    ) -> str:
        """
        Predict risk level from check-in data.
        Uses rule-based logic until ML model is trained.
        """
        # Check for critical symptoms first — these always escalate
        critical_count = sum(
            1 for s in symptoms if s in CRITICAL_SYMPTOMS
        )

        if critical_count >= 2:
            return "EMERGENCY"
        if critical_count == 1:
            return "HIGH"

        # Pain-based escalation
        if pain_level >= 8:
            return "HIGH"
        if pain_level >= 6:
            return "MEDIUM"

        # Symptom count escalation
        if len(symptoms) >= 3:
            return "MEDIUM"

        # Early post-op period is higher risk
        if days_since_surgery <= 3 and pain_level >= 5:
            return "MEDIUM"

        return "LOW"
