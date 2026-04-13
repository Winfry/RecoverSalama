"""
Tests for ReadmissionPredictor Layer 1 (rules-only).

Uses the synchronous predict() method — no Gemini, no DB, no network.
Verifies that the rules-based scoring produces clinically sensible results.
"""

from app.services.ml.readmission_predictor import ReadmissionPredictor, _categorize

predictor = ReadmissionPredictor()


# ── _categorize helper ───────────────────────────────────────

def test_categorize_low():
    assert _categorize(0.1) == "LOW"
    assert _categorize(0.29) == "LOW"


def test_categorize_medium():
    assert _categorize(0.3) == "MEDIUM"
    assert _categorize(0.59) == "MEDIUM"


def test_categorize_high():
    assert _categorize(0.6) == "HIGH"
    assert _categorize(1.0) == "HIGH"


# ── Compliance factor ────────────────────────────────────────

def test_zero_checkins_raises_risk():
    """A patient who never checked in is invisible — high risk."""
    prob = predictor.predict(
        age=35,
        surgery_type="Appendectomy",
        checkin_count=0,
        avg_pain=0,
        critical_symptom_count=0,
        days_since_surgery=14,
    )
    assert prob >= 0.2, f"Expected >= 0.2 for zero compliance, got {prob}"


def test_good_compliance_low_pain_is_low_risk():
    prob = predictor.predict(
        age=30,
        surgery_type="Appendectomy",
        checkin_count=14,
        avg_pain=2.0,
        critical_symptom_count=0,
        days_since_surgery=14,
    )
    assert prob < 0.3, f"Expected LOW risk, got {prob}"


# ── Surgery complexity factor ────────────────────────────────

def test_cardiac_surgery_higher_than_appendectomy():
    """High-complexity surgery should score higher than low-complexity."""
    cardiac = predictor.predict(
        age=50, surgery_type="Cardiac Surgery",
        checkin_count=10, avg_pain=3.0,
        critical_symptom_count=0, days_since_surgery=10,
    )
    appendectomy = predictor.predict(
        age=50, surgery_type="Appendectomy",
        checkin_count=10, avg_pain=3.0,
        critical_symptom_count=0, days_since_surgery=10,
    )
    assert cardiac > appendectomy


# ── Age factor ───────────────────────────────────────────────

def test_elderly_patient_higher_risk():
    young = predictor.predict(
        age=25, surgery_type="Hernia Repair",
        checkin_count=7, avg_pain=2.0,
        critical_symptom_count=0, days_since_surgery=7,
    )
    elderly = predictor.predict(
        age=75, surgery_type="Hernia Repair",
        checkin_count=7, avg_pain=2.0,
        critical_symptom_count=0, days_since_surgery=7,
    )
    assert elderly > young


# ── Critical events factor ───────────────────────────────────

def test_multiple_critical_events_raises_risk():
    no_events = predictor.predict(
        age=40, surgery_type="Caesarean Section",
        checkin_count=10, avg_pain=3.0,
        critical_symptom_count=0, days_since_surgery=10,
    )
    many_events = predictor.predict(
        age=40, surgery_type="Caesarean Section",
        checkin_count=10, avg_pain=3.0,
        critical_symptom_count=3, days_since_surgery=10,
    )
    assert many_events > no_events


# ── High pain factor ─────────────────────────────────────────

def test_high_avg_pain_raises_risk():
    low_pain = predictor.predict(
        age=40, surgery_type="Hysterectomy",
        checkin_count=10, avg_pain=2.0,
        critical_symptom_count=0, days_since_surgery=10,
    )
    high_pain = predictor.predict(
        age=40, surgery_type="Hysterectomy",
        checkin_count=10, avg_pain=8.0,
        critical_symptom_count=0, days_since_surgery=10,
    )
    assert high_pain > low_pain


# ── Probability bounds ───────────────────────────────────────

def test_probability_never_exceeds_1():
    prob = predictor.predict(
        age=90, surgery_type="Cardiac Surgery",
        checkin_count=0, avg_pain=10.0,
        critical_symptom_count=5, days_since_surgery=30,
    )
    assert prob <= 1.0


def test_probability_never_below_0():
    prob = predictor.predict(
        age=20, surgery_type="Tubal Ligation",
        checkin_count=14, avg_pain=0.0,
        critical_symptom_count=0, days_since_surgery=14,
    )
    assert prob >= 0.0
