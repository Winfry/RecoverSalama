// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 02: Profile Setup (3 Steps)
// Step 1: Surgery type (drives everything — required, card grid)
// Step 2: Personal details (name, age, gender, date, weight)
// Step 3: Diet & Caregiver
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../hospital/providers/hospital_provider.dart';
import '../../recovery/providers/recovery_provider.dart';
import '../providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

// ── Hospital picker bottom sheet ────────────────────────────
class _HospitalPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<String> onSelect;
  const _HospitalPickerSheet({required this.onSelect});

  @override
  ConsumerState<_HospitalPickerSheet> createState() =>
      _HospitalPickerSheetState();
}

class _HospitalPickerSheetState extends ConsumerState<_HospitalPickerSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(hospitalProvider).hospitals.isEmpty) {
        ref.read(hospitalProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalProvider);
    final q = _query.toLowerCase();
    final hospitals = state.hospitals
        .where((h) =>
            q.isEmpty ||
            h.name.toLowerCase().contains(q) ||
            h.address.toLowerCase().contains(q))
        .take(80)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('Select Hospital',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name or area…',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
            Expanded(
              child: hospitals.isEmpty
                  ? const Center(
                      child: Text('No hospitals found.',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: hospitals.length,
                      itemBuilder: (_, i) {
                        final h = hospitals[i];
                        return ListTile(
                          title: Text(h.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          subtitle: h.address.isNotEmpty
                              ? Text(h.address,
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: Text(h.typeLabel,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary)),
                          onTap: () {
                            widget.onSelect(h.name);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _step = 1;
  String _gender = 'Female';
  String _surgery = '';
  DateTime? _surgeryDate;

  // Step 2 controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // Step 3 controllers
  final _allergiesCtrl = TextEditingController();
  final _caregiverCtrl = TextEditingController();

  String _hospital = '';

  bool _isSaving = false;

  // Allergy toggles
  final Map<String, bool> _allergyToggles = {
    'Milk/Dairy': false,
    'Eggs': false,
    'Peanuts': false,
    'Soya': false,
    'Seafood': false,
  };

  // Surgery types with emoji, description, and healing context
  final List<Map<String, String>> _surgeries = [
    {
      'name': 'C-Section',
      'full': 'Caesarean Section (C-Section)',
      'emoji': '👶',
      'note': '6–8 weeks recovery',
    },
    {
      'name': 'Hernia Repair',
      'full': 'Inguinal Hernia Repair',
      'emoji': '🏥',
      'note': '2–4 weeks recovery',
    },
    {
      'name': 'Appendectomy',
      'full': 'Appendectomy',
      'emoji': '🫁',
      'note': '2–4 weeks recovery',
    },
    {
      'name': 'Laparotomy',
      'full': 'Laparotomy',
      'emoji': '🔬',
      'note': '4–8 weeks recovery',
    },
    {
      'name': 'Hysterectomy',
      'full': 'Hysterectomy',
      'emoji': '🌸',
      'note': '6–8 weeks recovery',
    },
    {
      'name': 'Fracture Repair',
      'full': 'Open Fracture Repair',
      'emoji': '🦴',
      'note': '8–12 weeks recovery',
    },
    {
      'name': 'Tubal Ligation',
      'full': 'Tubal Ligation',
      'emoji': '🔗',
      'note': '1–2 weeks recovery',
    },
    {
      'name': 'Gallbladder',
      'full': 'Cholecystectomy',
      'emoji': '💛',
      'note': '2–3 weeks recovery',
    },
    {
      'name': 'Prostatectomy',
      'full': 'Prostatectomy',
      'emoji': '💙',
      'note': '4–6 weeks recovery',
    },
    {
      'name': 'Thyroidectomy',
      'full': 'Thyroidectomy',
      'emoji': '🦋',
      'note': '2–3 weeks recovery',
    },
    {
      'name': 'Knee Replacement',
      'full': 'Knee Replacement',
      'emoji': '🦿',
      'note': '12+ weeks recovery',
    },
    {
      'name': 'Hip Replacement',
      'full': 'Hip Replacement',
      'emoji': '🦵',
      'note': '12+ weeks recovery',
    },
    {
      'name': 'Mastectomy',
      'full': 'Mastectomy',
      'emoji': '🎗️',
      'note': '4–6 weeks recovery',
    },
    {
      'name': 'Myomectomy',
      'full': 'Myomectomy',
      'emoji': '🌺',
      'note': '4–6 weeks recovery',
    },
    {
      'name': 'Cardiac Surgery',
      'full': 'Cardiac Surgery',
      'emoji': '❤️',
      'note': '8–12 weeks recovery',
    },
    {
      'name': 'Other Surgery',
      'full': 'Other',
      'emoji': '🏨',
      'note': 'AI will ask for details',
    },
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
    _caregiverCtrl.dispose();
    super.dispose();
  }

  // ── Header with progress bar ───────────────────────────────
  Widget _buildHeader() {
    final titles = [
      'What Surgery Did You Have?',
      'Tell Us About You',
      'Diet & Caregiver',
    ];
    final subs = [
      'This drives your diet, pain levels & healing plan',
      'Helps us personalise your recovery further',
      'Final step — almost done!',
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077B6), Color(0xFF00B37E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (_step > 1) {
                    setState(() => _step--);
                  } else {
                    context.go(AppRoutes.landing);
                  }
                },
                child: const Text('← Back',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              const SizedBox(height: 14),
              SalamaProgressBar(currentStep: _step, totalSteps: 3),
              const SizedBox(height: 10),
              Text('Step $_step of 3',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 4),
              Text(titles[_step - 1],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(subs[_step - 1],
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Surgery Type — card grid, REQUIRED ─────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Context banner explaining why this matters
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your surgery type determines your diet plan, expected pain levels, and healing timeline. Select carefully.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),

        // 2-column card grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemCount: _surgeries.length,
          itemBuilder: (context, i) {
            final s = _surgeries[i];
            final selected = _surgery == s['full'];
            return GestureDetector(
              onTap: () => setState(() => _surgery = s['full']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s['emoji']!,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      s['name']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['note']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected
                            ? AppColors.primary.withOpacity(0.7)
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Validation message if none selected
        if (_surgery.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.warning, size: 14),
                SizedBox(width: 6),
                Text(
                  'Please select your surgery type to continue',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 2: Personal Details ───────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show selected surgery as reminder
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Surgery: $_surgery',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success),
                ),
              ),
            ],
          ),
        ),

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

        // Gender selector
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
                    color: selected ? AppColors.primaryLight : Colors.white,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
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

        // Surgery date
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
                    colorScheme:
                        const ColorScheme.light(primary: AppColors.primary)),
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

        SalamaInput(
          label: 'Weight (kg)',
          placeholder: 'e.g. 68',
          keyboardType: TextInputType.number,
          controller: _weightCtrl,
          helperText: 'Used for calorie and protein calculations',
        ),

        const SizedBox(height: 16),
        const Text('Hospital (Optional)',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            if (ref.read(hospitalProvider).hospitals.isEmpty) {
              ref.read(hospitalProvider.notifier).load();
            }
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => _HospitalPickerSheet(
                onSelect: (name) => setState(() => _hospital = name),
              ),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _hospital.isNotEmpty
                    ? AppColors.primary
                    : AppColors.border,
                width: _hospital.isNotEmpty ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _hospital.isNotEmpty
                        ? _hospital
                        : 'Select your hospital…',
                    style: TextStyle(
                      color: _hospital.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Diet & Caregiver ───────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              color: entry.value ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: entry.value ? AppColors.primary : AppColors.border,
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
              onChanged: (v) =>
                  setState(() => _allergyToggles[entry.key] = v),
            ),
          );
        }),
        const SizedBox(height: 8),

        SalamaInput(
          label: 'Other Allergies / Restrictions',
          placeholder: 'e.g. Sulphur drugs, lactose intolerant…',
          controller: _allergiesCtrl,
          maxLines: 2,
        ),

        SalamaInput(
          label: 'Caregiver Contact (Optional)',
          placeholder: '+254 7XX XXX XXX',
          controller: _caregiverCtrl,
          keyboardType: TextInputType.phone,
          helperText:
              'They will receive daily recovery updates via WhatsApp (Phase 2)',
        ),
      ],
    );
  }

  // ── Save to backend + Riverpod ─────────────────────────────
  Future<void> _completeSetup() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final allergies = _allergyToggles.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    try {
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
        'caregiver_phone': _caregiverCtrl.text.trim(),
        'hospital': _hospital,
      });

      ref.read(profileProvider.notifier).setFromSetup({
        'id': '',
        'name': _nameCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'gender': _gender,
        'surgery_type': _surgery,
        'surgery_date': _surgeryDate,
        'hospital': _hospital,
        'surgeon': '',
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'blood_type': '',
        'allergies': allergies,
        'other_allergies': _allergiesCtrl.text.trim(),
        'phone': '',
        'caregiver_phone': _caregiverCtrl.text.trim(),
      });

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

  // ── Next / Finish button logic ─────────────────────────────
  void _handleNext() {
    // Step 1: surgery must be selected
    if (_step == 1) {
      if (_surgery.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your surgery type to continue.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      setState(() => _step++);
      return;
    }
    // Step 2: name must be filled
    if (_step == 2) {
      if (_nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your full name.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      setState(() => _step++);
      return;
    }
    // Step 3: save
    _completeSetup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_step == 3) _buildStep3(),
                  const SizedBox(height: 8),
                  SalamaButton(
                    label: _step < 3
                        ? 'Continue →'
                        : (_isSaving ? 'Saving…' : 'Finish Setup ✓'),
                    color: _step == 3
                        ? AppColors.success
                        : AppColors.primary,
                    onTap: (_step == 3 && _isSaving) ? null : _handleNext,
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
