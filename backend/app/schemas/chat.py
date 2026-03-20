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
    sources: list[str] = []  # Knowledge base sources cited
