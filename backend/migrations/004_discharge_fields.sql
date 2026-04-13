-- ============================================================
-- SalamaRecover: Discharge Fields
-- Adds discharge tracking to the patients table.
-- Run this in Supabase SQL Editor after 001_initial_schema.sql
-- ============================================================

ALTER TABLE patients
    ADD COLUMN IF NOT EXISTS is_discharged    boolean   DEFAULT false,
    ADD COLUMN IF NOT EXISTS discharge_date   date,
    ADD COLUMN IF NOT EXISTS assigned_doctor  text      DEFAULT '',
    ADD COLUMN IF NOT EXISTS discharge_notes  text      DEFAULT '';

-- Index for filtering active (non-discharged) patients quickly
CREATE INDEX IF NOT EXISTS idx_patients_is_discharged
    ON patients(is_discharged);

COMMENT ON COLUMN patients.discharge_date  IS 'Official date patient left hospital — starts the home-recovery countdown';
COMMENT ON COLUMN patients.discharge_notes IS 'Doctor instructions — shown directly in patient Flutter app';
COMMENT ON COLUMN patients.assigned_doctor IS 'Doctor responsible for this patient''s follow-up';
COMMENT ON COLUMN patients.is_discharged   IS 'True once the hospital has formally discharged the patient';
