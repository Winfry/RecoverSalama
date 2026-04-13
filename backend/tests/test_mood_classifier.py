"""
Tests for MoodClassifier — rule-based, no API calls needed.

Verifies that mood trend detection and mental health level
classification work correctly.
"""

from app.services.ml.mood_classifier import MoodClassifier

classifier = MoodClassifier()


# ── Single mood classification ───────────────────────────────

def test_okay_mood_is_stable():
    result = classifier.classify("Okay", [])
    assert result["level"] == "stable"


def test_tired_mood_is_stable_or_monitor():
    result = classifier.classify("Tired", [])
    assert result["level"] in ("stable", "monitor")


def test_overwhelmed_mood_needs_support():
    """Overwhelmed alone should trigger needs_support."""
    result = classifier.classify("Overwhelmed", [])
    assert result["level"] == "needs_support"


# ── Trend detection ──────────────────────────────────────────

def test_persistent_negative_trend_needs_support():
    """History dominated by Overwhelmed (score=4) pushes avg above 3.5 → needs_support."""
    history = ["Overwhelmed", "Overwhelmed", "Overwhelmed", "Anxious", "Overwhelmed", "Overwhelmed", "Overwhelmed"]
    result = classifier.classify("Overwhelmed", history)
    assert result["level"] == "needs_support"


def test_persistent_anxious_trend_is_monitor():
    """All Anxious (score=3) gives avg=3.0, which is >= 2.5 but < 3.5 → monitor."""
    history = ["Anxious", "Anxious", "Anxious", "Anxious", "Anxious", "Anxious", "Anxious"]
    result = classifier.classify("Anxious", history)
    assert result["level"] == "monitor"


def test_recently_declining_triggers_monitor():
    """Mixed history with recent negatives — avg >= 2.5 → monitor."""
    history = ["Okay", "Tired", "Anxious", "Anxious", "Anxious", "Anxious"]
    result = classifier.classify("Anxious", history)
    assert result["level"] in ("monitor", "needs_support")


# ── Response structure ───────────────────────────────────────

def test_result_has_required_keys():
    result = classifier.classify("Tired", ["Okay", "Tired"])
    assert "level" in result
    assert "message" in result
    assert "action" in result


def test_needs_support_includes_helpline():
    """Befrienders Kenya number should appear in needs_support message."""
    result = classifier.classify("Overwhelmed", [])
    assert "0722" in result["message"] or "Befrienders" in result["message"]
