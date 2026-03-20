"""
Gemini AI Service — the LLM brain behind the chat assistant.

How it works:
1. Patient asks a question in Flutter's AI Chat screen
2. RAG service retrieves relevant chunks from Kenya MOH documents
3. This service builds a prompt with those chunks as context
4. Sends to Google Gemini API
5. Returns a clinically grounded response

The system prompt ensures Gemini:
- Only answers based on provided clinical context
- Responds in the same language the patient used (EN or SW)
- Never diagnoses — always recommends seeing a doctor for serious concerns
- References the Kenya Nutrition Manual page numbers when relevant
"""

import google.generativeai as genai

from app.config import settings

# System prompt — defines how the AI behaves
SYSTEM_PROMPT = """You are SalamaRecover AI, a compassionate surgical recovery assistant
for Kenyan patients. You are NOT a doctor. You provide evidence-based recovery guidance.

RULES:
1. ONLY answer based on the clinical context provided below. If the context
   doesn't cover the question, say "I'm not sure — please ask your doctor."
2. Respond in the SAME LANGUAGE the patient uses (English or Kiswahili).
3. NEVER diagnose conditions. For serious symptoms, always recommend
   contacting a doctor or going to the hospital.
4. When recommending foods, use Kenya-local examples (ugali, sukuma wiki,
   uji, githeri, etc.) — not Western foods.
5. Reference the source document and page number when possible.
6. Be warm, encouraging, and culturally sensitive.
7. Keep responses concise — patients are recovering and may be tired.

PATIENT CONTEXT:
- Surgery type: {surgery_type}
- Days since surgery: {days_since_surgery}

CLINICAL CONTEXT (from Kenya MOH guidelines):
{rag_context}
"""


class GeminiService:
    def __init__(self):
        genai.configure(api_key=settings.gemini_api_key)
        self.model = genai.GenerativeModel("gemini-1.5-flash")

    async def generate_response(
        self,
        message: str,
        context: list[dict],
        language: str = "en",
        patient_context: dict | None = None,
    ) -> str:
        """Generate a clinically grounded response using Gemini + RAG context."""

        # Build context string from retrieved chunks
        rag_context = "\n\n".join(
            f"[Source: {chunk.get('source', 'Unknown')}, Page {chunk.get('page', '?')}]\n"
            f"{chunk.get('content', '')}"
            for chunk in context
        )

        # Build the full prompt
        system = SYSTEM_PROMPT.format(
            surgery_type=patient_context.get("surgery_type", "Unknown")
            if patient_context
            else "Unknown",
            days_since_surgery=patient_context.get("days_since_surgery", 0)
            if patient_context
            else 0,
            rag_context=rag_context or "No specific clinical context available.",
        )

        # Call Gemini
        response = self.model.generate_content(
            f"{system}\n\nPatient message: {message}"
        )

        return response.text
