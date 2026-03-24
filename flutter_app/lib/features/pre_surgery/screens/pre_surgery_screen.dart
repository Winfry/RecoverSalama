// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 03: Pre-Surgery Guidance
// Shown before surgery date. Three interactive checklists
// (Health Prep, Hospital Bag, Doctor Questions) plus an
// Emotional Readiness section. Checked items get green fill
// + white checkmark + strikethrough text.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';

class PreSurgeryScreen extends ConsumerStatefulWidget {
  const PreSurgeryScreen({super.key});

  @override
  ConsumerState<PreSurgeryScreen> createState() =>
      _PreSurgeryScreenState();
}

class _PreSurgeryScreenState extends ConsumerState<PreSurgeryScreen> {
  // Tracks which checklist items are ticked (persists within session)
  final Map<String, bool> _checked = {};

  // Three checklist sections with different colors and interaction types
  final _sections = [
    {
      'title': '🏃 Health Prep Checklist',
      'color': AppColors.success,
      'bg': AppColors.successLight,
      'items': [
        'Complete all pre-op blood tests',
        'Fast for 8 hours before surgery',
        'Stop blood thinners if advised',
        'Arrange transport home',
        'Shower with antibacterial soap',
      ],
      'type': 'checkbox', // Interactive — tappable
    },
    {
      'title': '🎒 Hospital Bag',
      'color': AppColors.success,
      'bg': AppColors.successLight,
      'items': [
        'ID and insurance documents',
        'Comfortable loose clothing',
        'Toiletries and toothbrush',
        'Phone charger and earphones',
        'Snacks for recovery room',
      ],
      'type': 'checkbox', // Interactive — tappable
    },
    {
      'title': '❓ Questions for Your Doctor',
      'color': AppColors.warning,
      'bg': AppColors.warningLight,
      'items': [
        'How long will surgery take?',
        'What are the main risks?',
        'How long is recovery?',
        'What medications will I need?',
        'When can I eat or drink again?',
      ],
      'type': 'bullet', // Read-only — reference list
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Blue gradient header with progress bar ──────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0077B6), Color(0xFF005f8e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back → Profile Setup
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.profileSetup),
                      child: const Text('← Back',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar — step 2 of 3
                    const SalamaProgressBar(
                        currentStep: 2, totalSteps: 3),
                    const SizedBox(height: 8),

                    const Text('Step 2 of 3',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 4),
                    const Text('Pre-Surgery Guidance',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const Text(
                        'Get ready — physically & emotionally',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          // ── Content — checklists + emotional readiness ─────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Checklist sections (Health Prep, Hospital Bag, Doctor Questions)
                  ..._sections.map((section) => _buildSection(section)),

                  // Emotional readiness card
                  _buildEmotionalCard(),

                  const SizedBox(height: 16),

                  // Start Recovery CTA — green button
                  SalamaButton(
                    label: 'Start Recovery →',
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

  /// Builds a checklist section card.
  /// 'checkbox' type: tappable items with green fill when checked.
  /// 'bullet' type: read-only reference items with diamond bullets.
  Widget _buildSection(Map section) {
    final items = section['items'] as List<String>;
    final isBullet = section['type'] == 'bullet';
    final color = section['color'] as Color;
    final bg = section['bg'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(section['title'] as String,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),

          // Items
          ...items.asMap().entries.map((entry) {
            final key = '${section['title']}-${entry.key}';
            final checked = _checked[key] ?? false;

            return GestureDetector(
              onTap: isBullet
                  ? null
                  : () => setState(() => _checked[key] = !checked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Checkbox or bullet
                    if (!isBullet)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                              checked ? color : Colors.transparent,
                          border:
                              Border.all(color: color, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: checked
                            ? const Icon(Icons.check,
                                size: 13, color: Colors.white)
                            : null,
                      )
                    else
                      Text('✦',
                          style: TextStyle(
                              color: color, fontSize: 12)),
                    const SizedBox(width: 10),

                    // Item text — strikethrough when checked
                    Expanded(
                      child: Text(entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: checked && !isBullet
                                ? AppColors.textHint
                                : AppColors.textPrimary,
                            decoration: checked && !isBullet
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.textHint,
                          )),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Emotional readiness card — tips for managing pre-surgery anxiety.
  /// Green background with diamond bullet points.
  Widget _buildEmotionalCard() {
    final tips = [
      'It is normal to feel nervous — talk to someone you trust.',
      'Practice deep breathing: 4 counts in, hold 4, exhale 6.',
      'Write down your fears and share with your care team.',
      'Your medical team is trained and prepared for you.',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💚 Emotional Readiness',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✦',
                        style: TextStyle(
                            color: AppColors.success, fontSize: 12)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(tip,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.5))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
