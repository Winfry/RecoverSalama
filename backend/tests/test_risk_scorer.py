"""
Tests for the rule-based Layer 1 of the risk scorer.

These tests verify that the hard-coded safety rules ALWAYS fire correctly.
They only test Layer 1 (rules) — no Gemini calls, so they're fast, free,
and work offline.

Run with: pytest backend/tests/test_risk_scorer.py

Layer 2 (Gemini) is tested in:
  - ml/notebooks/02_gemini_clinical_prompts.ipynb (interactive)
  - ml/notebooks/04_prompt_evaluation.ipynb (automated scorecard)
"""

from app.services.ml.risk_scorer import RiskScorer


# Create scorer instance (Gemini may or may not initialize depending
# on whether API key is set — that's fine, we only test rules here)
scorer = RiskScorer()


# ── EMERGENCY tests — these must NEVER fail ──

def test_emergency_multiple_critical_symptoms():
    """Two or more critical symptoms = EMERGENCY, always."""
    result = scorer.predict(
        pain_level=7,
        symptoms=["Fever above 38°C", "Wound bleeding"],
        mood="Anxious",
        days_since_surgery=5,
    )
    assert result == "EMERGENCY", f"Expected EMERGENCY, got {result}"


def test_emergency_chest_pain():
    """Chest pain alone = EMERGENCY (possible pulmonary embolism)."""
    result = scorer.predict(
        pain_level=4,
        symptoms=["Chest pain"],
        mood="Anxious",
        days_since_surgery=7,
    )
    assert result == "EMERGENCY", f"Expected EMERGENCY, got {result}"


def test_emergency_difficulty_breathing():
    """Difficulty breathing = EMERGENCY."""
    result = scorer.predict(
        pain_level=5,
        symptoms=["Difficulty breathing"],
        mood="Anxious",
        days_since_surgery=3,
    )
    assert result == "EMERGENCY", f"Expected EMERGENCY, got {result}"


def test_emergency_extreme_pain():
    """Pain 9-10 = EMERGENCY."""
    result = scorer.predict(
        pain_level=9,
        symptoms=[],
        mood="Low",
        days_since_surgery=5,
    )
    assert result == "EMERGENCY", f"Expected EMERGENCY, got {result}"


# ── HIGH tests ──

def test_high_single_critical_symptom():
    """One critical symptom = HIGH."""
    result = scorer.predict(
        pain_level=5,
        symptoms=["Fever above 38°C"],
        mood="Tired",
        days_since_surgery=5,
    )
    assert result == "HIGH", f"Expected HIGH, got {result}"


def test_high_pain_eight():
    """Pain level 8 = HIGH."""
    result = scorer.predict(
        pain_level=8,
        symptoms=[],
        mood="Tired",
        days_since_surgery=7,
    )
    assert result == "HIGH", f"Expected HIGH, got {result}"


def test_high_wound_bleeding_alone():
    """Wound bleeding alone = HIGH."""
    result = scorer.predict(
        pain_level=4,
        symptoms=["Wound bleeding"],
        mood="Good",
        days_since_surgery=6,
    )
    assert result == "HIGH", f"Expected HIGH, got {result}"


# ── MEDIUM tests ──

def test_medium_moderate_pain():
    """Pain 6-7 = MEDIUM."""
    result = scorer.predict(
        pain_level=6,
        symptoms=[],
        mood="Good",
        days_since_surgery=10,
    )
    assert result == "MEDIUM", f"Expected MEDIUM, got {result}"


def test_medium_early_postop_with_pain():
    """Early post-op (Day 1-3) with pain >= 5 = MEDIUM."""
    result = scorer.predict(
        pain_level=5,
        symptoms=[],
        mood="Tired",
        days_since_surgery=2,
    )
    assert result == "MEDIUM", f"Expected MEDIUM, got {result}"


def test_medium_overwhelmed_mood():
    """Overwhelmed mood = MEDIUM (mental health concern)."""
    result = scorer.predict(
        pain_level=3,
        symptoms=[],
        mood="Overwhelmed",
        days_since_surgery=10,
    )
    assert result == "MEDIUM", f"Expected MEDIUM, got {result}"


# ── LOW tests ──

def test_low_normal_recovery():
    """Normal recovery — low pain, no symptoms, good mood = LOW."""
    result = scorer.predict(
        pain_level=2,
        symptoms=[],
        mood="Good",
        days_since_surgery=14,
    )
    assert result == "LOW", f"Expected LOW, got {result}"


def test_low_minimal_symptoms():
    """Very low pain, no critical symptoms = LOW."""
    result = scorer.predict(
        pain_level=1,
        symptoms=[],
        mood="Good",
        days_since_surgery=21,
    )
    assert result == "LOW", f"Expected LOW, got {result}"
