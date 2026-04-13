"""
Chat schemas — AI chat request and response shapes.
"""

from pydantic import BaseModel


class ChatRequest(BaseModel):
    message: str
    language: str = "en"  # "en" or "sw" (Kiswahili)
    surgery_type: str = ""
    days_since_surgery: int = 0


class ChatResponse(BaseModel):
    reply: str
    sources: list[str] = []
    # alert_hospital: True when Gemini's clinical assessment says the patient
    # should contact their hospital. Flutter uses this to show the red CTA banner.
    alert_hospital: bool = False
    language: str = "en"
