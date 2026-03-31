-- ============================================================
-- SalamaRecover: Initial Database Schema
-- Run this in Supabase SQL Editor (Settings > SQL Editor)
-- ============================================================

-- Enable pgvector for RAG knowledge base
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- 1. HOSPITALS TABLE (no dependencies)
-- ============================================================
CREATE TABLE IF NOT EXISTS hospitals (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    type        text CHECK (type IN ('public', 'private', 'mission', 'emergency')),
    address     text,
    phone       text,
    lat         double precision,
    lng         double precision,
    created_at  timestamptz DEFAULT now()
);

-- ============================================================
-- 2. PATIENTS TABLE (depends on auth.users + hospitals)
-- ============================================================
CREATE TABLE IF NOT EXISTS patients (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    name             text NOT NULL,
    age              integer,
    gender           text,
    surgery_type     text NOT NULL,
    surgery_date     date,
    hospital         text DEFAULT '',
    surgeon          text DEFAULT '',
    weight           double precision DEFAULT 0,
    blood_type       text DEFAULT '',
    allergies        text[] DEFAULT '{}',
    other_allergies  text DEFAULT '',
    phone            text DEFAULT '',
    hospital_id      uuid REFERENCES hospitals(id) ON DELETE SET NULL,
    created_at       timestamptz DEFAULT now()
);

-- Index for fast lookup by user_id (auth)
CREATE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id);
-- Index for hospital dashboard queries
CREATE INDEX IF NOT EXISTS idx_patients_hospital_id ON patients(hospital_id);

-- ============================================================
-- 3. RECOVERY_LOGS TABLE (check-in data)
-- ============================================================
CREATE TABLE IF NOT EXISTS recovery_logs (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id          uuid REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
    pain_level          integer CHECK (pain_level >= 0 AND pain_level <= 10),
    symptoms            text[] DEFAULT '{}',
    mood                text,
    risk_level          text CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'EMERGENCY')),
    days_since_surgery  integer,
    created_at          timestamptz DEFAULT now()
);

-- Index for patient history queries
CREATE INDEX IF NOT EXISTS idx_recovery_logs_patient_id ON recovery_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_recovery_logs_created_at ON recovery_logs(created_at DESC);

-- ============================================================
-- 4. MOOD_LOGS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS mood_logs (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  uuid REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
    mood        text NOT NULL,
    notes       text,
    created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mood_logs_patient_id ON mood_logs(patient_id);

-- ============================================================
-- 5. ALERTS TABLE (triggered by HIGH/EMERGENCY risk)
-- ============================================================
CREATE TABLE IF NOT EXISTS alerts (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  uuid REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
    hospital_id uuid REFERENCES hospitals(id) ON DELETE SET NULL,
    risk_level  text NOT NULL CHECK (risk_level IN ('HIGH', 'EMERGENCY')),
    symptoms    text[] DEFAULT '{}',
    message     text,
    status      text DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved')),
    created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_alerts_hospital_id ON alerts(hospital_id);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON alerts(created_at DESC);

-- ============================================================
-- 6. CHAT_MESSAGES TABLE (conversation history)
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id  uuid REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
    role        text NOT NULL CHECK (role IN ('user', 'assistant')),
    content     text NOT NULL,
    sources     text[] DEFAULT '{}',
    created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_patient_id ON chat_messages(patient_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- ============================================================
-- 7. KNOWLEDGE_BASE TABLE (RAG with pgvector)
-- ============================================================
CREATE TABLE IF NOT EXISTS knowledge_base (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    content     text NOT NULL,
    source      text,
    page        integer,
    metadata    jsonb DEFAULT '{}',
    embedding   vector(768),
    created_at  timestamptz DEFAULT now()
);

-- HNSW index for fast vector similarity search
CREATE INDEX IF NOT EXISTS idx_knowledge_base_embedding
    ON knowledge_base USING hnsw (embedding vector_cosine_ops);
