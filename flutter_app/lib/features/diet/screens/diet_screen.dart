// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 08: Diet Guidance
// Kenya-local food recommendations from the Kenya National
// Clinical Nutrition Manual (MOH 2010). Personalised by
// surgery type, recovery day, and patient allergies.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/diet_provider.dart';

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  // "recommended" shows the foods to eat; "avoid" shows what to skip
  String _tab = 'recommended';

  @override
  void initState() {
    super.initState();
    // Load after the first frame so ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDiet());
  }

  void _loadDiet() {
    final profile = ref.read(profileProvider);
    if (profile.surgeryType.isEmpty) return;

    final allergies = [
      ...profile.allergies,
      if (profile.otherAllergies.isNotEmpty) profile.otherAllergies,
    ];

    ref.read(dietProvider.notifier).loadDietPlan(
          surgeryType: profile.surgeryType,
          daysSinceSurgery: profile.daysSinceSurgery,
          allergies: allergies,
        );
  }

  @override
  Widget build(BuildContext context) {
    final diet = ref.watch(dietProvider);
    final profile = ref.watch(profileProvider);

    final dayLabel = diet.currentDay > 0
        ? 'Day ${diet.currentDay}'
        : profile.daysSinceSurgery > 0
            ? 'Day ${profile.daysSinceSurgery}'
            : 'Recovery';

    final phaseLabel = diet.phaseLabel.isNotEmpty
        ? diet.phaseLabel
        : 'Personalised Nutrition';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Blue header ──────────────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Healing Foods for You Today',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Kenya-optimised recovery nutrition · $dayLabel',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        if (diet.phaseLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(phaseLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── AI Tip banner ────────────────────────────────
          Container(
            color: AppColors.successLight,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(
                          text: 'AI Tip: ',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20))),
                      TextSpan(
                          text: diet.aiTip.isNotEmpty
                              ? diet.aiTip
                              : 'Loading your personalised tip...',
                          style:
                              const TextStyle(color: Color(0xFF1B5E20))),
                    ]),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────
          Expanded(
            child: _buildBody(diet, profile),
          ),

          // ── Bottom nav — active on Diet (index 3) ────────
          SalamaBottomNav(
            currentIndex: 3,
            onTap: (i) {
              final routes = [
                AppRoutes.dashboard,
                AppRoutes.checkIn,
                AppRoutes.aiChat,
                AppRoutes.diet,
                AppRoutes.hospital,
              ];
              if (i < routes.length) context.go(routes[i]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DietState diet, dynamic profile) {
    // ── No profile yet ───────────────────────────────────
    if (profile.surgeryType.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🥗',
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Complete your profile first',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Your diet plan is personalised based on your surgery type and recovery day.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SalamaButton(
                label: 'Set Up Profile →',
                onTap: () => context.go(AppRoutes.profileSetup),
              ),
            ],
          ),
        ),
      );
    }

    // ── Loading ──────────────────────────────────────────
    if (diet.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading your personalised diet...',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    // ── Error ────────────────────────────────────────────
    if (diet.errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️',
                  style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(diet.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              SalamaButton(
                label: 'Try Again',
                onTap: () {
                  ref.read(dietProvider.notifier).clearError();
                  _loadDiet();
                },
              ),
            ],
          ),
        ),
      );
    }

    // ── Data ─────────────────────────────────────────────
    return Column(
      children: [
        // Target calories + tab selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              // Calories badge
              if (diet.targetKcal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('🔥 Target: ${diet.targetKcal} kcal/day',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              const Spacer(),
              // Recommended / Avoid toggle
              _tabChip('✅ Recommended', 'recommended'),
              const SizedBox(width: 6),
              _tabChip('🚫 Avoid', 'avoid'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Food list
        Expanded(
          child: _tab == 'recommended'
              ? _buildFoodList(diet)
              : _buildAvoidList(diet),
        ),

        // MOH source citation
        if (diet.source.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(diet.source,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 10)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Recommended foods list ────────────────────────────────

  Widget _buildFoodList(DietState diet) {
    if (diet.foods.isEmpty) {
      return const Center(
        child: Text('No food recommendations available.',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: diet.foods.length + 1, // +1 for section header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _sectionHeader(
              '✅ Recommended for Day ${diet.currentDay}',
              AppColors.success);
        }
        final food = diet.foods[index - 1];
        return _foodRow(food, index - 1);
      },
    );
  }

  // ── Avoid list ────────────────────────────────────────────

  Widget _buildAvoidList(DietState diet) {
    if (diet.avoidList.isEmpty) {
      return const Center(
        child: Text('No restrictions for your current diet phase.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: diet.avoidList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _sectionHeader(
              '🚫 Avoid During Recovery', AppColors.emergency);
        }
        final item = diet.avoidList[index - 1];
        return Container(
          color: index % 2 == 0 ? Colors.white : const Color(0xFFF9F9F9),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.cancel_outlined,
                  color: AppColors.emergency, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _tabChip(String label, String value) {
    final active = _tab == value;
    return GestureDetector(
      onTap: () => setState(() => _tab = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.w400,
              color:
                  active ? Colors.white : AppColors.textPrimary,
            )),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      color: color,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14)),
    );
  }

  Widget _foodRow(FoodItem food, int index) {
    return Container(
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF9F9F9),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Text(food.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(food.benefit,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          if (food.calories > 0)
            Text('${food.calories} kcal',
                style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
