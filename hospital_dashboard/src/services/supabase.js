/**
 * Supabase client for real-time features.
 *
 * The hospital dashboard uses Supabase Realtime to get
 * instant notifications when a patient's risk level changes.
 * This means nurses see alerts the moment they happen —
 * no need to refresh the page.
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

/**
 * Subscribe to real-time alerts for a hospital.
 * Calls the callback whenever a new alert is inserted.
 */
export function subscribeToAlerts(hospitalId, callback) {
  return supabase
    .channel(`alerts:${hospitalId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'alerts',
        filter: `hospital_id=eq.${hospitalId}`,
      },
      (payload) => callback(payload.new)
    )
    .subscribe();
}
