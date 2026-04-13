"""
Patient data schemas — defines the shape of patient data.

PatientCreate: what the Flutter app sends when profile setup is complete.
PatientResponse: what the API returns back.
"""

from pydantic import BaseModel, field_validator
from datetime import date
import re


class PatientCreate(BaseModel):
    name: str
    age: int
    gender: str
    surgery_type: str
    surgery_date: date | None = None
    hospital: str = ""
    surgeon: str = ""
    weight: float = 0
    blood_type: str = ""
    allergies: list[str] = []
    other_allergies: str = ""
    phone: str = ""
    caregiver_phone: str = ""
    notifications_enabled: bool = True

    @field_validator("age")
    @classmethod
    def age_must_be_valid(cls, v: int) -> int:
        if v < 0 or v > 120:
            raise ValueError("Age must be between 0 and 120")
        return v

    @field_validator("phone", "caregiver_phone", mode="before")
    @classmethod
    def normalise_phone(cls, v: str) -> str:
        """
        Normalise Kenyan phone numbers to +254XXXXXXXXX format.
        Accepts: 0712345678, 254712345678, +254712345678, 712345678
        Returns empty string unchanged (phone is optional).
        """
        if not v:
            return ""
        # Strip spaces and dashes
        digits = re.sub(r"[\s\-]", "", str(v))
        # Already in +254 format
        if digits.startswith("+254") and len(digits) == 13:
            return digits
        # 254XXXXXXXXX
        if digits.startswith("254") and len(digits) == 12:
            return f"+{digits}"
        # 0XXXXXXXXX (local format)
        if digits.startswith("0") and len(digits) == 10:
            return f"+254{digits[1:]}"
        # 7XXXXXXXX or 1XXXXXXXX (9 digits, no prefix)
        if len(digits) == 9 and digits[0] in ("7", "1"):
            return f"+254{digits}"
        # Return as-is if we can't normalise — don't reject, just pass through
        return v


class DischargeRequest(BaseModel):
    discharge_date: date
    assigned_doctor: str
    discharge_notes: str = ""


class PatientResponse(PatientCreate):
    id: str
    user_id: str | None = None
    created_at: str | None = None
    hospital_id: str | None = None
    is_active: bool = True
    # Discharge fields — populated after hospital formally discharges the patient
    is_discharged: bool = False
    discharge_date: date | None = None
    assigned_doctor: str = ""
    discharge_notes: str = ""
