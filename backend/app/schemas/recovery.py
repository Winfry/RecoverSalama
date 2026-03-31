"""
Recovery data schemas — check-ins, diet plans, risk levels, dashboard.
"""

from pydantic import BaseModel


class CheckInRequest(BaseModel):
    pain_level: int  # 0-10
    symptoms: list[str]  # ["Fever above 38°C", "Wound bleeding", etc.]
    mood: str  # "Good", "Tired", "Anxious", "Low"
    days_since_surgery: int


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
