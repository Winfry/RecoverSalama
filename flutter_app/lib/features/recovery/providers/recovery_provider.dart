import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recovery state model
class RecoveryState {
  final String stageName;
  final String stageDescription;
  final List<String> allowedActivities;
  final List<String> restrictedActivities;
  final String aiTip;
  final bool hasWarning;
  final String warningMessage;
  final int lastPainLevel;
  final List<String> lastSymptoms;
  final String lastMood;

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
    this.aiTip =
        'Pair ugali with beans tonight for a complete protein boost.',
    this.hasWarning = false,
    this.warningMessage = '',
    this.lastPainLevel = 0,
    this.lastSymptoms = const [],
    this.lastMood = 'Good',
  });

  RecoveryState copyWith({
    String? stageName,
    String? stageDescription,
    List<String>? allowedActivities,
    List<String>? restrictedActivities,
    String? aiTip,
    bool? hasWarning,
    String? warningMessage,
    int? lastPainLevel,
    List<String>? lastSymptoms,
    String? lastMood,
  }) {
    return RecoveryState(
      stageName: stageName ?? this.stageName,
      stageDescription: stageDescription ?? this.stageDescription,
      allowedActivities: allowedActivities ?? this.allowedActivities,
      restrictedActivities: restrictedActivities ?? this.restrictedActivities,
      aiTip: aiTip ?? this.aiTip,
      hasWarning: hasWarning ?? this.hasWarning,
      warningMessage: warningMessage ?? this.warningMessage,
      lastPainLevel: lastPainLevel ?? this.lastPainLevel,
      lastSymptoms: lastSymptoms ?? this.lastSymptoms,
      lastMood: lastMood ?? this.lastMood,
    );
  }
}

class RecoveryNotifier extends StateNotifier<RecoveryState> {
  RecoveryNotifier() : super(const RecoveryState());

  void submitCheckIn({
    required int painLevel,
    required List<String> symptoms,
    required String mood,
    required bool hasCriticalSymptoms,
  }) {
    state = state.copyWith(
      lastPainLevel: painLevel,
      lastSymptoms: symptoms,
      lastMood: mood,
      hasWarning: hasCriticalSymptoms || painLevel >= 7,
      warningMessage: hasCriticalSymptoms
          ? 'Critical symptoms detected — contact hospital immediately'
          : painLevel >= 7
              ? 'High pain level reported — monitor closely'
              : '',
    );

    // TODO: Send check-in data to FastAPI backend
    // TODO: Run ML risk classifier on symptoms
    // TODO: Trigger emergency alert if risk = HIGH/EMERGENCY
  }
}

final recoveryProvider =
    StateNotifierProvider<RecoveryNotifier, RecoveryState>((ref) {
  return RecoveryNotifier();
});
