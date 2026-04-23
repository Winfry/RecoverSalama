// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 08: Weekly Diet Plan
// Dark-themed weekly plan with AI-powered meal swaps.
// Kenya-local food recommendations grounded in MOH 2010 guidelines.
// Surgery type + recovery day determine the phase; Gemini builds the plan.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/diet_provider.dart';

// ── Theme constants ───────────────────────────────────────────
const _kBg      = Color(0xFF111827);  // dark navy background
const _kCard    = Color(0xFF1F2937);  // card surface
const _kChip    = Color(0xFF374151);  // small macro chip background
const _kPrimary = Color(0xFF0077B6);  // brand blue
const _kGreen   = Color(0xFF00B37E);  // brand green
const _kAmber   = Color(0xFFF59E0B);  // carbs colour
const _kPurple  = Color(0xFF8B5CF6);  // fat colour
const _kRed     = Color(0xFFEF4444);  // low-score / error

const _kDayNames   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kMealOrder  = ['breakfast', 'lunch', 'dinner', 'snack'];
const _kMealIcons  = {
  'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍎',
};
const _kMealLabels = {
  'breakfast': 'Breakfast', 'lunch': 'Lunch',
  'dinner': 'Dinner', 'snack': 'Snack',
};

// ─────────────────────────────────────────────────────────────

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  late DateTime _weekStart;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart    = now.subtract(Duration(days: now.weekday - 1)); // Monday
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForDate(_selectedDate));
  }

  // ── Helpers ───────────────────────────────────────────────

  void _loadForDate(DateTime date) {
    final profile = ref.read(profileProvider);
    if (profile.surgeryType.isEmpty) return;

    // Surgery type + day-since-surgery are the two critical inputs.
    // Surgery type → selects the correct diet protocol (15 types supported).
    // Day since surgery → determines the phase (clear liquid / soft / high protein).
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = date.difference(todayDate).inDays;
    final targetDay = (profile.daysSinceSurgery + diff).clamp(0, 730);

    final allergies = [
      ...profile.allergies,
      if (profile.otherAllergies.isNotEmpty) profile.otherAllergies,
    ];

    ref.read(dietProvider.notifier).loadMealPlan(
          surgeryType: profile.surgeryType,
          daysSinceSurgery: targetDay,
          allergies: allergies,
        );
  }

  void _selectDay(DateTime date) {
    if (_isSameDay(date, _selectedDate)) return;
    setState(() => _selectedDate = date);
    _loadForDate(date);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthAbbr(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  String _dateRangeLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    return '${_monthAbbr(_weekStart.month)} ${_weekStart.day} – '
        '${_monthAbbr(end.month)} ${end.day}';
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final diet    = ref.watch(dietProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(diet),
          _buildDaySelector(),
          Expanded(child: _buildBody(diet, profile)),
          SalamaBottomNav(
            currentIndex: 3,
            onTap: (i) {
              final routes = [
                AppRoutes.dashboard, AppRoutes.checkIn,
                AppRoutes.aiChat,    AppRoutes.diet,
                AppRoutes.hospital,
              ];
              if (i < routes.length) context.go(routes[i]);
            },
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(DietState diet) {
    final phaseLabel = diet.mealPlan?.phaseLabel.isNotEmpty == true
        ? diet.mealPlan!.phaseLabel
        : diet.phaseLabel;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077B6), Color(0xFF005f8e)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Diet Plan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dateRangeLabel(),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (phaseLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    phaseLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Day selector ──────────────────────────────────────────

  Widget _buildDaySelector() {
    return Container(
      color: const Color(0xFF1A2333),
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 7,
        itemBuilder: (_, i) {
          final date     = _weekStart.add(Duration(days: i));
          final selected = _isSameDay(date, _selectedDate);
          return _buildDayChip(date, i, selected);
        },
      ),
    );
  }

  Widget _buildDayChip(DateTime date, int weekdayIndex, bool selected) {
    return GestureDetector(
      onTap: () => _selectDay(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : const Color(0xFF2A3347),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _kDayNames[weekdayIndex],
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body dispatcher ───────────────────────────────────────

  Widget _buildBody(DietState diet, PatientProfile profile) {
    if (profile.surgeryType.isEmpty) return _buildSetupPrompt();
    if (diet.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kPrimary),
            SizedBox(height: 16),
            Text('Building your AI meal plan…',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      );
    }
    if (diet.errorMessage.isNotEmpty) return _buildError(diet);
    if (diet.mealPlan == null) {
      return const Center(
        child: Text('No meal plan loaded.',
            style: TextStyle(color: Colors.white54)),
      );
    }
    return _buildPlanContent(diet, profile);
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥗', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text('Complete your profile first',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Your diet plan is personalised by surgery type and recovery day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SalamaButton(
              label: 'Set Up Profile →',
              onTap: () => context.go(AppRoutes.profileSetup),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(DietState diet) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(diet.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 20),
            SalamaButton(
              label: 'Try Again',
              onTap: () {
                ref.read(dietProvider.notifier).clearError();
                _loadForDate(_selectedDate);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Plan content ──────────────────────────────────────────

  Widget _buildPlanContent(DietState diet, PatientProfile profile) {
    final plan = diet.mealPlan!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recovery context info strip
          _buildContextStrip(profile, diet),
          const SizedBox(height: 12),

          // Daily macro targets
          _buildMacroCard(plan),
          const SizedBox(height: 14),

          // AI tip (from Gemini, specific to surgery+phase)
          if (diet.aiTip.isNotEmpty) ...[
            _buildAiTip(diet.aiTip),
            const SizedBox(height: 14),
          ],

          // Meal cards — one per meal type in order
          for (final mealType in _kMealOrder)
            if (plan.meals.containsKey(mealType)) ...[
              _buildMealCard(
                mealType: mealType,
                meal: plan.meals[mealType]!,
                plan: plan,
                profile: profile,
              ),
              const SizedBox(height: 12),
            ],

          // Foods to avoid — from Kenya MOH rules (legacy section, retained)
          if (diet.avoidList.isNotEmpty) ...[
            _buildAvoidSection(diet.avoidList),
            const SizedBox(height: 12),
          ],

          // Source citation
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 11, color: Colors.white24),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Kenya National Clinical Nutrition Manual (MOH 2010)',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Context strip (surgery + day) ─────────────────────────

  Widget _buildContextStrip(PatientProfile profile, DietState diet) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = _selectedDate.difference(todayDate).inDays;
    final displayDay = profile.daysSinceSurgery + diff;

    return Row(
      children: [
        _contextChip(
          Icons.medical_services_outlined,
          profile.surgeryType.isNotEmpty
              ? profile.surgeryType
              : 'Surgery type',
          _kPrimary,
        ),
        const SizedBox(width: 8),
        _contextChip(
          Icons.today_outlined,
          'Day $displayDay of recovery',
          _kGreen,
        ),
      ],
    );
  }

  Widget _contextChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Macro summary card ────────────────────────────────────

  Widget _buildMacroCard(MealPlan plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Targets',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              _macroStat('🔥', '${plan.targetKcal}', 'kcal', _kPrimary),
              _macroStat(
                  '💪', '${plan.targetProteinG.toInt()}g', 'Protein', _kGreen),
              _macroStat(
                  '🌾', '${plan.targetCarbsG.toInt()}g', 'Carbs', _kAmber),
              _macroStat(
                  '🥑', '${plan.targetFatG.toInt()}g', 'Fat', _kPurple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroStat(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }

  // ── AI Tip banner ─────────────────────────────────────────

  Widget _buildAiTip(String tip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip,
                style: const TextStyle(color: _kGreen, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Meal card ──────────────────────────────────────────────

  Widget _buildMealCard({
    required String mealType,
    required MealDetail meal,
    required MealPlan plan,
    required PatientProfile profile,
  }) {
    final icon  = _kMealIcons[mealType]  ?? '🍽️';
    final label = _kMealLabels[mealType] ?? mealType;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ──
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const Spacer(),
              _scoreBadge(meal.score),
            ],
          ),
          const SizedBox(height: 10),

          // ── meal name + description ──
          Text(meal.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          if (meal.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meal.description,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],

          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 10),

          // ── food items with per-item macros ──
          ...meal.items.map(_buildItemRow),

          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 10),

          // ── meal totals ──
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              _macroChip('${meal.totalCalories}', 'cal', _kPrimary),
              const SizedBox(width: 4),
              _macroChip('${meal.totalProteinG.toInt()}g', 'P', _kGreen),
              const SizedBox(width: 4),
              _macroChip('${meal.totalCarbsG.toInt()}g', 'C', _kAmber),
              const SizedBox(width: 4),
              _macroChip('${meal.totalFatG.toInt()}g', 'F', _kPurple),
            ],
          ),

          const SizedBox(height: 14),

          // ── change meal button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showChangeMealSheet(
                context: context,
                mealType: mealType,
                meal: meal,
                plan: plan,
                profile: profile,
              ),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Change Meal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(MealItemDetail item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('•',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.name,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          _tinyChip('${item.calories}cal'),
          const SizedBox(width: 3),
          _tinyChip('P${item.proteinG.toInt()}g'),
          const SizedBox(width: 3),
          _tinyChip('C${item.carbsG.toInt()}g'),
          const SizedBox(width: 3),
          _tinyChip('F${item.fatG.toInt()}g'),
        ],
      ),
    );
  }

  // ── Shared widget helpers ──────────────────────────────────

  Widget _scoreBadge(int score) {
    final color =
        score >= 8 ? _kGreen : score >= 5 ? _kAmber : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text('$score/10',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _macroChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$value $label',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _tinyChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _kChip,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white54, fontSize: 9)),
    );
  }

  // ── Foods to Avoid section (from MOH rules) ──────────────

  Widget _buildAvoidSection(List<String> avoidList) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRed.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🚫', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 4),
                    Text('Avoid During Recovery',
                        style: TextStyle(
                            color: _kRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...avoidList.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: _kRed, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Change meal sheet launcher ────────────────────────────

  void _showChangeMealSheet({
    required BuildContext context,
    required String mealType,
    required MealDetail meal,
    required MealPlan plan,
    required PatientProfile profile,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeMealSheet(
        mealType: mealType,
        meal: meal,
        plan: plan,
        profile: profile,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Change Meal Bottom Sheet
// Two-stage: (1) preference input → (2) 5 AI alternatives
// ─────────────────────────────────────────────────────────────

class _ChangeMealSheet extends ConsumerStatefulWidget {
  final String mealType;
  final MealDetail meal;
  final MealPlan plan;
  final PatientProfile profile;

  const _ChangeMealSheet({
    required this.mealType,
    required this.meal,
    required this.plan,
    required this.profile,
  });

  @override
  ConsumerState<_ChangeMealSheet> createState() => _ChangeMealSheetState();
}

class _ChangeMealSheetState extends ConsumerState<_ChangeMealSheet> {
  final _prefCtrl = TextEditingController();
  bool _showingAlternatives = false;

  @override
  void dispose() {
    _prefCtrl.dispose();
    super.dispose();
  }

  String get _label => _kMealLabels[widget.mealType] ?? widget.mealType;

  Future<void> _getAlternatives() async {
    final allergies = [
      ...widget.profile.allergies,
      if (widget.profile.otherAllergies.isNotEmpty)
        widget.profile.otherAllergies,
    ];
    await ref.read(dietProvider.notifier).fetchAlternatives(
          mealName: widget.meal.name,
          mealType: widget.mealType,
          preferenceText: _prefCtrl.text,
          surgeryType: widget.profile.surgeryType,
          day: widget.profile.daysSinceSurgery,
          allergies: allergies,
        );
    if (mounted) setState(() => _showingAlternatives = true);
  }

  void _acceptAlternative(MealAlternative alt) {
    ref.read(dietProvider.notifier).acceptAlternative(widget.mealType, alt);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final diet = ref.watch(dietProvider);
    return DraggableScrollableSheet(
      initialChildSize: _showingAlternatives ? 0.85 : 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _showingAlternatives
                    ? _buildAlternativesView(diet)
                    : _buildInputView(diet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stage 1: preference input ─────────────────────────────

  Widget _buildInputView(DietState diet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Change $_label',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Current: ${widget.meal.name}',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 20),

        const Text('What would you like instead?',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _prefCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. "Something lighter", "No fish", "More protein"…',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF2A3347),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: diet.isLoadingAlternatives ? null : _getAlternatives,
            icon: diet.isLoadingAlternatives
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('✨', style: TextStyle(fontSize: 16)),
            label: Text(
              diet.isLoadingAlternatives
                  ? 'Getting alternatives…'
                  : 'Get 5 Alternatives',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        if (diet.alternativesError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(diet.alternativesError,
              style: const TextStyle(color: _kRed, fontSize: 12)),
        ],
      ],
    );
  }

  // ── Stage 2: 5 alternatives ───────────────────────────────

  Widget _buildAlternativesView(DietState diet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(dietProvider.notifier).clearAlternatives();
                setState(() => _showingAlternatives = false);
              },
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios, color: Colors.white54, size: 14),
                  SizedBox(width: 4),
                  Text('Back',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Choose a $_label Alternative',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (diet.alternatives.isEmpty)
          const Center(
            child: Text('No alternatives found.',
                style: TextStyle(color: Colors.white54)),
          )
        else
          ...diet.alternatives.map(_buildAlternativeCard),
      ],
    );
  }

  Widget _buildAlternativeCard(MealAlternative alt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3347),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(alt.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${alt.rating}/10',
                    style: const TextStyle(
                        color: _kGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (alt.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(alt.description,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _altChip('${alt.totalCalories}cal', _kPrimary),
              const SizedBox(width: 4),
              _altChip('P${alt.totalProteinG.toInt()}g', _kGreen),
              const SizedBox(width: 4),
              _altChip('C${alt.totalCarbsG.toInt()}g', _kAmber),
              const SizedBox(width: 4),
              _altChip('F${alt.totalFatG.toInt()}g', _kPurple),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _acceptAlternative(alt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Accept',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _altChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
