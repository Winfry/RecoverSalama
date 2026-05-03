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

  final _critical = [
    'Fever', 'Bleeding', 'Trouble breathing', 'Severe swelling',
  ];
  final _normal = [
    'Nausea', 'Fatigue', 'Mild pain', 'Constipation',
  ];

  bool get _hasCritical => _critical.any((s) => _symptoms[s] == true);

  Color get _painColor {
    if (_pain <= 3) return AppColors.primary;
    if (_pain <= 6) return AppColors.warning;
    return AppColors.emergency;
  }

  final _moods = [
    {'e': '😊', 'l': 'Good'},
    {'e': '😁', 'l': 'Great'},
    {'e': '😢', 'l': 'Sad'},
    {'e': '😤', 'l': 'Tired'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = ref.read(profileProvider);
      if (p.daysSinceSurgery > 0) setState(() => _days = p.daysSinceSurgery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (_hasCritical)
            EmergencyBanner(
              message: 'Critical symptom detected — consider contacting your hospital',
              onCall: () => context.go(AppRoutes.hospital),
            ),

          // ── Header ──
          Container(
            color: AppColors.surface,
            child: SafeArea(
              top: !_hasCritical,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.dashboard),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 20, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Check-In',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            Text('How are you feeling today?',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Day counter info ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Day $_days since surgery',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Pain level ──
                  _sectionLabel('Pain level'),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('No pain',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _painColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_pain.round()} / 10',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Text('Worst pain',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _painColor,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: _painColor,
                      overlayColor: _painColor.withOpacity(0.15),
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: _pain,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (v) => setState(() => _pain = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Mood ──
                  _sectionLabel('Mood'),
                  const SizedBox(height: 10),
                  Row(
                    children: _moods.map((m) {
                      final active = _mood == m['l'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mood = m['l']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primaryLight
                                  : AppColors.surface,
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: active ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(m['e']!,
                                    style: const TextStyle(fontSize: 24)),
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
                  const SizedBox(height: 22),

                  // ── Critical symptoms ──
                  _sectionLabel('Critical symptoms (seek help immediately)',
                      color: AppColors.emergency),
                  const SizedBox(height: 8),
                  ..._critical.map((s) => _symptomRow(s, critical: true)),
                  const SizedBox(height: 16),

                  // ── Normal symptoms ──
                  _sectionLabel('Normal symptoms'),
                  const SizedBox(height: 8),
                  ..._normal.map((s) => _symptomRow(s, critical: false)),
                  const SizedBox(height: 28),

                  // ── Submit ──
                  Consumer(
                    builder: (ctx, ref, _) {
                      final loading = ref.watch(recoveryProvider).isLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasCritical
                                ? AppColors.emergency
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  _hasCritical
                                      ? 'Submit & Alert Hospital →'
                                      : 'Save Check-In',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      );
                    },
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

  Widget _sectionLabel(String text, {Color color = AppColors.textPrimary}) =>
      Text(text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color));

  Widget _symptomRow(String symptom, {required bool critical}) {
    final checked = _symptoms[symptom] ?? false;
    final c = critical ? AppColors.emergency : AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _symptoms[symptom] = !checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: checked
              ? (critical
                  ? AppColors.emergencyLight
                  : AppColors.primaryLight)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: checked ? c : AppColors.border,
            width: checked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? c : Colors.white,
                border: Border.all(color: c, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(symptom,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
            ),
            if (critical)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emergencyLight,
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

  Future<void> _submit() async {
    final selected =
        _symptoms.entries.where((e) => e.value).map((e) => e.key).toList();

    await ref.read(recoveryProvider.notifier).submitCheckIn(
          painLevel: _pain.round(),
          symptoms: selected,
          mood: _mood,
          daysSinceSurgery: _days,
        );
    if (!mounted) return;

    final recovery = ref.read(recoveryProvider);
    if (recovery.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(recovery.errorMessage),
        backgroundColor: AppColors.emergency,
      ));
      ref.read(recoveryProvider.notifier).clearError();
      return;
    }

    final riskLevel = recovery.riskLevel;
    final Color snackColor = switch (riskLevel) {
      'EMERGENCY' || 'HIGH' => AppColors.emergency,
      'MEDIUM' => AppColors.warning,
      _ => AppColors.primary,
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (riskLevel) {
        'EMERGENCY' => 'EMERGENCY — Alert sent to hospital',
        'HIGH' => 'High risk — hospital has been notified',
        'MEDIUM' => 'Medium risk — monitor symptoms closely',
        _ => 'Check-in submitted — you\'re doing great!',
      }),
      backgroundColor: snackColor,
      duration: const Duration(seconds: 4),
    ));
    context.go(AppRoutes.dashboard);
  }
}
