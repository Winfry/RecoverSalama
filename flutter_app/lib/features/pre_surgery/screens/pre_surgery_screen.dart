// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 03: Pre-Surgery Checklist
// Accordion-style interactive checklists with circular overall
// progress tracker. Persists check state via SharedPreferences.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../providers/pre_surgery_provider.dart';

// ── Internal section model ────────────────────────────────────
class _Section {
  final String id;
  final String title;
  final IconData icon;
  final List<String> items;
  const _Section({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });
}

class PreSurgeryScreen extends ConsumerStatefulWidget {
  const PreSurgeryScreen({super.key});

  @override
  ConsumerState<PreSurgeryScreen> createState() => _PreSurgeryScreenState();
}

class _PreSurgeryScreenState extends ConsumerState<PreSurgeryScreen> {
  // Tracks which accordions are currently open
  final Set<String> _expanded = {};

  static const _sections = [
    _Section(
      id: 'health',
      title: 'Health Preparation',
      icon: Icons.favorite_border,
      items: [
        'Complete all pre-op blood tests',
        'Fast for 8 hours before surgery',
        'Stop blood thinners if advised',
        'Arrange transport home',
        'Shower with antibacterial soap',
      ],
    ),
    _Section(
      id: 'bag',
      title: 'Hospital Bag',
      icon: Icons.work_outline,
      items: [
        'ID and insurance documents',
        'Comfortable loose clothing',
        'Toiletries and toothbrush',
        'Phone charger and earphones',
        'Snacks for recovery room',
      ],
    ),
    _Section(
      id: 'doctor',
      title: 'Questions for Doctor',
      icon: Icons.help_outline,
      items: [
        'How long will surgery take?',
        'What are the main risks?',
        'How long is recovery?',
        'What medications will I need?',
        'When can I eat or drink again?',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final checkedState = ref.watch(preSurgeryProvider);

    // Overall progress across all 3 sections
    final totalItems =
        _sections.fold<int>(0, (sum, s) => sum + s.items.length);
    final checkedCount = _sections.fold<int>(0, (sum, s) {
      int n = 0;
      for (int i = 0; i < s.items.length; i++) {
        if (checkedState['${s.id}-$i'] ?? false) n++;
      }
      return sum + n;
    });
    final progress = totalItems > 0 ? checkedCount / totalItems : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: [
                  _buildProgressCard(checkedCount, totalItems, progress),
                  const SizedBox(height: 16),
                  ..._sections.map((s) => _buildAccordion(s, checkedState)),
                  const SizedBox(height: 4),
                  _buildEmotionalCard(),
                  const SizedBox(height: 20),
                  SalamaButton(
                    label: 'Start Recovery →',
                    color: AppColors.primary,
                    onTap: () => context.go(AppRoutes.dashboard),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.profileSetup),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pre-Surgery\nChecklist',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Overall progress card ───────────────────────────────────
  Widget _buildProgressCard(int checked, int total, double progress) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall progress',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '$checked of $total tasks done',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Circular ring with percentage
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Accordion section card ──────────────────────────────────
  Widget _buildAccordion(_Section section, Map<String, bool> checkedState) {
    final isExpanded = _expanded.contains(section.id);

    int completed = 0;
    for (int i = 0; i < section.items.length; i++) {
      if (checkedState['${section.id}-$i'] ?? false) completed++;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Tappable header row ─────────────────────────────
          GestureDetector(
            onTap: () => setState(() {
              isExpanded
                  ? _expanded.remove(section.id)
                  : _expanded.add(section.id);
            }),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Section icon square
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(section.icon,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Title + completion count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completed / ${section.items.length} completed',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary, size: 24),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded checklist items ────────────────────────
          if (isExpanded) ...[
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: List.generate(section.items.length, (i) {
                  final key = '${section.id}-$i';
                  final checked = checkedState[key] ?? false;

                  return GestureDetector(
                    onTap: () =>
                        ref.read(preSurgeryProvider.notifier).toggle(key),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Checkbox
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: checked
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: checked
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: checked
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Item text with strikethrough when checked
                          Expanded(
                            child: Text(
                              section.items[i],
                              style: TextStyle(
                                fontSize: 13,
                                color: checked
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                                decoration: checked
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Emotional readiness card ────────────────────────────────
  Widget _buildEmotionalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Emotional Readiness',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "You got this. Take a deep\nbreath, you're not alone.",
                  style: TextStyle(
                    color: Color(0xFF5B21B6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('🧘', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }

  // ── Bottom navigation bar ───────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                active: false,
                onTap: () => context.go(AppRoutes.dashboard),
              ),
              _navItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: 'Guidance',
                active: true,
                onTap: null,
              ),
              _navItem(
                icon: Icons.bar_chart,
                activeIcon: Icons.bar_chart,
                label: 'Dashboard',
                active: false,
                onTap: () => context.go(AppRoutes.dashboard),
              ),
              _navItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
                active: false,
                onTap: () => context.go(AppRoutes.aiChat),
              ),
              _navItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                active: false,
                onTap: () => context.go(AppRoutes.profileSetup),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool active,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            size: 24,
            color: active ? AppColors.primary : AppColors.textHint,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
