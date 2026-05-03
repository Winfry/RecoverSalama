import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/diet_provider.dart';

// ── Design tokens ────────────────────────────────────────────
const _kPrimary  = AppColors.primary;
const _kGreen    = Color(0xFF22C55E);
const _kAmber    = Color(0xFFFFB703);
const _kRed      = Color(0xFFEF4444);

const _kMealBg = {
  'breakfast': Color(0xFFFFF8E7),
  'lunch':     Color(0xFFEDF7ED),
  'dinner':    Color(0xFFF5F0FF),
  'snack':     Color(0xFFE3F2FD),
};
const _kMealAccent = {
  'breakfast': Color(0xFFFFB703),
  'lunch':     Color(0xFF22C55E),
  'dinner':    Color(0xFF8B5CF6),
  'snack':     Color(0xFF3B82F6),
};
const _kMealIcons  = {'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍎'};
const _kMealLabels = {'breakfast': 'Breakfast', 'lunch': 'Lunch', 'dinner': 'Dinner', 'snack': 'Snack'};
const _kMealOrder  = ['breakfast', 'lunch', 'dinner', 'snack'];

// Popular Kenya recovery foods (tappable chips)
const _kPopularFoods = [
  {'emoji': '🍚', 'name': 'Ugali'},
  {'emoji': '🫘', 'name': 'Beans'},
  {'emoji': '🍌', 'name': 'Banana'},
  {'emoji': '🥛', 'name': 'Milk'},
  {'emoji': '🥑', 'name': 'Avocado'},
  {'emoji': '🫓', 'name': 'Chapati'},
  {'emoji': '🥚', 'name': 'Eggs'},
  {'emoji': '🌿', 'name': 'Sukuma Wiki'},
  {'emoji': '🍅', 'name': 'Tomato'},
  {'emoji': '🍊', 'name': 'Orange'},
  {'emoji': '🐟', 'name': 'Fish'},
  {'emoji': '🍗', 'name': 'Chicken'},
];

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
    _weekStart    = now.subtract(Duration(days: now.weekday - 1));
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  // ── Helpers ───────────────────────────────────────────────

  void _generatePlan() {
    final profile = ref.read(profileProvider);
    if (profile.surgeryType.isEmpty) {
      context.go(AppRoutes.profileSetup);
      return;
    }
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = _selectedDate.difference(todayDate).inDays;
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

  void _addIngredient(String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    ref.read(dietProvider.notifier).addPantryItem(trimmed);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _selectDay(DateTime date) {
    if (_isSameDay(date, _selectedDate)) return;
    setState(() => _selectedDate = date);
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final diet    = ref.watch(dietProvider);
    final profile = ref.watch(profileProvider);
    final hasPlan = diet.mealPlan != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero illustration + heading
                  _buildHero(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // Section 1: Ingredient input
                        _buildIngredientsSection(diet),
                        const SizedBox(height: 16),

                        // Popular foods horizontal scroll
                        _buildPopularFoods(diet),
                        const SizedBox(height: 16),

                        // CTA button
                        _buildCreatePlanCTA(diet),
                        const SizedBox(height: 20),

                        // Week overview strip
                        _buildWeekOverview(),
                        const SizedBox(height: 20),

                        // Meal plan results (only when loaded)
                        if (diet.isLoading)
                          _buildGeneratingState()
                        else if (hasPlan) ...[
                          _buildMealsSection(diet, profile),
                          const SizedBox(height: 16),
                          _buildWhyItWorks(diet),
                          const SizedBox(height: 16),
                          _buildActionRow(diet, profile),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SalamaBottomNav(
            currentIndex: 1,
            onTap: (i) {
              final routes = [
                AppRoutes.dashboard, AppRoutes.diet,
                AppRoutes.checkIn,   AppRoutes.aiChat,
                AppRoutes.hospital,
              ];
              if (i < routes.length) context.go(routes[i]);
            },
          ),
        ],
      ),
    );
  }

  // ── Header bar ────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.dashboard),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 22, color: AppColors.textPrimary),
              ),
              const Expanded(
                child: Text(
                  'Weekly Diet Plan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F9F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text content
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Let's plan today's\nmeals together 🍳",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.25),
                ),
                SizedBox(height: 6),
                Text(
                  "Tell us what you have, and we'll create recovery-friendly meals just for you.",
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Illustration placeholder — chef with vegetables
          SizedBox(
            width: 100,
            height: 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Backdrop circle
                Positioned(
                  bottom: 0, left: 5, right: 5,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(50)),
                    ),
                  ),
                ),
                // Chef emoji (centred)
                const Positioned(
                  bottom: 4,
                  left: 0, right: 0,
                  child: Text('👩🏾‍🍳',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 52)),
                ),
                // Leaf accent
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🌿',
                        style: TextStyle(fontSize: 14)),
                  ),
                ),
                // Veggie accent
                Positioned(
                  top: 20, left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _kAmber.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🥕',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 1: Ingredients ────────────────────────────────

  Widget _buildIngredientsSection(DietState diet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. What do you have at home today?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('Add ingredients you have available',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showTipsSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kAmber.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 4),
                    Text('Tips',
                        style: TextStyle(
                            color: _kAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Ingredient chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...diet.pantryItems.map((item) => _ingredientChip(item)),
              // "+ Add more" button
              GestureDetector(
                onTap: () => _showAddIngredientsSheet(diet),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _kPrimary.withOpacity(0.3),
                        style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: _kPrimary),
                      const SizedBox(width: 4),
                      const Text('Add more',
                          style: TextStyle(
                              color: _kPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ingredientChip(String item) {
    // Emoji lookup
    final emoji = _kPopularFoods.firstWhere(
            (f) => (f['name'] as String).toLowerCase() == item.toLowerCase(),
            orElse: () => {'emoji': '🥄', 'name': item})['emoji'] as String;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(item,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () =>
                ref.read(dietProvider.notifier).removePantryItem(item),
            child: const Icon(Icons.close_rounded,
                size: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ── Popular foods ─────────────────────────────────────────

  Widget _buildPopularFoods(DietState diet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Popular foods near you',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            GestureDetector(
              onTap: () => _showAddIngredientsSheet(diet),
              child: const Text('Tap to add',
                  style: TextStyle(
                      fontSize: 11,
                      color: _kPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kPopularFoods.map((food) {
              final name = food['name'] as String;
              final emoji = food['emoji'] as String;
              final added = diet.pantryItems.any(
                  (i) => i.toLowerCase() == name.toLowerCase());
              return GestureDetector(
                onTap: added
                    ? null
                    : () => _addIngredient(name),
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: added
                        ? AppColors.primaryLight
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: added
                          ? _kPrimary.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 5),
                      Text(name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: added
                                  ? _kPrimary
                                  : AppColors.textPrimary)),
                      if (added)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle_rounded,
                              size: 11, color: _kPrimary),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Create meal plan CTA ──────────────────────────────────

  Widget _buildCreatePlanCTA(DietState diet) {
    return GestureDetector(
      onTap: diet.isLoading ? null : _generatePlan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B494), Color(0xFF00C896)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _kPrimary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: diet.isLoading
            ? const Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              )
            : Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✨ ',
                          style: TextStyle(fontSize: 16)),
                      Text('Create my meal plan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    diet.mealPlan == null
                        ? 'AI will generate meals for your recovery needs'
                        : 'Tap to regenerate with current ingredients',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Week overview ─────────────────────────────────────────

  Widget _buildWeekOverview() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WEEKLY OVERVIEW',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                      letterSpacing: 0.8)),
              GestureDetector(
                onTap: () {},
                child: const Text('View full week',
                    style: TextStyle(
                        fontSize: 10,
                        color: _kPrimary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = _weekStart.add(Duration(days: i));
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final isPast = date.isBefore(DateTime.now()) && !isToday;
              return GestureDetector(
                onTap: () => _selectDay(date),
                child: Column(
                  children: [
                    Text(days[i],
                        style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? _kPrimary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400)),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: _kPrimary, width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: isPast && !isSelected
                            ? const Icon(Icons.check_rounded,
                                size: 13, color: _kGreen)
                            : Text('${date.day}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                            ? _kPrimary
                                            : AppColors
                                                .textSecondary)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Generating state ──────────────────────────────────────

  Widget _buildGeneratingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text('🍲',
              style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Creating your meal plan…',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('This may take a few seconds',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...[
            'Analyzing ingredients',
            'Checking nutrition needs',
            'Creating balanced meals',
            'Almost done!',
          ].asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: _kPrimary),
                    const SizedBox(width: 10),
                    Text(e.value,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Section 3: Meal cards ─────────────────────────────────

  Widget _buildMealsSection(DietState diet, PatientProfile profile) {
    final plan = diet.mealPlan!;
    final meals = _kMealOrder
        .where((k) => plan.meals.containsKey(k))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('3. Your recommended meals for today',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Personalized for you',
                  style: TextStyle(
                      fontSize: 9,
                      color: _kGreen,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal scroll of meal cards
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            itemBuilder: (_, i) => _buildMealCard(
              mealType: meals[i],
              meal: plan.meals[meals[i]]!,
              profile: profile,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required String mealType,
    required MealDetail meal,
    required PatientProfile profile,
  }) {
    final bg     = _kMealBg[mealType]     ?? Colors.white;
    final accent = _kMealAccent[mealType] ?? _kPrimary;
    final icon   = _kMealIcons[mealType]  ?? '🍽️';
    final label  = _kMealLabels[mealType] ?? mealType;

    // Derive nutrient badge from meal score / name
    final badgeInfo = _mealBadge(mealType, meal.score);

    return GestureDetector(
      onTap: () => _showSwapSheet(mealType, meal, profile),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal type tag
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w600)),
            ),
            // Meal name
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2)),
            ),
            // Description
            if (meal.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
                child: Text(meal.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ),
            // Food illustration (emoji in circle)
            Expanded(
              child: Center(
                child: Text(icon,
                    style: const TextStyle(fontSize: 40)),
              ),
            ),
            // Nutrient badge
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(badgeInfo['icon'] as String,
                        style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(badgeInfo['text'] as String,
                          style: TextStyle(
                              fontSize: 9,
                              color: accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _mealBadge(String mealType, int score) {
    final badges = {
      'breakfast': {'icon': '⭐', 'text': 'High in Protein'},
      'lunch':     {'icon': '🌿', 'text': 'Iron + Fibre'},
      'dinner':    {'icon': '💜', 'text': 'Easy to Digest'},
      'snack':     {'icon': '⚡', 'text': 'Quick Energy'},
    };
    return (badges[mealType] ?? {'icon': '✅', 'text': 'Balanced'})
        .cast<String, String>();
  }

  // ── Section 4: Why it works ───────────────────────────────

  Widget _buildWhyItWorks(DietState diet) {
    final reasons = [
      {'emoji': '💪', 'text': 'Protein helps repair tissues and build strength'},
      {'emoji': '💚', 'text': 'Iron supports blood recovery and energy'},
      {'emoji': '💧', 'text': 'Fluids keep you hydrated and prevent fatigue'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('4. Why this works for your recovery',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            GestureDetector(
              onTap: () {},
              child: const Text('Learn more',
                  style: TextStyle(
                      fontSize: 11,
                      color: _kPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: reasons.map((r) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['emoji']!,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(r['text']!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // AI tip if present
        if (diet.aiTip.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F9F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🤖',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(diet.aiTip,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Action row ────────────────────────────────────────────

  Widget _buildActionRow(DietState diet, PatientProfile profile) {
    return Row(
      children: [
        _actionBtn(
          Icons.bookmark_border_rounded,
          'Save Plan',
          onTap: () => _savePlan(),
          outlined: true,
        ),
        const SizedBox(width: 8),
        _actionBtn(
          Icons.refresh_rounded,
          'Regenerate',
          onTap: diet.isLoading ? null : _generatePlan,
          outlined: true,
        ),
        const SizedBox(width: 8),
        _actionBtn(
          Icons.swap_horiz_rounded,
          'Swap a Meal',
          onTap: () => _showMealPickerForSwap(diet, profile),
          outlined: true,
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label,
      {VoidCallback? onTap, bool outlined = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: _kPrimary),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheet launchers ───────────────────────────────────────

  void _savePlan() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅  Meal plan saved!'),
      backgroundColor: Color(0xFF22C55E),
      duration: Duration(seconds: 2),
    ));
  }

  void _showTipsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡  Recovery Meal Tips',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...const [
              '• Add at least 1 protein source each meal (eggs, beans, meat)',
              '• Include leafy greens for iron – sukuma wiki, spinach',
              '• Drink 8+ glasses of water daily to help your wound heal',
              '• Small frequent meals are better than large ones post-surgery',
              '• Avoid spicy, fatty or fried foods for the first 2 weeks',
            ].map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(t,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5)),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddIngredientsSheet(DietState diet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddIngredientsSheet(
        currentItems: diet.pantryItems,
        onAdd: _addIngredient,
        onRemove: (item) =>
            ref.read(dietProvider.notifier).removePantryItem(item),
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  void _showSwapSheet(
      String mealType, MealDetail meal, PatientProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeMealSheet(
        mealType: mealType,
        meal: meal,
        profile: profile,
      ),
    );
  }

  void _showMealPickerForSwap(DietState diet, PatientProfile profile) {
    final plan = diet.mealPlan;
    if (plan == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Which meal do you want to swap?',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ..._kMealOrder
                .where((k) => plan.meals.containsKey(k))
                .map((mealType) {
              final meal = plan.meals[mealType]!;
              final accent = _kMealAccent[mealType] ?? _kPrimary;
              final icon   = _kMealIcons[mealType]  ?? '🍽️';
              return ListTile(
                leading: Text(icon,
                    style: const TextStyle(fontSize: 24)),
                title: Text(_kMealLabels[mealType] ?? mealType,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(meal.name,
                    style: const TextStyle(fontSize: 11)),
                trailing: Icon(Icons.swap_horiz_rounded,
                    color: accent, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  _showSwapSheet(mealType, meal, profile);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add Ingredients Bottom Sheet
// ─────────────────────────────────────────────────────────────

class _AddIngredientsSheet extends StatefulWidget {
  final List<String> currentItems;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onDone;

  const _AddIngredientsSheet({
    required this.currentItems,
    required this.onAdd,
    required this.onRemove,
    required this.onDone,
  });

  @override
  State<_AddIngredientsSheet> createState() => _AddIngredientsSheetState();
}

class _AddIngredientsSheetState extends State<_AddIngredientsSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late List<String> _current;

  @override
  void initState() {
    super.initState();
    _current = List.from(widget.currentItems);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filtered {
    final q = _query.toLowerCase();
    return q.isEmpty
        ? _kPopularFoods.cast<Map<String, String>>()
        : _kPopularFoods
            .where((f) => (f['name'] as String)
                .toLowerCase()
                .contains(q))
            .cast<Map<String, String>>()
            .toList();
  }

  void _toggle(String name) {
    setState(() {
      if (_current.any((i) => i.toLowerCase() == name.toLowerCase())) {
        _current.removeWhere(
            (i) => i.toLowerCase() == name.toLowerCase());
        widget.onRemove(name);
      } else {
        _current.add(name);
        widget.onAdd(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add ingredients',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          // Your ingredients chips
          if (_current.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your ingredients',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _current.map((item) {
                      final emoji = _kPopularFoods.firstWhere(
                              (f) =>
                                  (f['name'] as String).toLowerCase() ==
                                  item.toLowerCase(),
                              orElse: () =>
                                  {'emoji': '🥄', 'name': item})[
                              'emoji'] as String;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary
                                  .withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji,
                                style:
                                    const TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            Text(item,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _toggle(item),
                              child: const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search ingredient…',
                hintStyle: const TextStyle(
                    color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('All ingredients',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          // Ingredient list
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final food = _filtered[i];
                final name = food['name']!;
                final emoji = food['emoji']!;
                final added = _current.any(
                    (item) => item.toLowerCase() == name.toLowerCase());
                return ListTile(
                  leading: Text(emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  trailing: GestureDetector(
                    onTap: () => _toggle(name),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: added
                            ? AppColors.primaryLight
                            : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: added
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        added
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        size: 16,
                        color: added
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Done button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).padding.bottom + 8),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _current.isEmpty
                      ? 'Done'
                      : 'Done (${_current.length})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Swap Meal Bottom Sheet
// ─────────────────────────────────────────────────────────────

class _ChangeMealSheet extends ConsumerStatefulWidget {
  final String mealType;
  final MealDetail meal;
  final PatientProfile profile;

  const _ChangeMealSheet({
    required this.mealType,
    required this.meal,
    required this.profile,
  });

  @override
  ConsumerState<_ChangeMealSheet> createState() =>
      _ChangeMealSheetState();
}

class _ChangeMealSheetState extends ConsumerState<_ChangeMealSheet> {
  final _prefCtrl = TextEditingController();
  bool _showingAlternatives = false;

  @override
  void dispose() {
    _prefCtrl.dispose();
    super.dispose();
  }

  String get _label =>
      _kMealLabels[widget.mealType] ?? widget.mealType;
  Color get _accent =>
      _kMealAccent[widget.mealType] ?? _kPrimary;

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

  void _accept(MealAlternative alt) {
    ref.read(dietProvider.notifier)
        .acceptAlternative(widget.mealType, alt);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final diet = ref.watch(dietProvider);
    return DraggableScrollableSheet(
      initialChildSize: _showingAlternatives ? 0.80 : 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 2),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _showingAlternatives
                    ? _buildAlternatives(diet)
                    : _buildInput(diet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(DietState diet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_kMealIcons[widget.mealType] ?? '🍽️',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Swap $_label',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text('Current: ${widget.meal.name}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Choose a new $_label option',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _prefCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText:
                'e.g. "Something lighter", "No fish", "More iron"…',
            hintStyle: const TextStyle(
                color: AppColors.textHint, fontSize: 12),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed:
                diet.isLoadingAlternatives ? null : _getAlternatives,
            icon: diet.isLoadingAlternatives
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('✨',
                    style: TextStyle(fontSize: 16)),
            label: Text(
              diet.isLoadingAlternatives
                  ? 'Getting options…'
                  : 'Get 3 Options',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (diet.alternativesError.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(diet.alternativesError,
              style: const TextStyle(color: _kRed, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildAlternatives(DietState diet) {
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
                  Icon(Icons.arrow_back_ios_rounded,
                      size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 2),
                  Text('Back',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('Swap $_label',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            Text('· Choose a new option',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 14),
        if (diet.alternatives.isEmpty)
          const Center(
              child: Text('No alternatives found.',
                  style: TextStyle(color: AppColors.textSecondary)))
        else
          ...diet.alternatives.asMap().entries.map((e) {
            final alt = e.value;
            final optNum = e.key + 1;
            final emoji = _kMealIcons[widget.mealType] ?? '🍽️';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Food visual
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Option $optNum',
                            style: TextStyle(
                                fontSize: 9,
                                color: _accent,
                                fontWeight: FontWeight.w700)),
                        Text(alt.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        if (alt.description.isNotEmpty)
                          Text(alt.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _miniChip(
                                '${alt.totalCalories}cal', _kPrimary),
                            const SizedBox(width: 4),
                            _miniChip('${alt.totalProteinG.toInt()}g P',
                                _kGreen),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _accept(alt),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _kGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}
