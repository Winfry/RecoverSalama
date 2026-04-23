import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/api_service.dart';
import '../../recovery/providers/recovery_provider.dart';

// ─────────────────────────────────────────────────────────────
// NEW Models — Structured AI Meal Plan
// ─────────────────────────────────────────────────────────────

class MealItemDetail {
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MealItemDetail({
    required this.name,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  factory MealItemDetail.fromJson(Map<String, dynamic> j) => MealItemDetail(
        name: j['name'] as String? ?? '',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
      );
}

class MealDetail {
  final String name;
  final int score;
  final String description;
  final List<MealItemDetail> items;
  final int totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;

  const MealDetail({
    required this.name,
    this.score = 0,
    this.description = '',
    this.items = const [],
    this.totalCalories = 0,
    this.totalProteinG = 0,
    this.totalCarbsG = 0,
    this.totalFatG = 0,
  });

  factory MealDetail.fromJson(Map<String, dynamic> j) => MealDetail(
        name: j['name'] as String? ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        description: j['description'] as String? ?? '',
        items: (j['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(MealItemDetail.fromJson)
            .toList(),
        totalCalories: (j['total_calories'] as num?)?.toInt() ?? 0,
        totalProteinG: (j['total_protein_g'] as num?)?.toDouble() ?? 0,
        totalCarbsG: (j['total_carbs_g'] as num?)?.toDouble() ?? 0,
        totalFatG: (j['total_fat_g'] as num?)?.toDouble() ?? 0,
      );

  MealDetail copyWithAlternative(MealAlternative alt) => MealDetail(
        name: alt.name,
        score: alt.rating,
        description: alt.description,
        items: [
          MealItemDetail(
            name: alt.name,
            calories: alt.totalCalories,
            proteinG: alt.totalProteinG,
            carbsG: alt.totalCarbsG,
            fatG: alt.totalFatG,
          ),
        ],
        totalCalories: alt.totalCalories,
        totalProteinG: alt.totalProteinG,
        totalCarbsG: alt.totalCarbsG,
        totalFatG: alt.totalFatG,
      );
}

class MealPlan {
  final String phase;
  final String phaseLabel;
  final int targetKcal;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final String aiTip;
  final Map<String, MealDetail> meals; // keys: breakfast/lunch/dinner/snack
  final List<String> avoid;            // Foods to avoid — from Kenya MOH rules

  const MealPlan({
    this.phase = '',
    this.phaseLabel = '',
    this.targetKcal = 0,
    this.targetProteinG = 0,
    this.targetCarbsG = 0,
    this.targetFatG = 0,
    this.aiTip = '',
    this.meals = const {},
    this.avoid = const [],
  });

  factory MealPlan.fromJson(Map<String, dynamic> j) => MealPlan(
        phase: j['phase'] as String? ?? '',
        phaseLabel: j['phase_label'] as String? ?? j['phase'] as String? ?? '',
        targetKcal: (j['target_kcal'] as num?)?.toInt() ?? 0,
        targetProteinG: (j['target_protein_g'] as num?)?.toDouble() ?? 0,
        targetCarbsG: (j['target_carbs_g'] as num?)?.toDouble() ?? 0,
        targetFatG: (j['target_fat_g'] as num?)?.toDouble() ?? 0,
        aiTip: j['ai_tip'] as String? ?? '',
        meals: (j['meals'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, MealDetail.fromJson(v as Map<String, dynamic>)),
        ),
        avoid: (j['avoid'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );

  int get totalCalories => meals.values.fold(0, (s, m) => s + m.totalCalories);
  double get totalProteinG => meals.values.fold(0.0, (s, m) => s + m.totalProteinG);
  double get totalCarbsG => meals.values.fold(0.0, (s, m) => s + m.totalCarbsG);
  double get totalFatG => meals.values.fold(0.0, (s, m) => s + m.totalFatG);

  MealPlan withUpdatedMeal(String mealType, MealDetail updated) => MealPlan(
        phase: phase,
        phaseLabel: phaseLabel,
        targetKcal: targetKcal,
        targetProteinG: targetProteinG,
        targetCarbsG: targetCarbsG,
        targetFatG: targetFatG,
        aiTip: aiTip,
        meals: Map.from(meals)..[mealType] = updated,
        avoid: avoid,
      );
}

class MealAlternative {
  final String name;
  final int rating;
  final String description;
  final int totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;

  const MealAlternative({
    required this.name,
    this.rating = 0,
    this.description = '',
    this.totalCalories = 0,
    this.totalProteinG = 0,
    this.totalCarbsG = 0,
    this.totalFatG = 0,
  });

  factory MealAlternative.fromJson(Map<String, dynamic> j) => MealAlternative(
        name: j['name'] as String? ?? '',
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        description: j['description'] as String? ?? '',
        totalCalories: (j['total_calories'] as num?)?.toInt() ?? 0,
        totalProteinG: (j['total_protein_g'] as num?)?.toDouble() ?? 0,
        totalCarbsG: (j['total_carbs_g'] as num?)?.toDouble() ?? 0,
        totalFatG: (j['total_fat_g'] as num?)?.toDouble() ?? 0,
      );
}

// ─────────────────────────────────────────────────────────────
// LEGACY Model — flat food list (kept for backward compat)
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
  // ── NEW: structured AI meal plan (breakfast/lunch/dinner/snack) ──
  final MealPlan? mealPlan;
  final bool isLoadingAlternatives;
  final List<MealAlternative> alternatives;
  final String alternativesError;

  // ── LEGACY: flat food list (retained) ───────────────────────────
  final int currentDay;       // Which recovery day this plan is for
  final String phase;         // "clear_liquid" | "full_liquid" | "soft_diet" | "high_protein"
  final String phaseLabel;    // Human-readable e.g. "Soft Diet"
  final String aiTip;         // Phase-specific tip shown in the green banner
  final int targetKcal;
  final List<FoodItem> foods;
  final List<String> avoidList;
  final String source;        // Citation: "Kenya National Clinical Nutrition Manual (MOH 2010)"

  // ── Shared ──────────────────────────────────────────────────────
  final bool isLoading;
  final String errorMessage;

  const DietState({
    this.mealPlan,
    this.isLoadingAlternatives = false,
    this.alternatives = const [],
    this.alternativesError = '',
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
    MealPlan? mealPlan,
    bool? isLoadingAlternatives,
    List<MealAlternative>? alternatives,
    String? alternativesError,
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
        mealPlan: mealPlan ?? this.mealPlan,
        isLoadingAlternatives:
            isLoadingAlternatives ?? this.isLoadingAlternatives,
        alternatives: alternatives ?? this.alternatives,
        alternativesError: alternativesError ?? this.alternativesError,
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
  ///   - surgeryType          → surgery-specific diet rules (15 surgery types)
  ///   - daysSinceSurgery     → which phase (clear/full liquid, soft, high protein)
  ///   - allergies            → filters out allergen foods
  ///
  /// This calls the Gemini-powered /meal_plan endpoint which returns a
  /// structured breakfast/lunch/dinner/snack plan with per-item macros.
  /// The legacy flat fields (phase, phaseLabel, aiTip, targetKcal) are also
  /// populated from the same response so existing code continues to work.
  ///
  /// Source: Kenya National Clinical Nutrition Manual (MOH 2010)
  Future<void> loadDietPlan({
    required String surgeryType,
    required int daysSinceSurgery,
    required List<String> allergies,
  }) async {
    await loadMealPlan(
      surgeryType: surgeryType,
      daysSinceSurgery: daysSinceSurgery,
      allergies: allergies,
    );
  }

  /// Load the structured AI meal plan for the weekly diet screen.
  ///
  /// Calls GET /api/recovery/meal_plan which:
  ///   1. Uses DietEngine to determine the correct phase for surgeryType+day
  ///   2. Calls Gemini to generate Kenya-local structured meals with macros
  ///
  /// Also back-fills legacy flat fields so existing code is unaffected.
  Future<void> loadMealPlan({
    required String surgeryType,
    required int daysSinceSurgery,
    required List<String> allergies,
  }) async {
    if (surgeryType.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final response = await _api.getMealPlan(
        surgeryType: surgeryType,
        daysSinceSurgery: daysSinceSurgery,
        allergies: allergies,
      );

      final data = response.data as Map<String, dynamic>;
      final plan = MealPlan.fromJson(data);

      // Back-fill legacy flat fields from the structured plan so
      // any existing code reading phase/phaseLabel/aiTip/targetKcal
      // continues to work without changes.
      final phaseRaw = plan.phase;
      state = state.copyWith(
        isLoading: false,
        mealPlan: plan,
        currentDay: daysSinceSurgery,
        phase: phaseRaw,
        phaseLabel: plan.phaseLabel.isNotEmpty
            ? plan.phaseLabel
            : _phaseLabel(phaseRaw),
        aiTip: plan.aiTip.isNotEmpty ? plan.aiTip : _phaseTip(phaseRaw),
        targetKcal: plan.targetKcal,
        avoidList: plan.avoid,
        source: 'Kenya National Clinical Nutrition Manual (MOH 2010)',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(e),
      );
    }
  }

  /// Fetch 5 AI alternatives for a specific meal.
  ///
  /// Calls POST /api/recovery/meal_alternatives with:
  ///   - The current meal name and type (breakfast/lunch/dinner/snack)
  ///   - The patient's free-text preference (e.g. "something lighter")
  ///   - Surgery type + recovery day so Gemini respects phase restrictions
  ///   - Allergens so Gemini avoids them
  Future<void> fetchAlternatives({
    required String mealName,
    required String mealType,
    required String preferenceText,
    required String surgeryType,
    required int day,
    required List<String> allergies,
  }) async {
    state = state.copyWith(
      isLoadingAlternatives: true,
      alternativesError: '',
      alternatives: [],
    );

    try {
      final response = await _api.getMealAlternatives(
        mealName: mealName,
        mealType: mealType,
        preferenceText: preferenceText,
        surgeryType: surgeryType,
        day: day,
        phase: state.mealPlan?.phase ?? '',
        allergies: allergies,
      );
      final data = response.data as Map<String, dynamic>;
      final alts = (data['alternatives'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(MealAlternative.fromJson)
          .toList();
      state = state.copyWith(
        isLoadingAlternatives: false,
        alternatives: alts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAlternatives: false,
        alternativesError: _friendlyError(e),
      );
    }
  }

  /// Replace a meal in the current plan with a chosen alternative.
  void acceptAlternative(String mealType, MealAlternative alt) {
    final plan = state.mealPlan;
    if (plan == null) return;
    final current = plan.meals[mealType];
    if (current == null) return;
    state = state.copyWith(
      mealPlan: plan.withUpdatedMeal(mealType, current.copyWithAlternative(alt)),
      alternatives: [],
    );
  }

  void clearAlternatives() => state = state.copyWith(alternatives: []);

  void clearError() => state = state.copyWith(errorMessage: '');

  // ── Helpers ──────────────────────────────────────────────

  /// Map a phase string to a human-readable label.
  /// Handles both short keys ("clear_liquid") and full names ("Clear Liquid Diet").
  String _phaseLabel(String phase) {
    final lower = phase.toLowerCase();
    if (lower.contains('clear')) return 'Clear Liquid Diet';
    if (lower.contains('full') && lower.contains('liquid')) return 'Full Liquid Diet';
    if (lower.contains('soft')) return 'Soft Diet';
    if (lower.contains('protein') || lower.contains('high')) return 'High Protein Diet';
    return phase.isNotEmpty ? phase : 'Recovery Diet';
  }

  /// Phase-specific recovery tip shown on the diet screen.
  /// Keyed to the phase so the right guidance shows regardless of how the
  /// backend names the phase.
  String _phaseTip(String phase) {
    final lower = phase.toLowerCase();
    if (lower.contains('clear')) {
      return 'Sip slowly and often. Clear liquids help your digestive system wake up gently after surgery.';
    }
    if (lower.contains('full') && lower.contains('liquid')) {
      return 'Uji wa wimbi and mtindi are excellent choices — high in protein and calories to fuel your healing.';
    }
    if (lower.contains('soft')) {
      return 'Soft ugali with mashed vegetables is ideal this week. Easy to digest, packed with nutrients.';
    }
    if (lower.contains('protein') || lower.contains('high')) {
      return 'Your body needs extra protein to rebuild tissue. Aim for eggs, samaki, or beans at every meal.';
    }
    return 'Follow the recommended foods below. They are selected specifically for your surgery type and recovery day.';
  }

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
