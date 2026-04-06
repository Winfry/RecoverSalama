// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 01: Landing Page
// The first screen every patient sees. Gradient hero, bilingual
// toggle, two CTAs, and four benefit cards.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _lang = 'EN';

  // Bilingual copy — all text switches instantly on toggle
  final Map<String, Map<String, String>> _copy = {
    'EN': {
      'tag': 'Recover Safely. Heal Confidently.',
      'sub':
          'AI-guided recovery tailored to your surgery, your life, and your healing.',
      'start': 'Start Recovery Plan →',
      'guest': 'Guest Mode',
      'label': 'WHAT YOU GET',
    },
    'SW': {
      'tag': 'Pona Salama. Pumzika kwa Amani.',
      'sub':
          'Mshauri wako wa kibinafsi wa kupona baada ya upasuaji wako.',
      'start': 'Anza Mpango wa Kupona →',
      'guest': 'Kuingia Bila Akaunti',
      'label': 'UTAKACHOPATA',
    },
  };

  @override
  Widget build(BuildContext context) {
    final t = _copy[_lang]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── HERO SECTION ──────────────────────────────────
          // Gradient from #0077B6 (blue) → #005f8e → #00B37E (green)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0077B6),
                  Color(0xFF005f8e),
                  Color(0xFF00B37E),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar: logo + language toggle ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💚 SalamaRecover',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            Text('SURGICAL RECOVERY AI',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                    letterSpacing: 2)),
                          ],
                        ),
                        // Language toggle — switches all text instantly
                        GestureDetector(
                          onTap: () => setState(
                              () => _lang = _lang == 'EN' ? 'SW' : 'EN'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                                _lang == 'EN'
                                    ? '🌍 Kiswahili'
                                    : '🌍 English',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Hero card — frosted glass effect ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Text('🩺',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(t['tag']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35)),
                                const SizedBox(height: 6),
                                Text(t['sub']!,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Primary CTA — white button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.go(AppRoutes.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        child: Text(t['start']!,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Secondary CTA — green outlined ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            context.go(AppRoutes.dashboard),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color:
                                  AppColors.success.withOpacity(0.5)),
                          backgroundColor:
                              AppColors.success.withOpacity(0.2),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(t['guest']!,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BENEFIT CARDS ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['label']!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  BenefitCard(
                      icon: '🤖',
                      title: _lang == 'EN'
                          ? 'AI Guidance'
                          : 'Mwongozo wa AI',
                      desc: _lang == 'EN'
                          ? 'Ask anything about your recovery anytime'
                          : 'Uliza chochote kuhusu kupona kwako'),
                  BenefitCard(
                      icon: '🥗',
                      title: _lang == 'EN'
                          ? 'Kenya Diet'
                          : 'Lishe ya Kenya',
                      desc: _lang == 'EN'
                          ? 'Local foods that help you heal faster'
                          : 'Vyakula vya ndani vinavyosaidia',
                      isBlue: false),
                  BenefitCard(
                      icon: '🧠',
                      title: _lang == 'EN'
                          ? 'Mental Health'
                          : 'Afya ya Akili',
                      desc: _lang == 'EN'
                          ? 'Daily check-ins for your emotional wellbeing'
                          : 'Ukaguzi wa kila siku wa hali yako'),
                  BenefitCard(
                      icon: '🏥',
                      title: _lang == 'EN'
                          ? 'Doctor Connect'
                          : 'Musiliano na Daktari',
                      desc: _lang == 'EN'
                          ? 'Reach hospitals and specialists instantly'
                          : 'Wasiliana na hospitali mara moja',
                      isBlue: false),
                ],
              ),
            ),
          ),

          // ── PRIVACY FOOTER ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              '🔒 Your data is private & secure · For informational support only',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textHint, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
