import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/api_service.dart';
import '../../recovery/providers/recovery_provider.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────

class FoodItem {
  final String icon;
  final String name;
  final String benefit;
  final int calories;
  final String source;

  const FoodItem({
    required this.icon,
    required this.name,
    required this.benefit,
    this.calories = 0,
    this.source = '',
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        icon: json['icon'] as String? ?? '🍽️',
        name: json['name'] as String? ?? '',
        benefit: json['benefit'] as String? ?? '',
        calories: json['calories'] as int? ?? 0,
        source: json['source'] as String? ?? '',
      );
}

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

class DietState {
  final int currentDay;
  final String phase;       // "clear_liquid" | "full_liquid" | "soft_diet" | "high_protein"
  final String phaseLabel;  // Human-readable e.g. "Soft Diet"
  final String aiTip;       // Phase-specific tip shown in the green banner
  final int targetKcal;
  final List<FoodItem> foods;
  final List<String> avoidList;
  final String source;      // Citation: "Kenya National Clinical Nutrition Manual (MOH 2010)"
  final bool isLoading;
  final String errorMessage;

  const DietState({
    this.currentDay = 0,
    this.phase = '',
    this.phaseLabel = '',
    this.aiTip = '',
    this.targetKcal = 0,
    this.foods = const [],
    this.avoidList = const [],
    this.source = '',
    this.isLoading = false,
    this.errorMessage = '',
  });

  DietState copyWith({
    int? currentDay,
    String? phase,
    String? phaseLabel,
    String? aiTip,
    int? targetKcal,
    List<FoodItem>? foods,
    List<String>? avoidList,
    String? source,
    bool? isLoading,
    String? errorMessage,
  }) =>
      DietState(
        currentDay: currentDay ?? this.currentDay,
        phase: phase ?? this.phase,
        phaseLabel: phaseLabel ?? this.phaseLabel,
        aiTip: aiTip ?? this.aiTip,
        targetKcal: targetKcal ?? this.targetKcal,
        foods: foods ?? this.foods,
        avoidList: avoidList ?? this.avoidList,
        source: source ?? this.source,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class DietNotifier extends StateNotifier<DietState> {
  final ApiService _api;

  DietNotifier(this._api) : super(const DietState());

  /// Fetch the personalised diet plan from FastAPI.
  ///
  /// The backend uses:
  ///   - surgeryType  → surgery-specific diet rules
  ///   - daysSinceSurgery → which phase (clear/full liquid, soft, high protein)
  ///   - allergies    → filters out allergen foods
  ///
  /// Source: Kenya National Clinical Nutrition Manual (MOH 2010)
  Future<void> loadDietPlan({
    required String surgeryType,
    required int daysSinceSurgery,
    required List<String> allergies,
  }) async {
    if (surgeryType.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final response = await _api.getDietPlan(
        surgeryType: surgeryType,
        daysSinceSurgery: daysSinceSurgery,
        allergies: allergies,
      );

      final data = response.data as Map<String, dynamic>;

      final foodsJson = (data['foods'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final avoidJson = (data['avoid'] as List<dynamic>? ?? [])
          .map((a) => a.toString())
          .toList();

      final phase = data['phase'] as String? ?? '';

      state = state.copyWith(
        isLoading: false,
        currentDay: data['day'] as int? ?? daysSinceSurgery,
        phase: phase,
        phaseLabel: _phaseLabel(phase),
        aiTip: _phaseTip(phase),
        targetKcal: data['target_kcal'] as int? ?? 0,
        foods: foodsJson.map(FoodItem.fromJson).toList(),
        avoidList: avoidJson,
        source: data['source'] as String? ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(e),
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: '');

  // ── Helpers ──────────────────────────────────────────────

  String _phaseLabel(String phase) => switch (phase) {
        'clear_liquid' => 'Clear Liquid Diet',
        'full_liquid'  => 'Full Liquid Diet',
        'soft_diet'    => 'Soft Diet',
        'high_protein' => 'High Protein Diet',
        _              => 'Recovery Diet',
      };

  String _phaseTip(String phase) => switch (phase) {
        'clear_liquid' =>
          'Sip slowly and often. Clear liquids help your digestive system wake up gently after surgery.',
        'full_liquid' =>
          'Uji wa wimbi and mtindi are excellent choices — high in protein and calories to fuel your healing.',
        'soft_diet' =>
          'Soft ugali with mashed vegetables is ideal this week. Easy to digest, packed with nutrients.',
        'high_protein' =>
          'Your body needs extra protein to rebuild tissue. Aim for eggs, samaki, or beans at every meal.',
        _ =>
          'Follow the recommended foods below. They are selected specifically for your surgery type and recovery day.',
      };

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet. Check your network and try again.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Session expired. Please log in again.';
    }
    return 'Could not load diet plan. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final dietProvider = StateNotifierProvider<DietNotifier, DietState>((ref) {
  return DietNotifier(ref.watch(apiServiceProvider));
});
