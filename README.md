# SalamaRecover

AI-powered surgical recovery platform built for Kenya. Helps patients manage post-surgical recovery at home with AI guidance, while giving hospitals visibility into patient outcomes.

## The Problem

Thousands of Kenyan patients are discharged after surgery with minimal follow-up, leading to preventable complications, unnecessary readmissions, and patient anxiety.

## Architecture

```
Patients (Flutter App)  <-->  Backend (FastAPI)  <-->  Hospitals (React Dashboard)
        |                          |
  WhatsApp / USSD            AI + Database
  (Africa's Talking)      (Gemini + Supabase)
```

## Tech Stack (100% Free Tier)

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Patient App | Flutter (Dart) | iOS + Android mobile app |
| Hospital Dashboard | React.js + Tailwind | Web dashboard for clinical staff |
| Backend API | Python FastAPI | REST API, AI orchestration, ML serving |
| Database | Supabase (PostgreSQL + pgvector) | Data, auth, vector search for RAG |
| AI Engine | Google Gemini API | Chat assistant, risk scoring, clinical reasoning |
| RAG Knowledge Base | LangChain + pgvector | Grounds AI in Kenya MOH clinical guidelines |
| WhatsApp | Africa's Talking | WhatsApp bot for patients without app |
| USSD | Africa's Talking | Feature phone access, zero internet required |
| Hosting | Render (API) + Vercel (Dashboard) | Free deployment |

## Project Structure

```
salama-recover/
├── flutter_app/           # Patient mobile app (10 screens)
├── hospital_dashboard/    # React web dashboard (8 screens)
├── backend/               # FastAPI backend (shared brain)
│   ├── app/
│   │   ├── routers/       # API endpoints
│   │   ├── services/
│   │   │   ├── ai/        # Gemini, RAG, embeddings
│   │   │   ├── ml/        # Risk scorer, diet engine, readmission predictor
│   │   │   └── channels/  # WhatsApp, USSD
│   │   ├── schemas/       # Request/response data shapes
│   │   └── utils/         # Kiswahili detection, helpers
│   └── tests/
├── ml/                    # ML notebooks and scripts
│   ├── notebooks/         # RAG setup, prompt testing, data generation, evaluation
│   ├── scripts/           # Training and knowledge base scripts
│   └── data/              # Clinical PDFs, synthetic data, trained models
├── whatsapp/              # WhatsApp conversation flows
└── ussd/                  # USSD menu flows
```

## Key Features

- **AI Chat** — Bilingual (English + Kiswahili), grounded in Kenya MOH clinical guidelines via RAG
- **Daily Check-Ins** — Pain, symptoms, mood tracking with ML risk classification
- **Risk Scoring** — Two-layer system: rule-based safety net + Gemini clinical intelligence
- **Diet Engine** — Surgery-specific meal plans from the Kenya National Clinical Nutrition Manual
- **Emergency Alerts** — Auto-triggered when risk is HIGH/EMERGENCY, sent to hospital dashboard
- **Hospital Dashboard** — Patient lists, alert centre, analytics
- **WhatsApp + USSD** — Reach patients without smartphones or internet

## Setup

### Prerequisites

- Flutter SDK (>=3.16.0)
- Python (>=3.11)
- Node.js (>=18)
- Free accounts: Supabase, Google AI Studio, Africa's Talking, Render, Vercel

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env      # Edit with your API keys
uvicorn app.main:app --reload
```

### Flutter App

```bash
cd flutter_app
cp .env.example .env      # Edit with your API keys
flutter pub get
flutter run
```

### Hospital Dashboard

```bash
cd hospital_dashboard
npm install
cp .env.example .env      # Edit with your API keys
npm run dev
```

## Build Roadmap

| Phase | Weeks | Goal |
|-------|-------|------|
| 1 | 1-2 | Real AI + database integration |
| 2 | 3-4 | Knowledge base + diet engine |
| 3 | 5-6 | ML risk classifier |
| 4 | 7-9 | WhatsApp channel |
| 5 | 10-12 | Hospital dashboard + pilot partnerships |
| 6 | 13-16 | USSD/SMS for feature phones |

## Author

**Winfry Nyarangi Nyabuto**

Confidential & Proprietary. All Rights Reserved.
