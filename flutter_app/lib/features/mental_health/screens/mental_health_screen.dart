// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 07: Mental Health Check-In
// Daily emotional wellbeing check. 4 mood cards in a 2x2 grid.
// AI responds immediately. If "Overwhelmed" → red referral CTA.
// This is a SAFETY FEATURE — the referral must never be removed.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../providers/mental_health_provider.dart';

class MentalHealthScreen extends ConsumerStatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  ConsumerState<MentalHealthScreen> createState() =>
      _MentalHealthScreenState();
}

class _MentalHealthScreenState extends ConsumerState<MentalHealthScreen> {
  String? _mood;

  // 4 moods — each with color, background, emoji, and description
  final _moods = [
    {
      'emoji': '😊',
      'label': 'Okay',
      'color': AppColors.success,
      'bg': AppColors.successLight,
      'desc': 'Feeling well and positive',
    },
    {
      'emoji': '😐',
      'label': 'Tired',
      'color': AppColors.warning,
      'bg': AppColors.warningLight,
      'desc': 'Okay but exhausted',
    },
    {
      'emoji': '😟',
      'label': 'Anxious',
      'color': const Color(0xFFF77F00),
      'bg': const Color(0xFFFFF3E0),
      'desc': 'Worried about recovery',
    },
    {
      'emoji': '😢',
      'label': 'Overwhelmed',
      'color': AppColors.emergency,
      'bg': const Color(0xFFFFF0F0),
      'desc': 'Struggling emotionally',
    },
  ];

  // AI responses — personalised per mood
  final Map<String, String> _responses = {
    'Okay':
        'That is wonderful! 💚 Keep up the positivity — it genuinely supports '
            'healing. Try a short walk and enjoy some sunlight today if possible.',
    'Tired':
        'Fatigue is completely normal at this stage. 🌙 Rest as much as you need. '
            'Stay hydrated, eat well, and do not push yourself. Your body is working '
            'hard to heal.',
    'Anxious':
        'It is okay to feel anxious — you have been through a lot. 🌿 Try the '
            '4-4-4 breathing technique: breathe in 4 seconds, hold 4, out 4. Consider '
            'talking to someone you trust today.',
    'Overwhelmed':
        'You are not alone in feeling this way. 💛 Your feelings are valid. Please '
            'speak with a mental health professional or trusted person today. You '
            'deserve support.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Purple gradient header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5C6BC0), Color(0xFF9C27B0)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  children: const [
                    Text('🧠', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 10),
                    Text('Mental Health Check-In',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text(
                        'Your emotional wellbeing matters as much as physical healing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5)),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('How are you feeling today?',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Tap what describes you right now',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint)),
                  const SizedBox(height: 20),

                  // ── 2x2 Mood grid ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: _moods.map((m) {
                      final selected = _mood == m['label'];
                      return GestureDetector(
                        onTap: () {
                          setState(
                              () => _mood = m['label'] as String);
                          // Save to provider
                          ref
                              .read(mentalHealthProvider.notifier)
                              .selectMood(m['label'] as String);
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected
                                ? (m['bg'] as Color)
                                : AppColors.background,
                            border: Border.all(
                              color: selected
                                  ? (m['color'] as Color)
                                  : AppColors.border,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(m['emoji'] as String,
                                  style: const TextStyle(
                                      fontSize: 36)),
                              const SizedBox(height: 6),
                              Text(m['label'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? (m['color'] as Color)
                                        : AppColors.textPrimary,
                                  )),
                              const SizedBox(height: 3),
                              Text(m['desc'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textHint)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── AI Response card (green) ──
                  if (_mood != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                AppColors.success.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('💚 AI Response for You',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(_responses[_mood]!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.7)),

                          // SAFETY: Red referral button for "Overwhelmed"
                          if (_mood == 'Overwhelmed') ...[
                            const SizedBox(height: 12),
                            SalamaButton(
                              label: '🤝 Connect to a Professional',
                              color: AppColors.emergency,
                              onTap: () =>
                                  context.go(AppRoutes.hospital),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // ── Wellbeing tips card (purple) ──
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFE1BEE7)),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('✨ Wellbeing Tips for Today',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF7B1FA2))),
                        const SizedBox(height: 10),
                        ...[
                          'Write 3 things you are grateful for in your recovery',
                          'Limit social media if it increases anxiety',
                          'Connect with a friend or family member today',
                          'Celebrate small wins — every day of healing counts',
                        ].map((tip) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('◆ ',
                                      style: TextStyle(
                                          color:
                                              Color(0xFF9C27B0),
                                          fontSize: 12)),
                                  Expanded(
                                      child: Text(tip,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors
                                                  .textPrimary,
                                              height: 1.5))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                  // ── Befrienders Kenya helpline ──
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Text('📞', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Befrienders Kenya',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  '0722 178 177 — Free & confidential',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Done button ──
                  const SizedBox(height: 20),
                  SalamaButton(
                    label: 'Done for Today ✓',
                    color: AppColors.success,
                    onTap: () => context.go(AppRoutes.dashboard),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
