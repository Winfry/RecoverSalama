// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 02: Profile Setup (3 Steps)
// Collects everything the AI needs to personalise recovery.
// Step 1: Personal info. Step 2: Surgery details. Step 3: Diet & caregiver.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../recovery/providers/recovery_provider.dart';
import '../providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _step = 1;
  String _gender = 'Female';
  String _surgery = '';
  DateTime? _surgeryDate;

  // Step 1 controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  // Step 3 controllers
  final _allergiesCtrl = TextEditingController();
  final _caregiverCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  bool _isSaving = false;

  // Allergy toggles — from Kenya Nutrition Manual p.77
  final Map<String, bool> _allergyToggles = {
    'Milk/Dairy': false,
    'Eggs': false,
    'Peanuts': false,
    'Soya': false,
    'Seafood': false,
  };

  // 16 surgery types — covers most common surgeries in Kenya
  final List<String> _surgeries = [
    'Caesarean Section (C-Section)',
    'Inguinal Hernia Repair',
    'Appendectomy',
    'Laparotomy',
    'Hysterectomy',
    'Open Fracture Repair',
    'Tubal Ligation',
    'Cholecystectomy',
    'Prostatectomy',
    'Thyroidectomy',
    'Knee Replacement',
    'Hip Replacement',
    'Mastectomy',
    'Myomectomy',
    'Cardiac Surgery',
    'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _allergiesCtrl.dispose();
    _caregiverCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Purple header with progress bar ───────────────────────
  Widget _buildHeader() {
    final titles = [
      'Tell Us About You',
      'Your Surgery Details',
      'Diet & Caregiver',
    ];
    final subs = [
      'Help us personalise your recovery plan',
      'This drives all your AI recommendations',
      'Final step — almost done!',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF5C6BC0), // Purple
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button — goes to previous step or back to landing
              GestureDetector(
                onTap: () {
                  if (_step > 1) {
                    setState(() => _step--);
                  } else {
                    context.go(AppRoutes.landing);
                  }
                },
                child: const Text('← Back',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              const SizedBox(height: 14),

              // Progress bar — white filled/unfilled segments
              SalamaProgressBar(currentStep: _step, totalSteps: 3),
              const SizedBox(height: 10),

              // Step counter
              Text('Step $_step of 3',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 4),

              // Title + subtitle — changes per step
              Text(titles[_step - 1],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(subs[_step - 1],
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Personal Info ─────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SalamaInput(
          label: 'Full Name',
          placeholder: 'e.g. Amina Wanjiru',
          helperText: 'Used to personalise your care plan',
          controller: _nameCtrl,
        ),
        SalamaInput(
          label: 'Age',
          placeholder: 'e.g. 34',
          keyboardType: TextInputType.number,
          controller: _ageCtrl,
        ),

        // Gender pill selector — Female/Male/Other
        const Text('Gender',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: ['Female', 'Male', 'Other'].map((g) {
            final selected = _gender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryLight
                        : Colors.white,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(g,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Step 2: Surgery Details ───────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Surgery type dropdown — 16 options
        const Text('Surgery Type',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _surgery.isEmpty ? null : _surgery,
          hint: const Text('Select surgery type…',
              style: TextStyle(color: AppColors.textHint)),
          items: _surgeries
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (v) => setState(() => _surgery = v ?? ''),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.border, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This is the most important field — it drives all diet, activity, and risk recommendations.',
          style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),

        // Surgery date picker with calendar emoji
        const Text('Surgery Date',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) => Theme(
                data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: AppColors.primary)),
                child: child!,
              ),
            );
            if (date != null) setState(() => _surgeryDate = date);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _surgeryDate != null
                      ? '${_surgeryDate!.day}/${_surgeryDate!.month}/${_surgeryDate!.year}'
                      : 'Pick a date',
                  style: TextStyle(
                    color: _surgeryDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
                const Text('📅', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Weight — used for calorie calculations
        SalamaInput(
          label: 'Weight (kg)',
          placeholder: 'e.g. 68',
          keyboardType: TextInputType.number,
          controller: _weightCtrl,
          helperText: 'Used for calorie and protein calculations',
        ),
      ],
    );
  }

  // ── Step 3: Diet & Caregiver ──────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Allergy toggles with emoji icons
        const Text('Food Allergies',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
            'Toggle any that apply — we\'ll exclude these from your diet plan',
            style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        const SizedBox(height: 8),

        ..._allergyToggles.entries.map((entry) {
          final icons = {
            'Milk/Dairy': '🥛',
            'Eggs': '🥚',
            'Peanuts': '🥜',
            'Soya': '🫘',
            'Seafood': '🦐',
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color:
                  entry.value ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: entry.value
                    ? AppColors.primary
                    : AppColors.border,
                width: 1.5,
              ),
            ),
            child: SwitchListTile(
              title: Row(
                children: [
                  Text(icons[entry.key] ?? '',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(entry.key,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              value: entry.value,
              activeColor: AppColors.primary,
              onChanged: (v) {
                setState(() => _allergyToggles[entry.key] = v);
              },
            ),
          );
        }),
        const SizedBox(height: 8),

        // Other allergies — free text
        SalamaInput(
          label: 'Other Allergies / Restrictions',
          placeholder: 'e.g. Sulphur drugs, lactose intolerant…',
          controller: _allergiesCtrl,
          maxLines: 2,
        ),

        // Caregiver phone — for WhatsApp daily summaries
        SalamaInput(
          label: 'Caregiver Contact (Optional)',
          placeholder: '+254 7XX XXX XXX',
          controller: _caregiverCtrl,
          keyboardType: TextInputType.phone,
          helperText:
              'They will receive daily recovery updates via WhatsApp',
        ),
      ],
    );
  }

  // ── Save profile to Supabase via backend, then store locally ──
  Future<void> _completeSetup() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final allergies = _allergyToggles.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    try {
      // POST to /api/patients/profile — creates the patient row in Supabase
      await ref.read(apiServiceProvider).saveProfile({
        'name': _nameCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'gender': _gender,
        'surgery_type': _surgery,
        'surgery_date': _surgeryDate != null
            ? '${_surgeryDate!.year.toString().padLeft(4, '0')}-'
              '${_surgeryDate!.month.toString().padLeft(2, '0')}-'
              '${_surgeryDate!.day.toString().padLeft(2, '0')}'
            : null,
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'allergies': allergies,
        'other_allergies': _allergiesCtrl.text.trim(),
      });

      // Mirror into Riverpod so the rest of the app can read it instantly
      ref.read(profileProvider.notifier).saveProfile(
            name: _nameCtrl.text.trim(),
            age: int.tryParse(_ageCtrl.text) ?? 0,
            gender: _gender,
            surgeryType: _surgery,
            surgeryDate: _surgeryDate,
            hospital: '',
            surgeon: '',
            weight: double.tryParse(_weightCtrl.text) ?? 0,
            bloodType: '',
            allergies: allergies,
            otherAllergies: _allergiesCtrl.text.trim(),
          );

      if (!mounted) return;
      context.go(AppRoutes.preSurgery);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('SocketException') ||
                    e.toString().contains('connection')
                ? 'No internet. Check your network and try again.'
                : 'Could not save profile. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Purple header with progress bar
          _buildHeader(),

          // Step content — scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_step == 3) _buildStep3(),

                  const SizedBox(height: 8),

                  // Continue / Finish button
                  SalamaButton(
                    label: _step < 3
                        ? 'Save & Continue →'
                        : (_isSaving ? 'Saving…' : 'Finish Setup ✓'),
                    color: _step == 3
                        ? AppColors.success
                        : AppColors.primary,
                    onTap: (_step == 3 && _isSaving)
                        ? null
                        : () {
                            if (_step < 3) {
                              setState(() => _step++);
                            } else {
                              _completeSetup();
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
