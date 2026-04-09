import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/api_service.dart';

class MentalHealthState {
  final String? selectedMood;
  final DateTime? lastCheckIn;
  final String? supportMessage;
  final String? mentalHealthLevel; // "stable" | "monitor" | "needs_support"
  final bool isLoading;
  final String? error;

  const MentalHealthState({
    this.selectedMood,
    this.lastCheckIn,
    this.supportMessage,
    this.mentalHealthLevel,
    this.isLoading = false,
    this.error,
  });

  MentalHealthState copyWith({
    String? selectedMood,
    DateTime? lastCheckIn,
    String? supportMessage,
    String? mentalHealthLevel,
    bool? isLoading,
    String? error,
  }) {
    return MentalHealthState(
      selectedMood: selectedMood ?? this.selectedMood,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      supportMessage: supportMessage ?? this.supportMessage,
      mentalHealthLevel: mentalHealthLevel ?? this.mentalHealthLevel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MentalHealthNotifier extends StateNotifier<MentalHealthState> {
  final ApiService _api;

  MentalHealthNotifier(this._api) : super(const MentalHealthState());

  Future<void> selectMood(String mood, {String? notes}) async {
    // Immediately reflect selection in UI
    state = state.copyWith(
      selectedMood: mood,
      lastCheckIn: DateTime.now(),
      isLoading: true,
      error: null,
    );

    try {
      final response = await _api.submitMoodCheckIn(mood: mood, notes: notes);
      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        supportMessage: data['support_message'] as String?,
        mentalHealthLevel: data['mental_health_level'] as String?,
        isLoading: false,
      );
    } catch (_) {
      // API failure is non-fatal — UI falls back to local messages
      state = state.copyWith(isLoading: false, error: 'offline');
    }
  }
}

final mentalHealthProvider =
    StateNotifierProvider<MentalHealthNotifier, MentalHealthState>((ref) {
  return MentalHealthNotifier(ref.read(apiServiceProvider));
});
