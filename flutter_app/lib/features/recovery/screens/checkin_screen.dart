// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 04: Daily Check-In Form
// THE most important data collection screen. Filled every day.
// Data feeds the two-layer risk scorer (rules + Gemini).
// If critical symptom ticked → red banner appears INSTANTLY.
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

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  int _days = 5;
  double _pain = 4;
  String _mood = 'Good';
  final Map<String, bool> _symptoms = {};

  // Critical symptoms — red checkboxes, trigger emergency banner
  final _criticalSymptoms = [
    'Fever above 38°C',
    'Wound bleeding or discharge',
    'Severe swelling',
    'Difficulty breathing',
  ];

  // Normal symptoms — green checkboxes, monitored but not alarming
  final _normalSymptoms = [
    'Nausea or vomiting',
    'Constipation',
    'Mild headache',
    'Fatigue or weakness',
  ];

  // True if ANY critical symptom is checked — shows emergency banner
  bool get _hasCritical =>
      _criticalSymptoms.any((s) => _symptoms[s] == true);

  // Pain slider color changes with severity
  Color get _painColor {
    if (_pain <= 3) return AppColors.success;   // Green — good
    if (_pain <= 6) return AppColors.warning;   // Amber — moderate
    return AppColors.emergency;                  // Red — severe
  }

  @override
  void initState() {
    super.initState();
    // Try to auto-set days from profile's surgery date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider);
      if (profile.daysSinceSurgery > 0) {
        setState(() => _days = profile.daysSinceSurgery);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Emergency banner — appears INSTANTLY on critical symptom ──
          if (_hasCritical)
            EmergencyBanner(
              message:
                  'Critical symptom detected — consider contacting your hospital',
              onCall: () => context.go(AppRoutes.hospital),
            ),

          // ── Blue header ──
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Daily Check-In',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('How are you feeling today?',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          // ── Form content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Days since surgery counter ──
                  const Text('Days Since Surgery',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button — outlined
                      _counterBtn(Icons.remove,
                          () => setState(() => _days = (_days - 1).clamp(0, 365))),
                      const SizedBox(width: 24),
                      // Day number — large blue
                      Text('$_days',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      const SizedBox(width: 24),
                      // Plus button — filled blue
                      _counterBtn(Icons.add,
                          () => setState(() => _days++),
                          filled: true),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Pain level slider ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pain Level',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                      // Color-coded badge (green/amber/red)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: _painColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('${_pain.round()}/10',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Slider — color changes with severity
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _painColor,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: _painColor,
                      overlayColor: _painColor.withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _pain,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (v) => setState(() => _pain = v),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('No pain',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                      Text('Moderate',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                      Text('Severe',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),

                  // Helper tip with orange left border
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9F0),
                      borderRadius: BorderRadius.circular(10),
                      border: const Border(
                          left: BorderSide(
                              color: Color(0xFFE65100), width: 3)),
                    ),
                    child: const Text(
                      'If any symptom is severe, the AI may suggest visiting a hospital.',
                      style: TextStyle(
                          color: Color(0xFFE65100), fontSize: 12),
                    ),
                  ),

                  // ── Symptoms checklist ──
                  const SizedBox(height: 20),
                  const Text('Symptoms',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),

                  // Critical symptoms — red, with CRITICAL badge
                  ..._criticalSymptoms
                      .map((s) => _symptomRow(s, critical: true)),

                  // Normal symptoms — green
                  ..._normalSymptoms
                      .map((s) => _symptomRow(s, critical: false)),

                  // ── Mood selector — 4 emoji buttons ──
                  const SizedBox(height: 20),
                  const Text('How are you feeling emotionally?',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      {'e': '😊', 'l': 'Good'},
                      {'e': '😐', 'l': 'Tired'},
                      {'e': '😟', 'l': 'Anxious'},
                      {'e': '😢', 'l': 'Low'},
                    ].map((m) {
                      final active = _mood == m['l'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _mood = m['l']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primaryLight
                                  : AppColors.background,
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(m['e']!,
                                    style: const TextStyle(
                                        fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(m['l']!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: active
                                          ? AppColors.primary
                                          : AppColors.textHint,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── Submit button ──
                  const SizedBox(height: 28),
                  SalamaButton(
                    label: _hasCritical
                        ? 'Submit & Alert Hospital →'
                        : 'Update Recovery Plan →',
                    color: _hasCritical
                        ? AppColors.emergency
                        : AppColors.primary,
                    onTap: _submitCheckIn,
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

  /// Day counter +/− button
  Widget _counterBtn(IconData icon, VoidCallback onTap,
      {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: filled ? Colors.white : AppColors.primary,
            size: 20),
      ),
    );
  }

  /// Symptom checkbox row — red for critical, green for normal.
  /// Critical symptoms show a "CRITICAL" badge on the right.
  Widget _symptomRow(String symptom, {required bool critical}) {
    final checked = _symptoms[symptom] ?? false;
    final checkColor =
        critical ? AppColors.emergency : AppColors.success;
    final bgColor = checked
        ? (critical
            ? const Color(0xFFFFF0F0)
            : AppColors.successLight)
        : AppColors.background;

    return GestureDetector(
      onTap: () => setState(() => _symptoms[symptom] = !checked),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked ? checkColor : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: checked ? checkColor : Colors.white,
                border: Border.all(color: checkColor, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: checked
                  ? const Icon(Icons.check,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),

            // Symptom name
            Expanded(
                child: Text(symptom,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary))),

            // CRITICAL badge for critical symptoms
            if (critical)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emergency.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('CRITICAL',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.emergency,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  /// Submit check-in to Riverpod provider → FastAPI backend
  Future<void> _submitCheckIn() async {
    final selectedSymptoms = _symptoms.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // Save to Riverpod recovery provider
    ref.read(recoveryProvider.notifier).submitCheckIn(
          painLevel: _pain.round(),
          symptoms: selectedSymptoms,
          mood: _mood,
          hasCriticalSymptoms: _hasCritical,
        );

    if (mounted) {
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasCritical
                ? 'Alert sent to your hospital team'
                : 'Check-in submitted successfully',
          ),
          backgroundColor:
              _hasCritical ? AppColors.emergency : AppColors.success,
        ),
      );

      // Navigate to dashboard
      context.go(AppRoutes.dashboard);
    }
  }
}
