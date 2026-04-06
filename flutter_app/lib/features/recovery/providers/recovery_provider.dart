import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/api_service.dart';

/// Single instance of ApiService shared across the app
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

class RecoveryState {
  final String stageName;
  final String stageDescription;
  final List<String> allowedActivities;
  final List<String> restrictedActivities;

  /// Real values returned by the backend after a check-in
  final String riskLevel;        // "LOW" | "MEDIUM" | "HIGH" | "EMERGENCY"
  final String aiTip;            // Backend AI tip / recommendation
  final String riskMessage;      // Human-readable risk summary
  final String reasoning;        // Gemini clinical reasoning (shown in dashboard)

  /// Last submitted check-in values (shown on dashboard)
  final int lastPainLevel;
  final List<String> lastSymptoms;
  final String lastMood;

  /// True while the API call is in flight — screen shows spinner
  final bool isLoading;

  /// Non-empty when an API call fails — screen shows error banner
  final String errorMessage;

  const RecoveryState({
    this.stageName = 'Stage 2 — Early Healing',
    this.stageDescription =
        'Body is rebuilding tissue. Light movement helps.',
    this.allowedActivities = const [
      'Short walks',
      'Deep breathing exercises',
      'Light reading',
    ],
    this.restrictedActivities = const [
      'Lifting above 2kg',
      'Driving',
      'Strenuous exercise',
    ],
    this.riskLevel = 'LOW',
    this.aiTip = '',
    this.riskMessage = '',
    this.reasoning = '',
    this.lastPainLevel = 0,
    this.lastSymptoms = const [],
    this.lastMood = 'Good',
    this.isLoading = false,
    this.errorMessage = '',
  });

  /// True when the backend flagged this check-in as HIGH or EMERGENCY
  bool get hasWarning =>
      riskLevel == 'HIGH' || riskLevel == 'EMERGENCY';

  /// Human-friendly warning text shown on the dashboard emergency banner
  String get warningMessage => riskMessage.isNotEmpty
      ? riskMessage
      : riskLevel == 'EMERGENCY'
          ? 'EMERGENCY — Contact your hospital immediately'
          : 'High risk detected — monitor closely and rest';

  RecoveryState copyWith({
    String? stageName,
    String? stageDescription,
    List<String>? allowedActivities,
    List<String>? restrictedActivities,
    String? riskLevel,
    String? aiTip,
    String? riskMessage,
    String? reasoning,
    int? lastPainLevel,
    List<String>? lastSymptoms,
    String? lastMood,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecoveryState(
      stageName: stageName ?? this.stageName,
      stageDescription: stageDescription ?? this.stageDescription,
      allowedActivities: allowedActivities ?? this.allowedActivities,
      restrictedActivities: restrictedActivities ?? this.restrictedActivities,
      riskLevel: riskLevel ?? this.riskLevel,
      aiTip: aiTip ?? this.aiTip,
      riskMessage: riskMessage ?? this.riskMessage,
      reasoning: reasoning ?? this.reasoning,
      lastPainLevel: lastPainLevel ?? this.lastPainLevel,
      lastSymptoms: lastSymptoms ?? this.lastSymptoms,
      lastMood: lastMood ?? this.lastMood,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class RecoveryNotifier extends StateNotifier<RecoveryState> {
  final ApiService _api;

  RecoveryNotifier(this._api) : super(const RecoveryState());

  /// Submit the daily check-in to FastAPI.
  ///
  /// Flow:
  ///   1. Set isLoading = true (screen shows spinner)
  ///   2. POST /api/recovery/checkin → backend runs two-layer risk scorer
  ///   3. Backend saves to recovery_logs; creates alert if HIGH/EMERGENCY
  ///   4. Update state with real risk_level + message + recommendation
  ///   5. On failure → set errorMessage so the screen can show it
  Future<void> submitCheckIn({
    required int painLevel,
    required List<String> symptoms,
    required String mood,
    required int daysSinceSurgery,
  }) async {
    // Clear any previous error and start loading
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      lastPainLevel: painLevel,
      lastSymptoms: symptoms,
      lastMood: mood,
    );

    try {
      final response = await _api.submitCheckIn(
        painLevel: painLevel,
        symptoms: symptoms,
        mood: mood,
        daysSinceSurgery: daysSinceSurgery,
      );

      final data = response.data as Map<String, dynamic>;

      state = state.copyWith(
        isLoading: false,
        riskLevel: data['risk_level'] as String? ?? 'LOW',
        riskMessage: data['message'] as String? ?? '',
        aiTip: data['recommendation'] as String? ?? '',
        reasoning: data['reasoning'] as String? ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(e),
      );
    }
  }

  /// Clears the error message after the screen has shown it
  void clearError() => state = state.copyWith(errorMessage: '');

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Session expired. Please log in again.';
    }
    if (msg.contains('422')) {
      return 'Check-in data is invalid. Please try again.';
    }
    return 'Could not submit check-in. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final recoveryProvider =
    StateNotifierProvider<RecoveryNotifier, RecoveryState>((ref) {
  return RecoveryNotifier(ref.watch(apiServiceProvider));
});
