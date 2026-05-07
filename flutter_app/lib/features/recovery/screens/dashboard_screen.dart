// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 06: Recovery Dashboard
// Hero stage card with gender-aware illustration, two-column
// activity cards, circular meal items, and bell notification.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/dashboard_loader.dart';
import '../providers/recovery_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dashboardLoaderProvider);

    final profile = ref.watch(profileProvider);
    final recovery = ref.watch(recoveryProvider);
    final day = profile.daysSinceSurgery;
    final totalDays = _totalDays(profile.surgeryType);
    final progress =
        (day / totalDays.clamp(1, 999) * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Emergency banner — safety feature, must never be removed
          if (recovery.hasWarning)
            EmergencyBanner(
              message: recovery.warningMessage.isNotEmpty
                  ? recovery.warningMessage
                  : 'Monitor wound site — rest today.',
              onCall: () => context.go(AppRoutes.hospital),
            ),

          // ── Header ──────────────────────────────────────────
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
                          child: Text(
                            'Hi ${_firstName(profile.name)}! 🌻',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Bell with red notification dot
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: AppColors.textSecondary, size: 22),
                            ),
                            Positioned(
                              top: 7,
                              right: 9,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.emergency,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day $day of your recovery 🌸',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Progress row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$progress% Completed',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$day of $totalDays days',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
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

          // ── Scrollable content ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StageCard(day: day, gender: profile.gender),
                  const SizedBox(height: 12),
                  _ActivitiesRow(day: day),
                  const SizedBox(height: 16),
                  _MealsSection(
                    day: day,
                    onTap: () => context.go(AppRoutes.diet),
                  ),
                  const SizedBox(height: 16),
                  _AiTipCard(
                    tip: recovery.aiTip.isNotEmpty
                        ? recovery.aiTip
                        : _defaultTip(day),
                    onChat: () => context.go(AppRoutes.aiChat),
                  ),
                  const SizedBox(height: 12),
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

  String _firstName(String name) {
    final first = name.split(' ').first;
    return first.isNotEmpty ? first : 'there';
  }

  int _totalDays(String surgeryType) {
    const map = {
      'Caesarean Section': 42,
      'Appendectomy': 21,
      'Hernia Repair': 21,
      'Cholecystectomy': 28,
      'Knee Replacement': 90,
      'Hip Replacement': 90,
      'Laparotomy': 42,
      'Hysterectomy': 42,
      'Open Fracture Repair': 84,
      'Cardiac Surgery': 180,
    };
    return map[surgeryType] ?? 42;
  }

  String _defaultTip(int day) {
    if (day <= 2) {
      return 'Rest is the best medicine right now. Sip water regularly and take your prescribed pain medication on schedule.';
    }
    if (day <= 7) {
      return 'Short 5-minute walks improve blood flow and speed healing. Avoid lifting anything heavier than a phone.';
    }
    if (day <= 14) {
      return 'Your wound is closing well. Keep it clean and dry. Eat protein-rich foods like eggs and beans.';
    }
    if (day <= 30) {
      return "Strength returns slowly — don't rush it. Eat balanced meals and stay well hydrated.";
    }
    return 'You are in the final stretch of recovery. Resume activities gradually and celebrate your progress!';
  }
}

// ── Stage card — hero card with gender-aware illustration ─────
class _StageCard extends StatelessWidget {
  final int day;
  final String gender;
  const _StageCard({required this.day, required this.gender});

  @override
  Widget build(BuildContext context) {
    final stage = _stageData(day);
    // Female → woman emoji, Male → man emoji, Other/unknown → neutral
    final String figure = gender.toLowerCase() == 'female'
        ? '👩🏾'
        : gender.toLowerCase() == 'male'
            ? '👨🏾'
            : '🧑🏾';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Left content ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stage badge pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stage['badge']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Heart icon + title on same row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stage['name']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  stage['desc']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Plant decoration
                const Text('🌿', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Right — gender illustration ──────────────────────
          Text(figure, style: const TextStyle(fontSize: 80)),
        ],
      ),
    );
  }

  Map<String, String> _stageData(int day) {
    if (day <= 2) {
      return {
        'badge': 'STAGE 1 • IMMEDIATE POST-OP',
        'name': 'Rest is healing 💚',
        'desc':
            'Clear liquids only. Pain management is the priority right now.',
      };
    }
    if (day <= 7) {
      return {
        'badge': 'EARLY HEALING STAGE',
        'name': "You're doing well 💚",
        'desc':
            'Take it slow today — rest and light movement will help your body heal.',
      };
    }
    if (day <= 14) {
      return {
        'badge': 'ACTIVE RECOVERY STAGE',
        'name': 'Great progress 💪',
        'desc':
            'Pain is decreasing. Gradually increase activity and resume a normal diet.',
      };
    }
    if (day <= 30) {
      return {
        'badge': 'STRENGTHENING STAGE',
        'name': 'Getting stronger 🌟',
        'desc':
            'Near-normal activity levels. Continue healthy eating and stay hydrated.',
      };
    }
    return {
      'badge': 'FULL RECOVERY STAGE',
      'name': 'Almost there! 🎉',
      'desc':
          'Resume normal activities gradually. Schedule your final follow-up.',
    };
  }
}

// ── Two side-by-side activity cards ──────────────────────────
class _ActivitiesRow extends StatelessWidget {
  final int day;
  const _ActivitiesRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final allowed = _allowed(day);
    final restricted = _restricted(day);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left card — what you can do (white)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'What you can\ndo today',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${allowed.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...allowed.map((item) => _bullet(item, AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right card — try to avoid (light pink)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.emergency.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Try to avoid\nfor now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emergency.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${restricted.length}',
                        style: const TextStyle(
                          color: AppColors.emergency,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...restricted.map((item) => _bullet(item, AppColors.emergency)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text, Color dotColor) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    color: dotColor, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  List<String> _allowed(int day) {
    if (day <= 2) return ['Bed rest', 'Deep breathing', 'Sipping water'];
    if (day <= 7) return ['Light walking', 'Sitting upright', 'Drinking fluids'];
    if (day <= 14) {
      return ['Walks 15 min', 'Light housework', 'Gentle stretching'];
    }
    return ['Moderate exercise', 'Daily activities', 'Driving (if well)'];
  }

  List<String> _restricted(int day) {
    if (day <= 7) return ['Heavy lifting', 'Running', 'Bending'];
    if (day <= 14) return ['Lifting > 5 kg', 'Strenuous exercise', 'Swimming'];
    if (day <= 30) return ['Heavy lifting', 'High-impact sports', 'Overexertion'];
    return ['Extreme sports', 'Heavy lifting', 'Overexertion'];
  }
}

// ── Today's meals — circular food items ──────────────────────
class _MealsSection extends StatelessWidget {
  final int day;
  final VoidCallback onTap;
  const _MealsSection({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = _meals(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's meals",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: const Text(
                'See full plan',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items
                .map((item) => _MealCircle(
                      emoji: item['icon']!,
                      label: item['name']!,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _meals(int day) {
    if (day <= 2) {
      return [
        {'icon': '☕', 'name': 'Tea'},
        {'icon': '🍲', 'name': 'Broth'},
        {'icon': '💧', 'name': 'Water\n2.5L / 3L'},
      ];
    }
    if (day <= 4) {
      return [
        {'icon': '🥣', 'name': 'Uji'},
        {'icon': '🥛', 'name': 'Maziwa'},
        {'icon': '💧', 'name': 'Water\n2.5L / 3L'},
      ];
    }
    return [
      {'icon': '🫓', 'name': 'Ugali'},
      {'icon': '🌿', 'name': 'Sukuma\nWiki'},
      {'icon': '💧', 'name': 'Water\n2.5L / 3L'},
    ];
  }
}

class _MealCircle extends StatelessWidget {
  final String emoji;
  final String label;
  const _MealCircle({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI tip card ───────────────────────────────────────────────
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
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

// ── Mental health card ────────────────────────────────────────
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
                        color: Colors.white70, fontSize: 12, height: 1.5),
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
