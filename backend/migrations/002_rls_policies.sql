-- ============================================================
-- SalamaRecover: Row Level Security Policies
-- Run this AFTER 001_initial_schema.sql
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE recovery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PATIENTS: Users can only access their own record
-- ============================================================
CREATE POLICY "patients_select_own"
    ON patients FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "patients_insert_own"
    ON patients FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "patients_update_own"
    ON patients FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================================
-- RECOVERY_LOGS: Users can access logs for their own patient record
-- ============================================================
CREATE POLICY "recovery_logs_select_own"
    ON recovery_logs FOR SELECT
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "recovery_logs_insert_own"
    ON recovery_logs FOR INSERT
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================
-- MOOD_LOGS: Users can access their own mood logs
-- ============================================================
CREATE POLICY "mood_logs_select_own"
    ON mood_logs FOR SELECT
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "mood_logs_insert_own"
    ON mood_logs FOR INSERT
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================
-- ALERTS: Users can read their own alerts
-- ============================================================
CREATE POLICY "alerts_select_own"
    ON alerts FOR SELECT
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================
-- CHAT_MESSAGES: Users can access their own messages
-- ============================================================
CREATE POLICY "chat_messages_select_own"
    ON chat_messages FOR SELECT
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "chat_messages_insert_own"
    ON chat_messages FOR INSERT
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================
-- HOSPITALS: Public read (everyone can see hospitals)
-- ============================================================
CREATE POLICY "hospitals_public_read"
    ON hospitals FOR SELECT
    USING (true);

-- ============================================================
-- KNOWLEDGE_BASE: Public read (RAG search needs this)
-- ============================================================
CREATE POLICY "knowledge_base_public_read"
    ON knowledge_base FOR SELECT
    USING (true);

-- ============================================================
-- SERVICE ROLE BYPASS
-- Note: The service_role key automatically bypasses RLS.
-- The FastAPI backend uses service_role for all DB operations,
-- so it can read/write all tables without restriction.
-- These RLS policies protect direct client access (Flutter/React).
-- ============================================================
