-- ============================================================
-- SalamaRecover: Migration 006 — Add missing patient fields
--
-- Adds:
--   caregiver_phone       — for HIGH/EMERGENCY WhatsApp alerts to family
--   notifications_enabled — scheduler checks this before sending reminders
--   is_active             — soft-delete flag
--
-- Run this in Supabase SQL Editor after 005_enable_realtime.sql
-- ============================================================

ALTER TABLE patients
    ADD COLUMN IF NOT EXISTS caregiver_phone      text DEFAULT '',
    ADD COLUMN IF NOT EXISTS notifications_enabled boolean DEFAULT true,
    ADD COLUMN IF NOT EXISTS is_active             boolean DEFAULT true;

-- Back-fill existing rows so the scheduler picks them up immediately
UPDATE patients
SET notifications_enabled = true
WHERE notifications_enabled IS NULL;

UPDATE patients
SET is_active = true
WHERE is_active IS NULL;
