"""
SalamaRecover FastAPI Backend — The Brain

This is the central server that both the Flutter patient app and
React hospital dashboard talk to. It handles:

1. AI Chat — Gemini API + RAG over Kenya MOH clinical guidelines
2. Check-Ins — Receives patient symptom data, runs ML risk classifier
3. Diet Engine — Returns surgery-specific, allergy-aware meal plans
4. Alerts — Triggers hospital notifications when risk is HIGH/EMERGENCY
5. WhatsApp/USSD — Webhook handlers for Africa's Talking channels
6. Scheduler — Daily 6 AM WhatsApp reminders to active patients

Deployed on Render.com (free tier).
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import patients, recovery, chat, alerts, hospitals, webhooks
from app.services.scheduler import create_scheduler

logger = logging.getLogger(__name__)


# ── Lifespan: start/stop the scheduler with the server ────────────────────
#
# FastAPI's lifespan replaces the old @app.on_event("startup") pattern.
# Everything before `yield` runs on startup.
# Everything after `yield` runs on shutdown.
#
# The scheduler MUST be started here (not at module level) because it
# needs the asyncio event loop, which only exists once FastAPI is running.

@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ──────────────────────────────────────────────────────────
    scheduler = create_scheduler()
    scheduler.start()
    logger.info("SalamaRecover started. Scheduler running.")

    yield  # Server is live and handling requests

    # ── Shutdown ─────────────────────────────────────────────────────────
    scheduler.shutdown(wait=False)
    logger.info("SalamaRecover shutting down. Scheduler stopped.")


# ── App ────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="SalamaRecover API",
    description="AI-Powered Surgical Recovery Platform for Kenya",
    version="2.0.0",
    lifespan=lifespan,
)

# CORS — allow Flutter app and React dashboard to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register route groups
app.include_router(patients.router, prefix="/api/patients", tags=["Patients"])
app.include_router(recovery.router, prefix="/api/recovery", tags=["Recovery"])
app.include_router(chat.router, prefix="/api/chat", tags=["AI Chat"])
app.include_router(alerts.router, prefix="/api/alerts", tags=["Alerts"])
app.include_router(hospitals.router, prefix="/api/hospitals", tags=["Hospitals"])
app.include_router(webhooks.router, prefix="/api/webhooks", tags=["Webhooks"])


@app.get("/")
async def root():
    return {
        "app": "SalamaRecover API",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}
