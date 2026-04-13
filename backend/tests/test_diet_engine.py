"""
Tests for DietEngine — rule-based, no API calls needed.

Verifies that surgery-specific diet plans are returned correctly
and that allergy filtering works.
"""

import pytest
from app.services.ml.diet_engine import DietEngine

engine = DietEngine()


# ── Phase selection ──────────────────────────────────────────

def test_caesarean_day1_is_clear_liquid():
    plan = engine.get_plan("Caesarean Section", day=1)
    assert "Clear Liquid" in plan.phase
    assert plan.day == 1
    assert len(plan.foods) > 0


def test_caesarean_day5_is_soft_diet():
    plan = engine.get_plan("Caesarean Section", day=5)
    assert "Soft" in plan.phase or "Liquid" in plan.phase


def test_caesarean_day14_is_high_protein():
    plan = engine.get_plan("Caesarean Section", day=14)
    assert "Protein" in plan.phase or "High" in plan.phase


def test_appendectomy_returns_plan():
    plan = engine.get_plan("Appendectomy", day=3)
    assert plan is not None
    assert len(plan.foods) > 0


def test_unknown_surgery_defaults_gracefully():
    """Unknown surgery type should not crash — falls back to a default."""
    plan = engine.get_plan("Alien Removal Surgery", day=5)
    assert plan is not None
    assert plan.phase is not None


# ── Allergy filtering ────────────────────────────────────────

def test_egg_allergy_removes_egg_foods():
    plan = engine.get_plan("Caesarean Section", day=14, allergies=["Eggs"])
    food_names = [f.name for f in plan.foods]
    # No food name should contain "egg" (case-insensitive)
    for name in food_names:
        assert "egg" not in name.lower(), f"Egg food '{name}' not filtered out"


def test_dairy_allergy_removes_milk_foods():
    plan = engine.get_plan("Caesarean Section", day=5, allergies=["Milk/Dairy"])
    food_names = [f.name for f in plan.foods]
    dairy_keywords = ["milk", "maziwa", "mtindi", "yogurt", "cheese"]
    for name in food_names:
        for kw in dairy_keywords:
            assert kw not in name.lower(), f"Dairy food '{name}' not filtered out"


def test_no_allergies_returns_full_list():
    plan_no_allergy = engine.get_plan("Caesarean Section", day=14, allergies=[])
    plan_with_allergy = engine.get_plan("Caesarean Section", day=14, allergies=["Eggs"])
    # Allergy filtering should reduce or equal the food count, never increase it
    assert len(plan_with_allergy.foods) <= len(plan_no_allergy.foods)


# ── Source citation ──────────────────────────────────────────

def test_plan_has_moh_source():
    plan = engine.get_plan("Caesarean Section", day=7)
    assert "MOH" in plan.source or "Kenya" in plan.source or "Nutrition" in plan.source


# ── Calorie target ───────────────────────────────────────────

def test_high_protein_phase_has_higher_calories_than_clear_liquid():
    clear = engine.get_plan("Caesarean Section", day=1)
    protein = engine.get_plan("Caesarean Section", day=14)
    assert protein.target_kcal >= clear.target_kcal
