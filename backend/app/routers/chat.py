"""
AI Chat route — powers Flutter Screen 06 (AI Chat Assistant).

Flow:
1. Patient sends a message (English or Kiswahili)
2. RAG service retrieves relevant chunks from the Kenya Nutrition Manual
   and other clinical guidelines stored in Supabase pgvector
3. Retrieved chunks are injected into the Gemini prompt as context
4. Gemini generates a clinically grounded response
5. Response is returned to the Flutter app

This means the AI doesn't make up medical advice — it answers
based on official Kenya MOH documents.
"""

from fastapi import APIRouter

from app.schemas.chat import ChatRequest, ChatResponse
from app.services.ai.gemini_service import GeminiService
from app.services.ai.rag_service import RAGService

router = APIRouter()
gemini = GeminiService()
rag = RAGService()


@router.post("/", response_model=ChatResponse)
async def send_message(request: ChatRequest):
    """
    Process a patient chat message:
    1. Retrieve relevant clinical context via RAG
    2. Send to Gemini with context
    3. Return grounded response
    """
    # Step 1: Retrieve relevant knowledge base chunks
    context_chunks = await rag.retrieve(
        query=request.message,
        top_k=5,
    )

    # Step 2: Generate response with Gemini + context
    response = await gemini.generate_response(
        message=request.message,
        context=context_chunks,
        language=request.language,
        patient_context={
            "surgery_type": request.surgery_type,
            "days_since_surgery": request.days_since_surgery,
        },
    )

    return ChatResponse(
        reply=response,
        sources=[chunk.get("source", "") for chunk in context_chunks],
    )
