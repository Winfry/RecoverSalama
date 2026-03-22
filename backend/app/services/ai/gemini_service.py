"""
Gemini AI Service — The Central Intelligence of SalamaRecover.

This is the brain. Every AI-powered feature in SalamaRecover flows
through this service. It powers:

1. PATIENT CHAT — Conversational Q&A in English or Kiswahili
2. RISK ASSESSMENT — Clinical judgement on check-in data (used by risk_scorer.py)
3. DIET ADVICE — Personalised food recommendations grounded in MOH guidelines
4. MOOD SUPPORT — Empathetic responses to mental health check-ins
5. CAREGIVER SUMMARIES — Daily recovery updates for family members

ARCHITECTURE:
━━━━━━━━━━━━

┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│ Patient asks │────▶│ RAG retrieves│────▶│ Gemini builds│
│ a question   │     │ relevant     │     │ grounded     │
│ (EN or SW)   │     │ clinical     │     │ response     │
│              │     │ chunks from  │     │ using the    │
│              │     │ Kenya MOH    │     │ chunks as    │
│              │     │ documents    │     │ evidence     │
└─────────────┘     └──────────────┘     └──────┬───────┘
                                                │
                    ┌──────────────┐             │
                    │ Response     │◀────────────┘
                    │ includes:    │
                    │ - Answer     │
                    │ - Sources    │
                    │ - Citations  │
                    │ - Actions    │
                    └──────────────┘

KEY DESIGN DECISIONS:
━━━━━━━━━━━━━━━━━━━━

1. CONVERSATION MEMORY — Recent chat history is included in prompts so
   the AI remembers what the patient said yesterday. "The swelling is
   bigger now" is meaningless without knowing they mentioned swelling
   3 days ago. History is stored in Supabase, loaded per-patient.

2. PERSONALISATION — The prompt includes the patient's full context:
   surgery type, recovery day, allergies, pain trends, mood patterns.
   "Eat eggs for protein" is wrong if the patient is allergic to eggs.

3. KISWAHILI-NATIVE — The system prompt instructs Gemini to use natural
   conversational Kiswahili, not stiff textbook translations. Food names
   are Kiswahili first (sukuma wiki, not kale). Sheng is acceptable for
   younger Nairobi patients.

4. MULTI-STEP REASONING — For complex questions, the AI reasons in steps:
   extract symptoms → retrieve guidelines → assess risk → check diet
   implications → generate response. Each step can be verified.

5. STRUCTURED OUTPUT — For programmatic responses (risk scoring, diet
   plans), Gemini returns forced JSON. For chat, it returns natural text.
   The caller chooses which mode to use.

6. GRACEFUL FALLBACK — If Gemini is down or returns garbage, every
   method returns a safe fallback response instead of crashing.
"""

import json
import logging
from enum import Enum

import google.generativeai as genai

from app.config import settings

logger = logging.getLogger(__name__)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RESPONSE MODES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ResponseMode(Enum):
    """Controls how Gemini formats its response."""
    CHAT = "chat"              # Natural text — for patient conversations
    STRUCTURED = "structured"  # Forced JSON — for risk scoring, diet plans


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SYSTEM PROMPTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CHAT_SYSTEM_PROMPT = """You are SalamaRecover AI, a compassionate and knowledgeable
surgical recovery assistant built for Kenyan patients. You are NOT a doctor and you
NEVER diagnose. You provide evidence-based recovery guidance grounded in official
clinical documents.

YOUR PERSONALITY:
- Warm, encouraging, and patient — like a caring nurse who has time for you
- Culturally aware — you understand Kenyan life, food, and family dynamics
- Honest — you say "I'm not sure, please ask your doctor" when you don't know
- Concise — patients are recovering and may be tired, keep responses short

LANGUAGE RULES:
- ALWAYS respond in the SAME LANGUAGE the patient uses
- If they write in English, respond in English
- If they write in Kiswahili, respond in natural conversational Kiswahili
- Do NOT use stiff textbook Kiswahili — use the way real Kenyans speak
- Food names should be in Kiswahili first: "sukuma wiki" not "kale",
  "uji" not "porridge", "maharagwe" not "beans", "ugali" not "corn meal"
- For younger patients in Nairobi, light sheng is acceptable
- You can mix languages naturally the way Kenyans do

CLINICAL RULES:
1. ONLY answer medical questions based on the clinical context provided below.
   If the context doesn't cover it, say you're not sure and recommend asking
   their doctor.
2. NEVER diagnose. Never say "you have an infection" — say "these symptoms
   could indicate something that needs a doctor's attention."
3. For serious symptoms (high fever, bleeding, chest pain, difficulty breathing),
   ALWAYS recommend contacting the hospital immediately. Do not reassure.
4. When recommending foods, use Kenya-local examples and reference the source
   document and page number when possible.
5. When a patient seems distressed, be empathetic first, clinical second.
   "Pole sana, ninajua ni ngumu" before any medical guidance.

THIS PATIENT:
- Name: {patient_name}
- Surgery: {surgery_type}
- Days since surgery: {days_since_surgery} (Day {days_since_surgery} of recovery)
- Recovery stage: {recovery_stage}
- Known allergies: {allergies}
- Recent pain trend: {pain_trend}
- Current mood pattern: {mood_pattern}

RECENT CONVERSATION HISTORY:
{conversation_history}

CLINICAL CONTEXT (retrieved from Kenya MOH guidelines via RAG):
{rag_context}
"""

AGENTIC_SYSTEM_PROMPT = """You are a clinical reasoning agent for SalamaRecover,
a post-surgical recovery platform in Kenya.

You must reason through the patient's situation step by step before responding.
This ensures you don't miss anything important.

REASONING STEPS (follow these in order):

STEP 1 — UNDERSTAND: What is the patient asking or reporting?
Extract the core question or concern. Identify any symptoms mentioned.

STEP 2 — CONTEXT: What do we know about this patient?
Consider their surgery type, recovery day, allergies, and history.
Is this expected for their stage of recovery, or unusual?

STEP 3 — RETRIEVE: What do the clinical guidelines say?
Use the provided clinical context (RAG chunks) to find relevant guidance.
Cite specific sources and page numbers.

STEP 4 — ASSESS: Is there any risk?
Based on the symptoms and clinical context, should we be concerned?
Consider: Is this normal for their recovery day? Are there red flags?

STEP 5 — DIET CHECK: Does this affect their diet?
If the question involves food, symptoms that affect eating, or nutrition,
check against the Kenya Nutrition Manual recommendations for their
surgery type and recovery day.

STEP 6 — RESPOND: Generate the final response.
Write the response in the patient's language (English or Kiswahili).
Be warm, be clear, be concise. Include source citations.

STEP 7 — FLAG: Should we trigger any system action?
Set alert_hospital=true if symptoms are concerning.
Set diet_change=true if diet recommendations need updating.

THIS PATIENT:
- Name: {patient_name}
- Surgery: {surgery_type}
- Days since surgery: {days_since_surgery}
- Known allergies: {allergies}
- Recent pain level: {recent_pain}
- Current mood: {current_mood}

CLINICAL CONTEXT (from Kenya MOH guidelines):
{rag_context}

CONVERSATION HISTORY:
{conversation_history}

PATIENT'S MESSAGE:
{message}

Now reason through steps 1-7, then provide your final response.

You MUST respond with ONLY valid JSON in this exact format:
{{
    "reasoning_steps": {{
        "understand": "What the patient is asking",
        "context": "What we know about them",
        "retrieve": "What the guidelines say",
        "assess": "Risk assessment",
        "diet_check": "Diet implications",
        "respond": "The response to give the patient",
        "flag": "Any system actions needed"
    }},
    "response": "The actual message to send to the patient (in their language)",
    "sources": ["Source 1, page X", "Source 2, page Y"],
    "alert_hospital": false,
    "diet_change": false,
    "detected_language": "en or sw"
}}
"""

MOOD_SUPPORT_PROMPT = """You are SalamaRecover AI providing emotional support to a
post-surgical patient in Kenya.

THE PATIENT:
- Name: {patient_name}
- Surgery: {surgery_type}, Day {days_since_surgery} of recovery
- Selected mood: {mood}
- Recent mood history: {mood_history}

EMOTIONAL SUPPORT GUIDELINES:
- If mood is "Okay"/"Good": Celebrate genuinely. "Umefanya vizuri!" Encourage them.
- If mood is "Tired": Normalize it. Recovery IS tiring. Suggest rest, hydration,
  a short walk. Don't minimize their fatigue.
- If mood is "Anxious": Validate first. "Wasiwasi ni kawaida baada ya upasuaji."
  Then offer breathing exercise: inhale 4 seconds, hold 4, exhale 6.
- If mood is "Overwhelmed"/"Low": Take this seriously. Express genuine care.
  Suggest talking to someone they trust. Mention Befrienders Kenya: 0722 178 177.
  Do NOT say "just think positive."
- If mood has been negative for 3+ consecutive check-ins: Gently note the pattern.
  "Nimegundua umekuwa na hali ngumu siku kadhaa..." Recommend professional support.

LANGUAGE: Respond in {language}. If Kiswahili, use natural conversational Kiswahili.

Respond with a warm, concise message (2-4 sentences). Be human, not clinical.
"""

CAREGIVER_SUMMARY_PROMPT = """Generate a brief daily recovery summary for a family
caregiver. This will be sent via WhatsApp.

PATIENT: {patient_name}
SURGERY: {surgery_type}
DAY: {days_since_surgery} of recovery
TODAY'S CHECK-IN:
- Pain: {pain_level}/10
- Symptoms: {symptoms}
- Mood: {mood}
- Risk level: {risk_level}
DIET PHASE: {diet_phase}

Write a warm, concise WhatsApp message (3-5 lines) in {language} that tells
the caregiver:
1. How the patient is doing today (honest but not alarming)
2. What food to prepare (Kenya-local)
3. One thing to watch for
4. An encouraging word

Keep it simple — the caregiver may not be medically trained.
"""


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GEMINI SERVICE CLASS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class GeminiService:
    """
    Central AI service — all intelligence flows through here.

    Usage:
        gemini = GeminiService()

        # Patient chat (natural text response)
        reply = await gemini.chat(message="What should I eat today?", ...)

        # Agentic reasoning (structured JSON, multi-step)
        result = await gemini.reason(message="My wound feels warm", ...)

        # Mood support
        reply = await gemini.support_mood(mood="Anxious", ...)

        # Caregiver summary
        summary = await gemini.generate_caregiver_summary(...)
    """

    def __init__(self):
        """Initialize two Gemini models — one for chat, one for structured output."""
        try:
            genai.configure(api_key=settings.gemini_api_key)

            # Chat model — natural text responses, slightly creative
            self.chat_model = genai.GenerativeModel(
                model_name="gemini-2.0-flash",
                generation_config={
                    "temperature": 0.4,       # Warm but not wild
                    "top_p": 0.9,
                    "max_output_tokens": 1024,
                },
            )

            # Structured model — forced JSON, very consistent
            self.structured_model = genai.GenerativeModel(
                model_name="gemini-2.0-flash",
                generation_config={
                    "temperature": 0.1,       # Almost deterministic
                    "top_p": 0.8,
                    "max_output_tokens": 2048,
                    "response_mime_type": "application/json",
                },
            )

            self.available = True
            logger.info("Gemini service initialized successfully")

        except Exception as e:
            logger.error(f"Gemini initialization failed: {e}")
            self.available = False

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 1. PATIENT CHAT — Natural conversation
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def chat(
        self,
        message: str,
        rag_context: list[dict],
        patient_context: dict,
        conversation_history: list[dict] | None = None,
    ) -> dict:
        """
        Patient chat — the AI Chat screen (Flutter Screen 06).

        This is the most-used method. A patient types a question,
        RAG retrieves relevant clinical chunks, and this method
        generates a grounded, personalised response in their language.

        Args:
            message: What the patient typed
            rag_context: Clinical chunks from RAG (Kenya MOH docs)
            patient_context: {name, surgery_type, days_since_surgery,
                             allergies, pain_trend, mood_pattern, ...}
            conversation_history: Recent messages [{role, content}, ...]

        Returns:
            {reply, sources, language, alert_hospital}
        """
        if not self.available:
            return self._fallback_chat_response(message)

        # Format RAG chunks for the prompt
        rag_text = self._format_rag_context(rag_context)

        # Format conversation history (last 10 messages)
        history_text = self._format_conversation_history(conversation_history)

        # Build the system prompt with patient context
        system_prompt = CHAT_SYSTEM_PROMPT.format(
            patient_name=patient_context.get("name", "there"),
            surgery_type=patient_context.get("surgery_type", "Unknown"),
            days_since_surgery=patient_context.get("days_since_surgery", 0),
            recovery_stage=self._get_recovery_stage(
                patient_context.get("days_since_surgery", 0)
            ),
            allergies=", ".join(patient_context.get("allergies", [])) or "None known",
            pain_trend=patient_context.get("pain_trend", "No data yet"),
            mood_pattern=patient_context.get("mood_pattern", "No data yet"),
            conversation_history=history_text,
            rag_context=rag_text,
        )

        try:
            response = self.chat_model.generate_content(
                f"{system_prompt}\n\nPatient says: {message}"
            )

            reply_text = response.text

            # Extract sources from RAG context
            sources = list({
                chunk.get("source", "")
                for chunk in rag_context
                if chunk.get("source")
            })

            # Simple check: does the response suggest hospital contact?
            alert_keywords = [
                "hospital", "doctor", "daktari", "hospitali",
                "emergency", "dharura", "999", "112", "immediately",
                "haraka", "contact", "wasiliana",
            ]
            alert_hospital = any(
                keyword in reply_text.lower() for keyword in alert_keywords
            )

            return {
                "reply": reply_text,
                "sources": sources,
                "language": self._detect_response_language(reply_text),
                "alert_hospital": alert_hospital,
            }

        except Exception as e:
            logger.error(f"Gemini chat failed: {e}")
            return self._fallback_chat_response(message)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 2. AGENTIC REASONING — Multi-step clinical thinking
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def reason(
        self,
        message: str,
        rag_context: list[dict],
        patient_context: dict,
        conversation_history: list[dict] | None = None,
    ) -> dict:
        """
        Agentic multi-step reasoning — for complex patient situations.

        Instead of one prompt → one answer, the AI reasons in 7 steps:
        1. UNDERSTAND — What is the patient asking/reporting?
        2. CONTEXT — What do we know about this patient?
        3. RETRIEVE — What do the clinical guidelines say?
        4. ASSESS — Is there any risk here?
        5. DIET CHECK — Does this affect their diet?
        6. RESPOND — Generate the response in their language
        7. FLAG — Should we trigger any system action?

        Use this instead of chat() when:
        - The patient reports symptoms (not just asking questions)
        - The message mentions pain, bleeding, fever, or wound issues
        - You need the AI's reasoning to be auditable (each step is logged)

        Returns:
            {response, reasoning_steps, sources, alert_hospital,
             diet_change, detected_language}
        """
        if not self.available:
            return self._fallback_reasoning_response(message)

        rag_text = self._format_rag_context(rag_context)
        history_text = self._format_conversation_history(conversation_history)

        prompt = AGENTIC_SYSTEM_PROMPT.format(
            patient_name=patient_context.get("name", "Patient"),
            surgery_type=patient_context.get("surgery_type", "Unknown"),
            days_since_surgery=patient_context.get("days_since_surgery", 0),
            allergies=", ".join(patient_context.get("allergies", [])) or "None known",
            recent_pain=patient_context.get("recent_pain", "Unknown"),
            current_mood=patient_context.get("current_mood", "Unknown"),
            rag_context=rag_text,
            conversation_history=history_text,
            message=message,
        )

        try:
            response = self.structured_model.generate_content(prompt)
            result = json.loads(response.text)

            return {
                "response": result.get("response", "I'm not sure. Please ask your doctor."),
                "reasoning_steps": result.get("reasoning_steps", {}),
                "sources": result.get("sources", []),
                "alert_hospital": result.get("alert_hospital", False),
                "diet_change": result.get("diet_change", False),
                "detected_language": result.get("detected_language", "en"),
            }

        except json.JSONDecodeError as e:
            logger.warning(f"Gemini reasoning returned invalid JSON: {e}")
            # Fall back to regular chat
            return await self._reasoning_fallback_to_chat(
                message, rag_context, patient_context, conversation_history
            )
        except Exception as e:
            logger.error(f"Gemini reasoning failed: {e}")
            return self._fallback_reasoning_response(message)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 3. MOOD SUPPORT — Empathetic mental health responses
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def support_mood(
        self,
        mood: str,
        patient_context: dict,
        mood_history: list[str] | None = None,
        language: str = "en",
    ) -> str:
        """
        Mental health support — Flutter Screen 07.

        Generates an empathetic, culturally appropriate response
        based on the patient's selected mood. Considers mood history
        to detect persistent negative patterns.

        Args:
            mood: Current mood ("Okay", "Tired", "Anxious", "Overwhelmed")
            patient_context: {name, surgery_type, days_since_surgery}
            mood_history: List of recent moods ["Good", "Tired", "Tired", "Anxious"]
            language: "en" or "sw"

        Returns:
            A warm, concise support message (string)
        """
        if not self.available:
            return self._fallback_mood_response(mood, language)

        history_text = ", ".join(mood_history[-7:]) if mood_history else "No previous data"

        prompt = MOOD_SUPPORT_PROMPT.format(
            patient_name=patient_context.get("name", "there"),
            surgery_type=patient_context.get("surgery_type", "surgery"),
            days_since_surgery=patient_context.get("days_since_surgery", 0),
            mood=mood,
            mood_history=history_text,
            language="Kiswahili" if language == "sw" else "English",
        )

        try:
            response = self.chat_model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Gemini mood support failed: {e}")
            return self._fallback_mood_response(mood, language)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 4. CAREGIVER SUMMARY — Daily WhatsApp update for family
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def generate_caregiver_summary(
        self,
        patient_context: dict,
        checkin_data: dict,
        language: str = "en",
    ) -> str:
        """
        Generates a daily recovery summary for the patient's caregiver.
        Sent via WhatsApp. Written to be understood by non-medical people.

        Args:
            patient_context: {name, surgery_type, days_since_surgery}
            checkin_data: {pain_level, symptoms, mood, risk_level, diet_phase}
            language: "en" or "sw"

        Returns:
            A WhatsApp-friendly summary message (string)
        """
        if not self.available:
            return self._fallback_caregiver_summary(patient_context, checkin_data, language)

        prompt = CAREGIVER_SUMMARY_PROMPT.format(
            patient_name=patient_context.get("name", "your loved one"),
            surgery_type=patient_context.get("surgery_type", "surgery"),
            days_since_surgery=patient_context.get("days_since_surgery", 0),
            pain_level=checkin_data.get("pain_level", "?"),
            symptoms=", ".join(checkin_data.get("symptoms", [])) or "None",
            mood=checkin_data.get("mood", "Unknown"),
            risk_level=checkin_data.get("risk_level", "LOW"),
            diet_phase=checkin_data.get("diet_phase", "Normal diet"),
            language="Kiswahili" if language == "sw" else "English",
        )

        try:
            response = self.chat_model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Gemini caregiver summary failed: {e}")
            return self._fallback_caregiver_summary(patient_context, checkin_data, language)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 5. BACKWARD-COMPATIBLE METHOD — For existing code
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    async def generate_response(
        self,
        message: str,
        context: list[dict],
        language: str = "en",
        patient_context: dict | None = None,
    ) -> str:
        """
        Backward-compatible method — wraps chat() for existing code.
        Returns just the reply text string.
        """
        result = await self.chat(
            message=message,
            rag_context=context,
            patient_context=patient_context or {},
            conversation_history=None,
        )
        return result["reply"]

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # HELPER METHODS
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _format_rag_context(self, rag_chunks: list[dict]) -> str:
        """Format RAG chunks into a readable string for the prompt."""
        if not rag_chunks:
            return "No specific clinical context available for this question."

        formatted = []
        for chunk in rag_chunks:
            source = chunk.get("source", "Unknown source")
            page = chunk.get("page", "?")
            content = chunk.get("content", "")
            authority = chunk.get("metadata", {}).get("authority", "")

            header = f"[{source}, Page {page}"
            if authority:
                header += f" — {authority}"
            header += "]"

            formatted.append(f"{header}\n{content}")

        return "\n\n".join(formatted)

    def _format_conversation_history(
        self, history: list[dict] | None
    ) -> str:
        """Format recent conversation history for the prompt."""
        if not history:
            return "No previous conversation — this is the first message."

        # Only include the last 10 messages to stay within token limits
        recent = history[-10:]
        lines = []
        for msg in recent:
            role = msg.get("role", "unknown")
            content = msg.get("content", "")
            if role == "user":
                lines.append(f"Patient: {content}")
            elif role == "assistant":
                lines.append(f"AI: {content}")

        return "\n".join(lines)

    def _get_recovery_stage(self, days_since_surgery: int) -> str:
        """Determine recovery stage from days since surgery."""
        if days_since_surgery <= 2:
            return "Stage 1 — Immediate Post-Op (rest, clear liquids, pain management)"
        elif days_since_surgery <= 7:
            return "Stage 2 — Early Healing (tissue rebuilding, soft diet, light movement)"
        elif days_since_surgery <= 14:
            return "Stage 3 — Active Recovery (increasing activity, normal diet returning)"
        elif days_since_surgery <= 30:
            return "Stage 4 — Strengthening (near-normal activity, full diet)"
        else:
            return "Stage 5 — Long-term Recovery (full activity, monitoring for late complications)"

    def _detect_response_language(self, text: str) -> str:
        """Quick check if the response is in Kiswahili or English."""
        sw_markers = {
            "habari", "asante", "daktari", "hospitali", "maumivu",
            "kupona", "chakula", "vizuri", "sawa", "pole",
            "ndio", "hapana", "leo", "kesho", "kula",
        }
        words = set(text.lower().split())
        sw_count = len(words & sw_markers)
        return "sw" if len(words) > 0 and sw_count / len(words) >= 0.15 else "en"

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # FALLBACK RESPONSES — Used when Gemini is unavailable
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    def _fallback_chat_response(self, message: str) -> dict:
        """Safe response when Gemini is down."""
        return {
            "reply": (
                "I'm having trouble connecting right now. "
                "For urgent concerns, please contact your hospital directly. "
                "For diet questions, follow your recovery stage guidelines. "
                "I'll be back online soon!"
            ),
            "sources": [],
            "language": "en",
            "alert_hospital": False,
        }

    def _fallback_reasoning_response(self, message: str) -> dict:
        """Safe reasoning response when Gemini is down."""
        return {
            "response": (
                "I can't process this right now. If you're experiencing "
                "serious symptoms (high fever, bleeding, chest pain, difficulty "
                "breathing), please contact your hospital immediately or call 999."
            ),
            "reasoning_steps": {},
            "sources": [],
            "alert_hospital": False,
            "diet_change": False,
            "detected_language": "en",
        }

    async def _reasoning_fallback_to_chat(
        self, message, rag_context, patient_context, conversation_history
    ) -> dict:
        """If structured reasoning fails, fall back to regular chat."""
        chat_result = await self.chat(
            message=message,
            rag_context=rag_context,
            patient_context=patient_context,
            conversation_history=conversation_history,
        )
        return {
            "response": chat_result["reply"],
            "reasoning_steps": {"note": "Fell back to chat mode"},
            "sources": chat_result["sources"],
            "alert_hospital": chat_result["alert_hospital"],
            "diet_change": False,
            "detected_language": chat_result["language"],
        }

    def _fallback_mood_response(self, mood: str, language: str) -> str:
        """Safe mood response when Gemini is down."""
        responses = {
            "en": {
                "Okay": "That's great to hear! Keep up the positive energy — it truly helps healing.",
                "Tired": "Rest is your body's way of healing. Take it easy today. You're doing well.",
                "Anxious": "It's completely normal to feel anxious after surgery. Take slow, deep breaths. You are safe.",
                "Overwhelmed": "You don't have to go through this alone. Please talk to someone you trust, or call Befrienders Kenya: 0722 178 177.",
            },
            "sw": {
                "Okay": "Vizuri sana! Endelea na moyo huo — inasaidia kupona kwako.",
                "Tired": "Kupumzika ni sehemu ya kupona. Pumzika leo. Unafanya vizuri.",
                "Anxious": "Wasiwasi ni kawaida baada ya upasuaji. Vuta pumzi pole pole. Uko salama.",
                "Overwhelmed": "Si lazima upitie hii peke yako. Zungumza na mtu unayemwamini, au piga Befrienders Kenya: 0722 178 177.",
            },
        }
        lang_responses = responses.get(language, responses["en"])
        return lang_responses.get(mood, lang_responses.get("Okay", "Thank you for checking in."))

    def _fallback_caregiver_summary(
        self, patient_context: dict, checkin_data: dict, language: str
    ) -> str:
        """Safe caregiver summary when Gemini is down."""
        name = patient_context.get("name", "Your loved one")
        day = patient_context.get("days_since_surgery", "?")
        pain = checkin_data.get("pain_level", "?")
        mood = checkin_data.get("mood", "?")
        risk = checkin_data.get("risk_level", "LOW")

        if language == "sw":
            return (
                f"SalamaRecover — Siku {day}\n"
                f"{name}: Maumivu {pain}/10, Hali: {mood}\n"
                f"Hatari: {risk}\n"
                f"Endelea kumtunza vizuri. Pona Salama! 💚"
            )
        return (
            f"SalamaRecover — Day {day} Update\n"
            f"{name}: Pain {pain}/10, Mood: {mood}\n"
            f"Risk: {risk}\n"
            f"Keep supporting them. Recover Safely! 💚"
        )
