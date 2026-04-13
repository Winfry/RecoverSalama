"""
Patient data schemas — defines the shape of patient data.

PatientCreate: what the Flutter app sends when profile setup is complete.
PatientResponse: what the API returns back.
"""

from pydantic import BaseModel
from datetime import date


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


class DischargeRequest(BaseModel):
    discharge_date: date
    assigned_doctor: str
    discharge_notes: str = ""


class PatientResponse(PatientCreate):
    id: str
    created_at: str | None = None
    hospital_id: str | None = None
    # Discharge fields — populated after hospital formally discharges the patient
    is_discharged: bool = False
    discharge_date: date | None = None
    assigned_doctor: str = ""
    discharge_notes: str = ""
