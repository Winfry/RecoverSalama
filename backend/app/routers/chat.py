"""
AI Chat route — powers Flutter Screen 06 (AI Chat Assistant).

Flow:
1. Patient sends a message (English or Kiswahili)
2. Load conversation history from Supabase
3. RAG service retrieves relevant chunks from the Kenya Nutrition Manual
   and other clinical guidelines stored in Supabase pgvector
4. Retrieved chunks are injected into the Gemini prompt as context
5. Gemini generates a clinically grounded response
6. Both user message and AI response are saved to chat_messages table
7. Response is returned to the Flutter app

This means the AI doesn't make up medical advice — it answers
based on official Kenya MOH documents.
"""

from fastapi import APIRouter, Depends

from app.auth import get_current_user, get_patient_id
from app.database import get_supabase_client
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.ai.gemini_service import GeminiService
from app.services.ai.rag_service import RAGService

router = APIRouter()
gemini = GeminiService()
rag = RAGService()


@router.post("/", response_model=ChatResponse)
async def send_message(
    request: ChatRequest,
    patient_id: str = Depends(get_patient_id),
):
    """
    Process a patient chat message:
    1. Load conversation history
    2. Retrieve relevant clinical context via RAG
    3. Send to Gemini with context + history
    4. Save both messages to database
    5. Return grounded response
    """
    db = get_supabase_client()

    # Step 1: Load patient context
    patient = db.table("patients").select("*").eq("id", patient_id).execute()
    patient_data = patient.data[0] if patient.data else {}

    # Step 2: Load recent conversation history (last 10 messages)
    history_result = (
        db.table("chat_messages")
        .select("role, content")
        .eq("patient_id", patient_id)
        .order("created_at", desc=True)
        .limit(10)
        .execute()
    )
    # Reverse so oldest first
    conversation_history = list(reversed(history_result.data)) if history_result.data else []

    # Step 3: Retrieve relevant knowledge base chunks via RAG
    context_chunks = await rag.retrieve(
        query=request.message,
        top_k=5,
    )

    # Step 4: Build patient context and call gemini.chat() directly
    # so the full CHAT_SYSTEM_PROMPT with RAG context, conversation history,
    # and patient details is used — not the bare backward-compat wrapper.
    from datetime import date as _date
    surgery_date = patient_data.get("surgery_date")
    try:
        days_since = (
            (_date.today() - _date.fromisoformat(str(surgery_date)[:10])).days
            if surgery_date else request.days_since_surgery
        )
    except (ValueError, TypeError):
        days_since = request.days_since_surgery

    patient_context = {
        "name": patient_data.get("name", ""),
        "surgery_type": patient_data.get("surgery_type") or request.surgery_type,
        "days_since_surgery": days_since,
        "allergies": patient_data.get("allergies", []),
        "pain_trend": "No data yet",
        "mood_pattern": "No data yet",
    }

    gemini_result = await gemini.chat(
        message=request.message,
        rag_context=context_chunks,
        patient_context=patient_context,
        conversation_history=conversation_history,
    )

    reply_text = gemini_result["reply"]
    sources = gemini_result.get("sources") or [
        chunk.get("source", "") for chunk in context_chunks if chunk.get("source")
    ]
    alert_hospital = gemini_result.get("alert_hospital", False)
    language = gemini_result.get("language", "en")

    # Step 5: Save both messages to database
    db.table("chat_messages").insert([
        {
            "patient_id": patient_id,
            "role": "user",
            "content": request.message,
        },
        {
            "patient_id": patient_id,
            "role": "assistant",
            "content": reply_text,
            "sources": sources,
        },
    ]).execute()

    return ChatResponse(
        reply=reply_text,
        sources=sources,
        alert_hospital=alert_hospital,
        language=language,
    )


@router.get("/history")
async def get_chat_history(
    patient_id: str = Depends(get_patient_id),
    limit: int = 50,
):
    """Load conversation history for the Flutter chat screen."""
    db = get_supabase_client()
    result = (
        db.table("chat_messages")
        .select("*")
        .eq("patient_id", patient_id)
        .order("created_at", desc=False)
        .limit(limit)
        .execute()
    )
    return result.data
