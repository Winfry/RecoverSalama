"""
Readmission Predictor — predicts 30-day hospital readmission risk.

This model helps hospitals identify which discharged patients are
most likely to be readmitted within 30 days, so they can intervene
proactively.

Powers the Analytics screen on the hospital dashboard (Phase 2).

Trained on:
- Patient demographics (age, gender, weight)
- Surgery type and complexity
- Check-in history (pain trends, symptom frequency)
- Compliance (how often they do check-ins)

Output: probability of readmission (0.0 to 1.0)
"""


class ReadmissionPredictor:
    def __init__(self):
        self.model = None  # Will load LightGBM model in Phase 3
        # TODO: self.model = joblib.load("models/readmission_model.pkl")

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
        Predict 30-day readmission probability.
        Returns a float between 0.0 (low risk) and 1.0 (high risk).
        Uses rule-based logic until ML model is trained.
        """
        score = 0.0

        # Age factor — older patients have higher readmission risk
        if age > 65:
            score += 0.15
        elif age > 50:
            score += 0.05

        # Critical symptoms are the strongest predictor
        score += critical_symptom_count * 0.2

        # High average pain correlates with complications
        if avg_pain > 7:
            score += 0.2
        elif avg_pain > 5:
            score += 0.1

        # Low compliance (few check-ins) means less visibility
        expected_checkins = max(days_since_surgery, 1)
        compliance_rate = checkin_count / expected_checkins
        if compliance_rate < 0.5:
            score += 0.1

        return min(score, 1.0)
