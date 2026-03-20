"""
Embedding Service — converts text to vectors for RAG.

Used by build_knowledge_base.py to process PDFs into embeddings,
and by rag_service.py to embed patient queries for similarity search.
"""

from langchain_google_genai import GoogleGenerativeAIEmbeddings

from app.config import settings


class EmbeddingService:
    def __init__(self):
        self.model = GoogleGenerativeAIEmbeddings(
            model="models/text-embedding-004",
            google_api_key=settings.gemini_api_key,
        )

    def embed_text(self, text: str) -> list[float]:
        """Convert a text string to a vector embedding."""
        return self.model.embed_query(text)

    def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Convert multiple texts to embeddings in one call."""
        return self.model.embed_documents(texts)
