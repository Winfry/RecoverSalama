import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentalHealthState {
  final String? selectedMood;
  final DateTime? lastCheckIn;

  const MentalHealthState({this.selectedMood, this.lastCheckIn});
}

class MentalHealthNotifier extends StateNotifier<MentalHealthState> {
  MentalHealthNotifier() : super(const MentalHealthState());

  void selectMood(String mood) {
    state = MentalHealthState(
      selectedMood: mood,
      lastCheckIn: DateTime.now(),
    );
    // TODO: Send mood data to backend for mood classifier ML model
  }
}

final mentalHealthProvider =
    StateNotifierProvider<MentalHealthNotifier, MentalHealthState>((ref) {
  return MentalHealthNotifier();
});
