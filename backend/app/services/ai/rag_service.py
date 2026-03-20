"""
RAG (Retrieval Augmented Generation) Service.

This is what makes the AI clinically trustworthy instead of generic.

How it works:
1. The Kenya Nutrition Manual (270 pages) and other clinical PDFs are
   chunked into ~500-token pieces by build_knowledge_base.py
2. Each chunk is embedded using Google's text-embedding-004 model
3. Embeddings are stored in Supabase pgvector
4. When a patient asks a question, this service:
   a. Embeds the question using the same model
   b. Finds the 5 most similar chunks via cosine similarity
   c. Returns those chunks as context for Gemini

Result: When a patient asks "What should I eat on Day 5 after C-section?",
the RAG retrieves the exact pages from the Kenya Nutrition Manual about
soft diet progression, and Gemini answers using THAT information.
"""

from langchain_google_genai import GoogleGenerativeAIEmbeddings

from app.config import settings
from app.database import get_supabase_client


class RAGService:
    def __init__(self):
        self.embeddings = GoogleGenerativeAIEmbeddings(
            model="models/text-embedding-004",
            google_api_key=settings.gemini_api_key,
        )

    async def retrieve(self, query: str, top_k: int = 5) -> list[dict]:
        """
        Retrieve the most relevant clinical knowledge chunks for a query.

        Uses cosine similarity search on pgvector embeddings.
        Returns top_k chunks with their content, source, and page number.
        """
        # Embed the query
        query_embedding = self.embeddings.embed_query(query)

        # Search pgvector via Supabase RPC
        db = get_supabase_client()
        result = db.rpc(
            "match_knowledge_base",
            {
                "query_embedding": query_embedding,
                "match_threshold": 0.7,
                "match_count": top_k,
            },
        ).execute()

        return result.data if result.data else []
