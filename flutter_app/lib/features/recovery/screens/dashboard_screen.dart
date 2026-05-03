import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/recovery_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final recovery = ref.watch(recoveryProvider);
    final day = profile.daysSinceSurgery;
    final totalDays = _totalDays(profile.surgeryType);
    final progress = (day / totalDays.clamp(1, 999) * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (recovery.hasWarning)
            EmergencyBanner(
              message: recovery.warningMessage.isNotEmpty
                  ? recovery.warningMessage
                  : 'Monitor wound site — rest today.',
              onCall: () => context.go(AppRoutes.hospital),
            ),

          // ── Header ──
          Container(
            color: AppColors.surface,
            child: SafeArea(
              top: !recovery.hasWarning,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi ${profile.name.split(' ').first.isNotEmpty ? profile.name.split(' ').first : 'there'}! 🌟',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Day $day of your recovery 💕',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // Settings gear
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.settings),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.settings_outlined,
                                color: AppColors.textSecondary, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$progress% Completed',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text('$day of $totalDays days',
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage card
                  _StageCard(day: day),
                  const SizedBox(height: 12),

                  // Activities — two columns
                  _ActivitiesCard(day: day),
                  const SizedBox(height: 12),

                  // Today's meals
                  _MealsPreview(day: day, onTap: () => context.go(AppRoutes.diet)),
                  const SizedBox(height: 12),

                  // AI tip
                  _AiTipCard(
                    tip: recovery.aiTip.isNotEmpty
                        ? recovery.aiTip
                        : _defaultTip(day),
                    onChat: () => context.go(AppRoutes.aiChat),
                  ),
                  const SizedBox(height: 12),

                  // Mental health check-in card
                  _MentalHealthCard(
                    onTap: () => context.go(AppRoutes.mentalHealth),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          SalamaBottomNav(
            currentIndex: 0,
            onTap: (i) {
              final routes = [
                AppRoutes.dashboard,
                AppRoutes.diet,
                AppRoutes.checkIn,
                AppRoutes.aiChat,
                AppRoutes.hospital,
              ];
              if (i < routes.length) context.go(routes[i]);
            },
          ),
        ],
      ),
    );
  }

  int _totalDays(String surgeryType) {
    const map = {
      'Caesarean Section': 42, 'Appendectomy': 21,
      'Hernia Repair': 21, 'Cholecystectomy': 28,
      'Knee Replacement': 90, 'Hip Replacement': 90,
      'Laparotomy': 42, 'Hysterectomy': 42,
      'Open Fracture Repair': 84, 'Cardiac Surgery': 180,
    };
    return map[surgeryType] ?? 42;
  }

  String _defaultTip(int day) {
    if (day <= 2) return 'Rest is the best medicine right now. Sip water regularly and take your prescribed pain medication on schedule.';
    if (day <= 7) return 'Short 5-minute walks improve blood flow and speed healing. Avoid lifting anything heavier than a phone.';
    if (day <= 14) return 'Your wound is closing well. Keep it clean and dry. Eat protein-rich foods like eggs and beans.';
    if (day <= 30) return 'Strength returns slowly — don\'t rush it. Eat balanced meals and stay well hydrated.';
    return 'You are in the final stretch of recovery. Resume activities gradually and celebrate your progress!';
  }
}

class _StageCard extends StatelessWidget {
  final int day;
  const _StageCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final stage = _stage(day);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(stage['badge']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                Text(stage['name']!,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(stage['desc']!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('🌿', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }

  Map<String, String> _stage(int day) {
    if (day <= 2) return {'badge': 'STAGE 1', 'name': 'Immediate Post-Op', 'desc': 'Rest is critical. Clear liquids only.\nPain management is the priority.'};
    if (day <= 7) return {'badge': 'STAGE 2', 'name': 'Early Healing Stage', 'desc': 'Take it slow today — rest and light\nmovement will help your body heal.'};
    if (day <= 14) return {'badge': 'STAGE 3', 'name': 'Active Recovery', 'desc': 'Pain is decreasing. Gradually increase\nactivity and normal diet.'};
    if (day <= 30) return {'badge': 'STAGE 4', 'name': 'Strengthening', 'desc': 'Near-normal activity levels.\nContinue healthy eating.'};
    return {'badge': 'STAGE 5', 'name': 'Full Recovery', 'desc': 'Resume normal activities gradually.\nSchedule your final follow-up.'};
  }
}

class _ActivitiesCard extends StatelessWidget {
  final int day;
  const _ActivitiesCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final allowed = _allowed(day);
    final restricted = _restricted(day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What you can do today',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ...allowed.map((a) => _row(a, true)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, color: AppColors.border),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('Try to avoid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    SizedBox(width: 4),
                    _Badge(count: 3),
                  ],
                ),
                const SizedBox(height: 8),
                ...restricted.map((r) => _row(r, false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String text, bool ok) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 14,
              color: ok ? AppColors.primary : AppColors.emergency,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ),
          ],
        ),
      );

  List<String> _allowed(int day) {
    if (day <= 2) return ['Bed rest', 'Deep breathing', 'Sipping water'];
    if (day <= 7) return ['Light walking', 'Sitting upright', 'Drinking fluids'];
    if (day <= 14) return ['Walks 15 min', 'Light housework', 'Gentle stretching'];
    return ['Moderate exercise', 'Daily activities', 'Driving (if well)'];
  }

  List<String> _restricted(int day) {
    if (day <= 7) return ['Heavy lifting', 'Running', 'Bending'];
    if (day <= 14) return ['Lifting >5 kg', 'Strenuous exercise', 'Swimming'];
    if (day <= 30) return ['Heavy lifting', 'High-impact sports'];
    return ['Extreme sports'];
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.emergency.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$count',
          style: const TextStyle(
              color: AppColors.emergency,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _MealsPreview extends StatelessWidget {
  final int day;
  final VoidCallback onTap;
  const _MealsPreview({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = _chips(day);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s meals',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: onTap,
                child: const Text('See full plan',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items
                  .map((item) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item['icon']!,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(item['name']!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _chips(int day) {
    if (day <= 2) return [{'icon': '☕', 'name': 'Tea'}, {'icon': '🍲', 'name': 'Broth'}, {'icon': '💧', 'name': 'Water'}];
    if (day <= 4) return [{'icon': '🥣', 'name': 'Uji'}, {'icon': '🥛', 'name': 'Maziwa'}, {'icon': '💧', 'name': 'Water'}];
    return [{'icon': '🫓', 'name': 'Ugali'}, {'icon': '🌿', 'name': 'Sukuma Wiki'}, {'icon': '💧', 'name': 'Water 2.5L'}];
  }
}

class _MentalHealthCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MentalHealthCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💜 Mental Health Check-In',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    "How are you feeling emotionally today?\nIt's okay to not be okay.",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Check In Now →',
                        style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('🌸', style: TextStyle(fontSize: 44)),
          ],
        ),
      ),
    );
  }
}

class _AiTipCard extends StatelessWidget {
  final String tip;
  final VoidCallback onChat;
  const _AiTipCard({required this.tip, required this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Tip for Today',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(tip,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.6)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onChat,
                  child: const Text('Ask AI Assistant →',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
