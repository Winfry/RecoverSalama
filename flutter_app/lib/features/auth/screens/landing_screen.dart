 // © 2026 Winfry Nyarangi Nyabuto. All Rights Reserved.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  String _lang = 'EN';
  late AnimationController _ctrl;
  late Animation<double> _fade;

  static const _copy = {
    'EN': {
      'title': 'Recover better\nwith Pona Salama',
      'sub': 'Personalized care. Local guidance.\nBacked by AI and doctors.',
      'start': 'Start Recovery Plan',
      'guest': 'Continue in Guest Mode',
      'aiTitle': 'AI Guidance',
      'aiDesc': 'Smart answers to\nyour questions',
      'dietTitle': 'Kenya Diet',
      'dietDesc': 'Local foods for\nfaster healing',
      'mhTitle': 'Mental Health',
      'mhDesc': 'Support your\nmind every day',
      'docTitle': 'Doctor Connect',
      'docDesc': 'Talk or call\na professional',
    },
    'KW': {
      'title': 'Pona vizuri zaidi\nna Pona Salama',
      'sub': 'Huduma ya kibinafsi. Mwongozo wa ndani.\nKwa AI na madaktari.',
      'start': 'Anza Mpango wa Kupona',
      'guest': 'Endelea Bila Akaunti',
      'aiTitle': 'Mwongozo wa AI',
      'aiDesc': 'Majibu ya haraka\nkwa maswali yako',
      'dietTitle': 'Lishe ya Kenya',
      'dietDesc': 'Vyakula vya ndani\nkwa kupona haraka',
      'mhTitle': 'Afya ya Akili',
      'mhDesc': 'Saidia akili yako\nkila siku',
      'docTitle': 'Ungana na Daktari',
      'docDesc': 'Ongea au piga simu\nkwa mtaalamu',
    },
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _copy[_lang]!;

    final features = <_Feature>[
      _Feature(
        asset: 'assets/images/landing/icon_ai_guidance.png',
        tint: const Color(0xFFFFF6E0),
        title: t['aiTitle']!,
        desc: t['aiDesc']!,
      ),
      _Feature(
        asset: 'assets/images/landing/icon_kenya_diet.png',
        tint: const Color(0xFFE9F8E0),
        title: t['dietTitle']!,
        desc: t['dietDesc']!,
      ),
      _Feature(
        asset: 'assets/images/landing/icon_mental_health.png',
        tint: const Color(0xFFF3E8FF),
        title: t['mhTitle']!,
        desc: t['mhDesc']!,
      ),
      _Feature(
        asset: 'assets/images/landing/icon_doctor.png',
        tint: const Color(0xFFE0F2F8),
        title: t['docTitle']!,
        desc: t['docDesc']!,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.menu_rounded,
                        size: 26, color: AppColors.textPrimary),
                    const Spacer(),
                    _LangToggle(
                      lang: _lang,
                      onToggle: () => setState(
                          () => _lang = _lang == 'EN' ? 'KW' : 'EN'),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading with green heart
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          children: [
                            TextSpan(text: t['title']),
                            const TextSpan(text: ' 💚'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t['sub']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),

                      // ── Hero illustration ────────────────────────────
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/landing/illustration_people.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // ── Feature cards 2×2 ───────────────────────────
                      const SizedBox(height: 22),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children:
                            features.map((f) => _FeatureCard(feature: f)).toList(),
                      ),

                      // ── Primary CTA ──────────────────────────────────
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.login),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            t['start']!,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      // ── Guest CTA (outlined) ─────────────────────────
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => context.go(AppRoutes.dashboard),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary, width: 1.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            t['guest']!,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature card ─────────────────────────────────────────────────────────────

class _Feature {
  final String asset;
  final Color tint;
  final String title;
  final String desc;
  const _Feature({
    required this.asset,
    required this.tint,
    required this.title,
    required this.desc,
  });
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: feature.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(feature.asset, width: 36, height: 36),
          const Spacer(),
          Text(
            feature.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            feature.desc,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language toggle ──────────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  final String lang;
  final VoidCallback onToggle;
  const _LangToggle({required this.lang, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_pill('EN', lang == 'EN'), _pill('KW', lang == 'KW')],
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
        borderRadius: BorderRadius.circular(18),
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
