"""
Application configuration — loads environment variables.
All secrets (API keys, database URLs) live in .env, never in code.
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Supabase
    supabase_url: str = ""
    supabase_anon_key: str = ""
    supabase_service_key: str = ""

    # AI
    gemini_api_key: str = ""
    groq_api_key: str = ""  # Fallback LLM

    # Africa's Talking (WhatsApp + USSD)
    at_api_key: str = ""
    at_username: str = "sandbox"

    # Auth
    secret_key: str = "change-me-in-production"

    # CORS
    cors_origins: list[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
    ]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
