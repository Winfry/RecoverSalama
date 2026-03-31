"""
Embedding Service — converts text to vectors for RAG.

Used by build_knowledge_base.py to process PDFs into embeddings,
and by rag_service.py to embed patient queries for similarity search.
"""

import google.generativeai as genai

from app.config import settings


class EmbeddingService:
    def __init__(self):
        genai.configure(api_key=settings.gemini_api_key)
        self._model = "models/text-embedding-004"

    def embed_text(self, text: str) -> list[float]:
        """Convert a text string to a vector embedding."""
        result = genai.embed_content(model=self._model, content=text)
        return result["embedding"]

    def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Convert multiple texts to embeddings in one call."""
        return [
            genai.embed_content(model=self._model, content=t)["embedding"]
            for t in texts
        ]
