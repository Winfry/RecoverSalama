// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 08: Diet Guidance
// Kenya-local food recommendations from the Kenya National
// Clinical Nutrition Manual (MOH 2010). Filterable by category.
// No Western foods — ugali, sukuma wiki, githeri, pawpaw only.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  String _filter = 'All';

  // Kenya-local food sections — ALL from MOH Nutrition Manual
  final _sections = [
    {
      'title': '💪 Protein — Tissue Repair',
      'color': AppColors.success,
      'tag': 'Protein',
      'foods': [
        {'emoji': '🥚', 'name': 'Eggs (Mayai)', 'benefit': 'Complete protein, easy to digest'},
        {'emoji': '🫘', 'name': 'Beans (Githeri)', 'benefit': 'High fibre and plant protein'},
        {'emoji': '🟤', 'name': 'Lentils (Dengu)', 'benefit': 'Iron-rich, reduces inflammation'},
        {'emoji': '🐟', 'name': 'Fresh Fish (Samaki)', 'benefit': 'Omega-3 supports healing'},
        {'emoji': '🍗', 'name': 'Chicken (Kuku)', 'benefit': 'Lean protein, gut-friendly'},
      ],
    },
    {
      'title': '⚡ Energy — Fuel to Heal',
      'color': AppColors.warning,
      'tag': 'Energy',
      'foods': [
        {'emoji': '🫓', 'name': 'Ugali', 'benefit': 'Slow-release energy'},
        {'emoji': '🍚', 'name': 'Brown Rice (Wali)', 'benefit': 'Easy on the stomach'},
        {'emoji': '🍠', 'name': 'Sweet Potatoes (Viazi)', 'benefit': 'Vitamin A and natural energy'},
        {'emoji': '🥙', 'name': 'Chapati (wholemeal)', 'benefit': 'Filling and nutritious'},
      ],
    },
    {
      'title': '🌿 Vitamins & Healing',
      'color': AppColors.success,
      'tag': 'Vitamins',
      'foods': [
        {'emoji': '🥬', 'name': 'Sukuma Wiki', 'benefit': 'Iron, calcium, Vitamin K'},
        {'emoji': '🌱', 'name': 'Spinach (Mchicha)', 'benefit': 'Folate and antioxidants'},
        {'emoji': '🥑', 'name': 'Avocado', 'benefit': 'Healthy fats, Vitamin E'},
        {'emoji': '🍈', 'name': 'Pawpaw (Papai)', 'benefit': 'Enzymes that aid digestion'},
        {'emoji': '🥕', 'name': 'Carrots', 'benefit': 'Beta-carotene for tissue repair'},
      ],
    },
    {
      'title': '💧 Fluids — Stay Hydrated',
      'color': AppColors.primary,
      'tag': 'Fluids',
      'foods': [
        {'emoji': '💧', 'name': 'Water (Maji)', 'benefit': 'Aim for 2.5L daily'},
        {'emoji': '🍊', 'name': 'Fresh Fruit Juice', 'benefit': 'Vitamin C boosts immunity'},
        {'emoji': '🍲', 'name': 'Bone Broth (Supu)', 'benefit': 'Collagen for wound healing'},
        {'emoji': '🫖', 'name': 'Ginger Tea', 'benefit': 'Reduces nausea, anti-inflammatory'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter sections based on selected chip
    final filtered = _filter == 'All'
        ? _sections
        : _sections.where((s) => s['tag'] == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Blue header ──
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Healing Foods for You Today',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Kenya-optimised recovery nutrition · Day 5',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          // ── AI Tip banner (green) ──
          Container(
            color: AppColors.successLight,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Text('🤖', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: 'AI Tip: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20))),
                        TextSpan(
                            text:
                                'Pair ugali with beans tonight for complete protein — perfect for tissue repair.',
                            style:
                                TextStyle(color: Color(0xFF1B5E20))),
                      ]),
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // ── Filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Protein', 'Energy', 'Vitamins', 'Fluids']
                  .map((f) {
                final active = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? Colors.white
                              : AppColors.textPrimary,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Food sections list ──
          Expanded(
            child: ListView(
              children: filtered.map((section) {
                final foods =
                    section['foods'] as List<Map<String, String>>;
                final color = section['color'] as Color;
                return Column(
                  children: [
                    // Section header bar (colored)
                    Container(
                      width: double.infinity,
                      color: color,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(section['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ),
                    // Food rows (alternating white/gray)
                    ...foods.asMap().entries.map((entry) => Container(
                          color: entry.key % 2 == 0
                              ? Colors.white
                              : const Color(0xFFF9F9F9),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              Text(entry.value['emoji']!,
                                  style:
                                      const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.value['name']!,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w700,
                                            fontSize: 13)),
                                    Text(entry.value['benefit']!,
                                        style: const TextStyle(
                                            color:
                                                AppColors.textHint,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text('Recipe →',
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                  ],
                );
              }).toList(),
            ),
          ),

          // ── Bottom nav — active on Diet (index 3) ──
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
}
