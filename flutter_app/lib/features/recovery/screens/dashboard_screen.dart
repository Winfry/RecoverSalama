// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 05: Recovery Dashboard
// The main home screen patients see every morning. Shows what
// to do today — progress, stage, activities, diet, AI tip.
// Emergency banner sits at top if risk is HIGH/EMERGENCY.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

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
    final progressPercent = (day / 42 * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Emergency banner — first element, always visible ──
          if (recovery.hasWarning)
            EmergencyBanner(
              message: recovery.warningMessage.isNotEmpty
                  ? recovery.warningMessage
                  : 'Monitor wound site — rest today.',
              onCall: () => context.go(AppRoutes.hospital),
            ),

          // ── Blue header with amber progress bar ──
          Container(
            color: AppColors.primary,
            child: SafeArea(
              top: !recovery.hasWarning, // If banner above, SafeArea already handled
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day $day of Recovery',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const Text('Your Recovery Dashboard',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),

                    // Progress bar — amber fill (warm, healing feel)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Progress',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('$progressPercent%',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressPercent / 100,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.warning),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Dashboard content cards ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Recovery Stage card (green) ──
                  _sectionCard(
                    bg: AppColors.successLight,
                    border: AppColors.success.withOpacity(0.25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  _getStageBadge(day),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Text(_getStageName(day),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStageDescription(day),
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Activities card (allowed + restricted) ──
                  _sectionCard(
                    bg: Colors.white,
                    border: AppColors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✅ Allowed Today',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        const SizedBox(height: 8),
                        ..._getAllowedActivities(day)
                            .map((a) => _activityRow(a, allowed: true)),
                        const SizedBox(height: 12),
                        const Text('🚫 Restricted',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        const SizedBox(height: 8),
                        ..._getRestrictedActivities(day)
                            .map((a) => _activityRow(a, allowed: false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Diet preview card (amber) ──
                  _sectionCard(
                    bg: AppColors.warningLight,
                    border: AppColors.warning.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🥗 Today\'s Diet & Hydration',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getDietChips(day)
                              .map((f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.warning
                                              .withOpacity(0.5)),
                                    ),
                                    child: Text(f,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.diet),
                          child: const Text('View Full Diet Plan →',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── AI Tip card (light blue) ──
                  _sectionCard(
                    bg: AppColors.primaryLight,
                    border: const Color(0xFFCCE5FF),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('AI Tip of the Day',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                recovery.aiTip.isNotEmpty
                                    ? recovery.aiTip
                                    : _defaultTip(day),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    height: 1.6),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () =>
                                    context.go(AppRoutes.aiChat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                      'Ask AI Assistant →',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Bottom nav — active on Home (index 0) ──
          SalamaBottomNav(
            currentIndex: 0,
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

  // ── Reusable section card ──
  Widget _sectionCard(
      {required Widget child,
      required Color bg,
      required Color border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  // ── Activity row — green check or red cross ──
  Widget _activityRow(String text, {required bool allowed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(allowed ? '✓' : '✕',
              style: TextStyle(
                color: allowed ? AppColors.success : AppColors.emergency,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              )),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  // ── Stage info based on recovery day ──
  String _getStageBadge(int day) {
    if (day <= 2) return 'Stage 1';
    if (day <= 7) return 'Stage 2';
    if (day <= 14) return 'Stage 3';
    if (day <= 30) return 'Stage 4';
    return 'Stage 5';
  }

  String _getStageName(int day) {
    if (day <= 2) return 'Immediate Post-Op';
    if (day <= 7) return 'Early Healing';
    if (day <= 14) return 'Active Recovery';
    if (day <= 30) return 'Strengthening';
    return 'Full Recovery';
  }

  String _getStageDescription(int day) {
    if (day <= 2) {
      return 'Rest is critical. Your body is recovering from anaesthesia. '
          'Clear liquids only. Pain management is the priority.';
    }
    if (day <= 7) {
      return 'Your body is rebuilding tissue. Light movement helps blood flow. '
          'Avoid strenuous activity. Watch for infection signs.';
    }
    if (day <= 14) {
      return 'You are actively healing. Gradually increase activity. '
          'Normal diet returning. Pain should be decreasing.';
    }
    if (day <= 30) {
      return 'Strength is returning. Near-normal activity levels. '
          'Continue healthy eating. Follow-up appointment recommended.';
    }
    return 'Recovery is nearly complete. Resume normal activities gradually. '
        'Monitor for any late complications.';
  }

  // ── Allowed activities based on recovery day ──
  List<String> _getAllowedActivities(int day) {
    if (day <= 2) {
      return ['Bed rest', 'Deep breathing exercises', 'Sipping water'];
    }
    if (day <= 7) {
      return [
        'Short walks (5–10 min)',
        'Gentle stretching',
        'Deep breathing exercises',
        'Reading or light activities',
      ];
    }
    if (day <= 14) {
      return [
        'Walks (15–20 min)',
        'Light housework',
        'Gentle exercises',
        'Returning to light work',
      ];
    }
    return [
      'Moderate exercise',
      'Most daily activities',
      'Driving (if pain-free)',
      'Gradual return to work',
    ];
  }

  // ── Restricted activities based on recovery day ──
  List<String> _getRestrictedActivities(int day) {
    if (day <= 7) {
      return [
        'Lifting above 2kg',
        'Driving',
        'Intense exercise',
        'Swimming or bathing (shower only)',
      ];
    }
    if (day <= 14) {
      return [
        'Lifting above 5kg',
        'Strenuous exercise',
        'Swimming',
      ];
    }
    if (day <= 30) {
      return [
        'Heavy lifting (above 10kg)',
        'High-impact exercise',
      ];
    }
    return ['Consult doctor before contact sports'];
  }

  // ── Diet preview chips based on recovery day ──
  List<String> _getDietChips(int day) {
    if (day <= 2) {
      return ['🫖 Tea', '🥣 Broth', '💧 Water', '🧃 Juice'];
    }
    if (day <= 4) {
      return ['🥣 Uji', '🥛 Maziwa', '🫙 Mtindi', '🍲 Supu'];
    }
    if (day <= 7) {
      return [
        '🥚 Mayai',
        '🍌 Ndizi',
        '🫓 Ugali laini',
        '🥭 Papai',
        '💧 2L Water',
      ];
    }
    return [
      '🥚 Eggs',
      '🫘 Beans',
      '🌿 Sukuma',
      '🍌 Banana',
      '🫙 Soup',
      '💧 2.5L Water',
    ];
  }

  // ── Default tip shown before first check-in is submitted ──
  String _defaultTip(int day) {
    if (day <= 2) {
      return 'Rest is the best medicine right now. Sip water regularly '
          'and take your prescribed pain medication on schedule.';
    }
    if (day <= 7) {
      return 'Short 5-minute walks improve blood flow and speed healing. '
          'Avoid lifting anything heavier than a phone.';
    }
    if (day <= 14) {
      return 'Your wound is closing well. Keep it clean and dry. '
          'Eat protein-rich foods like eggs and beans to support tissue repair.';
    }
    if (day <= 30) {
      return 'Strength returns slowly — don\'t rush it. Eat balanced meals '
          'with sukuma wiki and lean protein. Stay well hydrated.';
    }
    return 'You are in the final stretch of recovery. Listen to your body '
        'and resume activities gradually. Congratulations on your progress!';
  }
}
