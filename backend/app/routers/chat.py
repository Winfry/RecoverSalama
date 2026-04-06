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

    # Step 4: Generate response with Gemini + context + history
    patient_context = {
        "surgery_type": patient_data.get("surgery_type", request.surgery_type),
        "days_since_surgery": request.days_since_surgery,
        "name": patient_data.get("name", ""),
        "allergies": patient_data.get("allergies", []),
    }

    response = await gemini.generate_response(
        message=request.message,
        context=context_chunks,
        language=request.language,
        patient_context=patient_context,
    )

    sources = [chunk.get("source", "") for chunk in context_chunks]

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
            "content": response,
            "sources": sources,
        },
    ]).execute()

    return ChatResponse(
        reply=response,
        sources=sources,
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
