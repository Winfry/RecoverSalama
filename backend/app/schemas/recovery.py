"""
Recovery data schemas — check-ins, diet plans, risk levels, dashboard.
"""

from typing import Annotated

from pydantic import BaseModel, Field


class CheckInRequest(BaseModel):
    pain_level: Annotated[int, Field(ge=0, le=10)]
    symptoms: list[str]  # ["Fever above 38°C", "Wound bleeding", etc.]
    mood: str  # "Good", "Tired", "Anxious", "Low"
    days_since_surgery: Annotated[int, Field(ge=0)]


class CheckInResponse(BaseModel):
    risk_level: str  # "LOW", "MEDIUM", "HIGH", "EMERGENCY"
    message: str
    reasoning: str = ""  # AI clinical reasoning (from Gemini layer 2)
    recommendation: str = ""  # Actionable next step for the patient


class FoodItem(BaseModel):
    icon: str
    name: str
    benefit: str
    calories: int = 0
    source: str = ""  # e.g., "Kenya Nutrition Manual p.69"


class DietResponse(BaseModel):
    day: int
    phase: str  # "clear_liquid", "full_liquid", "soft_diet", "high_protein"
    target_kcal: int
    foods: list[FoodItem]
    avoid: list[str]
    source: str  # "Kenya National Clinical Nutrition Manual (MOH 2010)"
    key_nutrients: str = ""  # Priority nutrients for this surgery type e.g. "Iron, Calcium, Vitamin D"


class DashboardResponse(BaseModel):
    patient_name: str
    surgery_type: str
    surgery_date: str
    days_since_surgery: int
    recovery_day: int
    total_recovery_days: int
    stage_name: str
    stage_description: str
    allowed_activities: list[str]
    restricted_activities: list[str]
    risk_level: str
    ai_tip: str
    latest_pain: int = 0
    latest_mood: str = ""


class MoodRequest(BaseModel):
    mood: str
    notes: str | None = None


class MoodResponse(BaseModel):
    status: str
    support_message: str
    mental_health_level: str  # "stable" | "monitor" | "needs_support"


# ── Structured Meal Plan ───────────────────────────────────────

class MealItemDetail(BaseModel):
    name: str
    calories: int = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0


class MealDetail(BaseModel):
    name: str
    score: int = 0
    description: str = ""
    items: list[MealItemDetail] = []
    total_calories: int = 0
    total_protein_g: float = 0
    total_carbs_g: float = 0
    total_fat_g: float = 0


class MealPlanResponse(BaseModel):
    phase: str = ""
    phase_label: str = ""
    target_kcal: int = 0
    target_protein_g: float = 0
    target_carbs_g: float = 0
    target_fat_g: float = 0
    ai_tip: str = ""
    meals: dict[str, MealDetail] = {}
    avoid: list[str] = []           # Foods to avoid — from Kenya MOH diet rules


class MealAlternativesRequest(BaseModel):
    meal_name: str
    meal_type: str  # "breakfast" | "lunch" | "dinner" | "snack"
    preference_text: str = ""
    surgery_type: str
    day: int
    phase: str
    allergies: list[str] = []


class MealAlternative(BaseModel):
    name: str
    rating: int = 0
    description: str = ""
    total_calories: int = 0
    total_protein_g: float = 0
    total_carbs_g: float = 0
    total_fat_g: float = 0


class MealAlternativesResponse(BaseModel):
    alternatives: list[MealAlternative] = []
