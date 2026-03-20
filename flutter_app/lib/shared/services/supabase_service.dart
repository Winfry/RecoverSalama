import 'package:supabase_flutter/supabase_flutter.dart';

/// Direct Supabase client for real-time features and auth.
/// Most data operations go through the FastAPI backend,
/// but auth and real-time subscriptions use Supabase directly.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Listen to real-time alerts for this patient
  static RealtimeChannel subscribeToAlerts(String patientId) {
    return client
        .channel('alerts:$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (payload) {
            // Handle incoming alert
          },
        )
        .subscribe();
  }
}
