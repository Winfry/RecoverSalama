// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 01: Landing Page
// The first screen every patient sees. Gradient hero, bilingual
// toggle, two CTAs, and four benefit cards.
// © 2026 Winfry Nyarangi Nyabuto. All Rights Reserved.
//

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _lang = 'EN';

  final Map<String, Map<String, String>> _copy = {
    'EN': {
      'title': 'Recover better\nwith Pona Salama',
      'sub': 'Personalised care. Local guidance.\nBacked by AI and doctors.',
      'start': 'Start Recovery Plan',
      'guest': 'Continue in Guest Mode',
    },
    'KW': {
      'title': 'Pona vizuri zaidi\nna Pona Salama',
      'sub': 'Huduma ya kibinafsi. Mwongozo wa ndani.\nKwa AI na madaktari.',
      'start': 'Anza Mpango wa Kupona',
      'guest': 'Endelea Bila Akaunti',
    },
  };

  final _features = [
    {'icon': '🤖', 'title': 'AI Guidance', 'desc': 'Smart answers\nfor your questions'},
    {'icon': '🥗', 'title': 'Kenya Diet', 'desc': 'Local foods for\nfaster healing'},
    {'icon': '🧠', 'title': 'Mental Health', 'desc': 'Support your\nmind every day'},
    {'icon': '🏥', 'title': 'Doctor Connect', 'desc': 'Talk or call\na professional'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = _copy[_lang]!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.menu_rounded,
                      size: 26, color: AppColors.textPrimary),
                  const Spacer(),
                  _LangToggle(
                    lang: _lang,
                    onToggle: () =>
                        setState(() => _lang = _lang == 'EN' ? 'KW' : 'EN'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Heading ──
                    Text(
                      t['title']!,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t['sub']!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    // ── Illustration ──
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('👩🏾', style: TextStyle(fontSize: 56)),
                            SizedBox(width: 8),
                            Text('👨🏾‍⚕️', style: TextStyle(fontSize: 64)),
                            SizedBox(width: 8),
                            Text('👵🏾', style: TextStyle(fontSize: 52)),
                          ],
                        ),
                      ),
                    ),

                    // ── Feature cards 2×2 ──
                    const SizedBox(height: 28),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: _features
                          .map((f) => _FeatureCard(
                                icon: f['icon']!,
                                title: f['title']!,
                                desc: f['desc']!,
                              ))
                          .toList(),
                    ),

                    // ── CTAs ──
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go(AppRoutes.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          t['start']!,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.dashboard),
                        child: Text(
                          t['guest']!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '🔒 Your data is private & secure',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                      ),
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
}

class _LangToggle extends StatelessWidget {
  final String lang;
  final VoidCallback onToggle;
  const _LangToggle({required this.lang, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill('EN', lang == 'EN'),
            _pill('KW', lang == 'KW'),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  const _FeatureCard(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}