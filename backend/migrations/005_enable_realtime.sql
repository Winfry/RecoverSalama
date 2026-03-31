-- ============================================================
-- SalamaRecover: Enable Realtime on alerts table
-- This allows the hospital dashboard to get live alert updates
-- ============================================================

-- Enable realtime for the alerts table
ALTER PUBLICATION supabase_realtime ADD TABLE alerts;
