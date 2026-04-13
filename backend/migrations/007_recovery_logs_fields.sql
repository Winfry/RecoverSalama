-- ============================================================
-- SalamaRecover: Migration 007 — Add channel and notes to recovery_logs
--
-- channel: tracks whether check-in came from 'app', 'ussd', or 'whatsapp'
-- notes:   free-text field for USSD and system-generated context
--
-- Run this in Supabase SQL Editor after 006_patient_fields.sql
-- ============================================================

ALTER TABLE recovery_logs
    ADD COLUMN IF NOT EXISTS channel text DEFAULT 'app',
    ADD COLUMN IF NOT EXISTS notes   text DEFAULT '';
