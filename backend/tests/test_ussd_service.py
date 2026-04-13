"""
Tests for USSDService — rule-based risk scoring and menu flow.

No database, no network, no API keys needed.
Tests the pure logic: menu navigation and risk calculation.
"""

from app.services.channels.ussd_service import USSDService

ussd = USSDService()


# ── Main menu ────────────────────────────────────────────────

def test_empty_input_shows_main_menu():
    response = ussd.handle_session("s1", "+254712345678", "")
    assert response.startswith("CON")
    assert "Check-In" in response or "check" in response.lower()


def test_option_3_shows_emergency_numbers():
    response = ussd.handle_session("s1", "+254712345678", "3")
    assert response.startswith("END")
    assert "999" in response


def test_option_4_shows_help():
    response = ussd.handle_session("s1", "+254712345678", "4")
    assert response.startswith("END")
    assert "SalamaRecover" in response


def test_invalid_option_returns_error():
    response = ussd.handle_session("s1", "+254712345678", "9")
    assert response.startswith("END")


# ── Check-in flow ────────────────────────────────────────────

def test_checkin_step0_asks_pain():
    response = ussd.handle_session("s1", "+254712345678", "1")
    assert response.startswith("CON")
    assert "Maumivu" in response


def test_checkin_step1_asks_symptom():
    response = ussd.handle_session("s1", "+254712345678", "1*3")
    assert response.startswith("CON")
    assert "Dalili" in response


def test_checkin_step2_returns_end():
    response = ussd.handle_session("s1", "+254712345678", "1*3*5")
    assert response.startswith("END")


# ── Risk calculation ─────────────────────────────────────────

def test_fever_is_emergency():
    risk = ussd._calculate_risk(pain_score=3, symptom="fever")
    assert risk == "EMERGENCY"


def test_bleeding_is_emergency():
    risk = ussd._calculate_risk(pain_score=2, symptom="bleeding")
    assert risk == "EMERGENCY"


def test_extreme_pain_is_emergency():
    risk = ussd._calculate_risk(pain_score=10, symptom="none")
    assert risk == "EMERGENCY"


def test_high_pain_is_high():
    risk = ussd._calculate_risk(pain_score=7, symptom="none")
    assert risk == "HIGH"


def test_swelling_is_high():
    risk = ussd._calculate_risk(pain_score=3, symptom="swelling")
    assert risk == "HIGH"


def test_moderate_pain_is_medium():
    risk = ussd._calculate_risk(pain_score=5, symptom="none")
    assert risk == "MEDIUM"


def test_low_pain_no_symptoms_is_low():
    risk = ussd._calculate_risk(pain_score=2, symptom="none")
    assert risk == "LOW"


def test_zero_pain_no_symptoms_is_low():
    risk = ussd._calculate_risk(pain_score=0, symptom="none")
    assert risk == "LOW"


# ── Diet flow ────────────────────────────────────────────────

def test_diet_step0_asks_days():
    response = ussd.handle_session("s1", "+254712345678", "2")
    assert response.startswith("CON")
    assert "Siku" in response


def test_diet_day1_returns_clear_liquids():
    response = ussd.handle_session("s1", "+254712345678", "2*1")
    assert response.startswith("END")
    assert "Maji" in response or "supu" in response.lower()


def test_diet_day8_returns_high_protein():
    response = ussd.handle_session("s1", "+254712345678", "2*4")
    assert response.startswith("END")
    assert "Protini" in response or "maharagwe" in response.lower()
