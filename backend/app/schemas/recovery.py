"""
Recovery data schemas — check-ins, diet plans, risk levels.
"""

from pydantic import BaseModel


class CheckInRequest(BaseModel):
    patient_id: str
    pain_level: int  # 0-10
    symptoms: list[str]  # ["Fever above 38°C", "Wound bleeding", etc.]
    mood: str  # "Good", "Tired", "Anxious", "Low"
    days_since_surgery: int


class CheckInResponse(BaseModel):
    risk_level: str  # "LOW", "MEDIUM", "HIGH", "EMERGENCY"
    message: str


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
