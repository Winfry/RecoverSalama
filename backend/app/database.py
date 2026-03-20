"""
Supabase database client.

Supabase is PostgreSQL under the hood. We use it for:
- Patient profiles and recovery logs
- pgvector for RAG knowledge base (Kenya Nutrition Manual embeddings)
- Real-time subscriptions (for hospital alert dashboard)
- Row Level Security (RLS) for data privacy
"""

from supabase import create_client, Client

from app.config import settings


def get_supabase_client() -> Client:
    """Returns a Supabase client for database operations."""
    return create_client(settings.supabase_url, settings.supabase_service_key)


def get_anon_client() -> Client:
    """Returns a Supabase client with anon key (for RLS-restricted queries)."""
    return create_client(settings.supabase_url, settings.supabase_anon_key)
