"""
Mood Classifier — tracks mental health trends over time.

Takes mood check-in data from Flutter Screen 07 and classifies
the patient's mental health state. This helps identify patients
who may need additional support or counselling referral.

In MVP, this is rule-based. In Phase 3, it can be trained on
mood + text data to detect early signs of post-surgical depression.
"""


class MoodClassifier:
    # Mood severity mapping
    MOOD_SCORES = {
        "Okay": 1,
        "Tired": 2,
        "Anxious": 3,
        "Overwhelmed": 4,
    }

    def classify(self, mood: str, recent_moods: list[str] | None = None) -> dict:
        """
        Classify mental health state based on current and recent moods.
        Returns a risk assessment and recommended action.
        """
        score = self.MOOD_SCORES.get(mood, 2)

        # Check for persistent negative mood
        if recent_moods:
            recent_scores = [
                self.MOOD_SCORES.get(m, 2) for m in recent_moods[-7:]
            ]
            avg_score = sum(recent_scores) / len(recent_scores)
        else:
            avg_score = score

        if avg_score >= 3.5 or score == 4:
            return {
                "level": "needs_support",
                "message": "Consider speaking to a counsellor. "
                "Befrienders Kenya: 0722 178 177",
                "action": "refer_counselling",
            }
        elif avg_score >= 2.5:
            return {
                "level": "monitor",
                "message": "Your mood has been low recently. "
                "Try talking to a friend or family member.",
                "action": "encourage_social",
            }
        else:
            return {
                "level": "stable",
                "message": "Keep up the positive attitude — it helps healing!",
                "action": "none",
            }
