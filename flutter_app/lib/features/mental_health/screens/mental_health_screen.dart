import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/mental_health_provider.dart';

class MentalHealthScreen extends ConsumerStatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  ConsumerState<MentalHealthScreen> createState() =>
      _MentalHealthScreenState();
}

class _MentalHealthScreenState extends ConsumerState<MentalHealthScreen> {
  String? _mood;
  final _notesCtrl = TextEditingController();

  final Map<String, String> _fallback = {
    'Okay': 'You\'re doing well 💚 Keep up the positivity — it genuinely supports healing. Try a short walk and enjoy some sunlight today if possible.',
    'Tired': 'Fatigue is completely normal at this stage. 🌙 Rest as much as you need. Stay hydrated, eat well, and don\'t push yourself.',
    'Anxious': 'It\'s okay to feel anxious — you\'ve been through a lot. 🌿 Try breathing slowly: in 4 seconds, hold 4, out 6. You are safe.',
    'Overwhelmed': 'You\'re not alone in feeling this way. 💛 Your feelings are valid. Taking this step is already a sign of strength. Please speak with someone today.',
  };

  final _moods = [
    {'emoji': '☀️', 'label': 'Okay', 'sub': "I'm managing", 'color': 0xFF22C55E, 'bg': 0xFFDCFCE7},
    {'emoji': '😴', 'label': 'Tired', 'sub': 'Very drained', 'color': 0xFFFFB703, 'bg': 0xFFFFF8E1},
    {'emoji': '😰', 'label': 'Anxious', 'sub': 'Feeling worried', 'color': 0xFFF77F00, 'bg': 0xFFFFF3E0},
    {'emoji': '🆘', 'label': 'Overwhelmed', 'sub': 'I need support', 'color': 0xFFEF4444, 'bg': 0xFFFEE2E2},
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mhState = ref.watch(mentalHealthProvider);
    final displayMsg = mhState.supportMessage ??
        (_mood != null ? _fallback[_mood] : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.dashboard),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Mental Health Check-In',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Heading ──
                    const Text(
                      'How are you feeling\nemotionally today?',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    const Text("It's okay to not be okay 💜",
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),

                    // ── 2×2 Mood grid ──
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: _moods.map((m) {
                        final selected = _mood == m['label'];
                        final color = Color(m['color'] as int);
                        final bg = Color(m['bg'] as int);
                        return GestureDetector(
                          onTap: () {
                            setState(() => _mood = m['label'] as String);
                            ref
                                .read(mentalHealthProvider.notifier)
                                .selectMood(
                                  m['label'] as String,
                                  notes: _notesCtrl.text.trim().isEmpty
                                      ? null
                                      : _notesCtrl.text.trim(),
                                );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: selected ? bg : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? color : AppColors.border,
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                          color: color.withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(m['emoji'] as String,
                                    style: const TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                Text(m['label'] as String,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? color
                                            : AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(m['sub'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // ── Notes ──
                    const SizedBox(height: 20),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Anything on your mind? (Optional)\nYou can write in English or Kiswahili',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                        if (_mood != null) {
                          ref.read(mentalHealthProvider.notifier).selectMood(
                                _mood!,
                                notes: _notesCtrl.text.trim().isEmpty
                                    ? null
                                    : _notesCtrl.text.trim(),
                              );
                        }
                      },
                    ),

                    // ── AI Support card ──
                    if (_mood != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                      child: Text('🤖',
                                          style: TextStyle(fontSize: 16))),
                                ),
                                const SizedBox(width: 10),
                                const Text('AI Support',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (mhState.isLoading)
                              const Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary),
                                ),
                              )
                            else
                              Text(displayMsg ?? '',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      height: 1.65)),
                          ],
                        ),
                      ),
                    ],

                    // ── SAFETY: Professional referral (Overwhelmed) ──
                    if (_mood == 'Overwhelmed' ||
                        (ref.watch(mentalHealthProvider).mentalHealthLevel ==
                            'needs_support')) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(AppRoutes.hospital),
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Talk to a Professional'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emergency,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],

                    // ── Befrienders helpline ──
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Text('📞', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Befrienders Kenya',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                SizedBox(height: 2),
                                Text('0722 178 177 · Free & confidential',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go(AppRoutes.dashboard),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Done for Today ✓',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
