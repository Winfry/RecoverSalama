-- ============================================================
-- SalamaRecover: Migration 008 — Add missing columns to alerts table
--
-- channel:    'app', 'ussd', or 'whatsapp' — where the check-in came from
-- pain_level: numeric pain score at time of alert (0-10)
-- phone:      patient phone number (for USSD patients without a patient_id)
--
-- Run this in Supabase SQL Editor after 007_recovery_logs_fields.sql
-- ============================================================

ALTER TABLE alerts
    ADD COLUMN IF NOT EXISTS channel    text DEFAULT 'app',
    ADD COLUMN IF NOT EXISTS pain_level integer,
    ADD COLUMN IF NOT EXISTS phone      text DEFAULT '';
