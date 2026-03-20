import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/profile_provider.dart';

/// Screen 02 — Profile Setup (3-step)
/// Step 1: Personal info (name, age, gender, surgery type, surgery date)
/// Step 2: Medical details (hospital, surgeon, blood type, weight)
/// Step 3: Allergies & diet preferences (toggles for milk, eggs, peanuts, soya, seafood)
/// Progress bar at top shows current step.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Step 1 controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedSurgeryType;
  DateTime? _surgeryDate;

  // Step 2 controllers
  final _hospitalController = TextEditingController();
  final _surgeonController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedBloodType;

  // Step 3 — allergies
  final Map<String, bool> _allergies = {
    'Milk/Dairy': false,
    'Eggs': false,
    'Peanuts': false,
    'Soya': false,
    'Seafood': false,
  };
  final _otherAllergiesController = TextEditingController();

  static const List<String> _surgeryTypes = [
    'Caesarean Section',
    'Appendectomy',
    'Hernia Repair',
    'Cholecystectomy',
    'Knee Replacement',
    'Hip Replacement',
    'Mastectomy',
    'Other',
  ];

  static const List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _hospitalController.dispose();
    _surgeonController.dispose();
    _weightController.dispose();
    _otherAllergiesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.landing);
    }
  }

  Future<void> _completeSetup() async {
    // Save profile data via provider
    ref.read(profileProvider.notifier).saveProfile(
      name: _nameController.text,
      age: int.tryParse(_ageController.text) ?? 0,
      gender: _selectedGender ?? '',
      surgeryType: _selectedSurgeryType ?? '',
      surgeryDate: _surgeryDate,
      hospital: _hospitalController.text,
      surgeon: _surgeonController.text,
      weight: double.tryParse(_weightController.text) ?? 0,
      bloodType: _selectedBloodType ?? '',
      allergies: _allergies.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      otherAllergies: _otherAllergiesController.text,
    );

    // Navigate to pre-surgery guidance
    if (mounted) {
      context.go(AppRoutes.preSurgery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        title: const Text('Back'),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Step pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Personal Info
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell Us About You',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Help us personalise your recovery',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildLabel('Full Name'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Amina Wanjiru'),
          ),
          const SizedBox(height: 16),

          _buildLabel('Age'),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 34'),
          ),
          const SizedBox(height: 16),

          _buildLabel('Gender'),
          Row(
            children: ['Female', 'Male', 'Other'].map((g) {
              final isSelected = _selectedGender == g;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (_) => setState(() => _selectedGender = g),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _buildLabel('Surgery Type'),
          DropdownButtonFormField<String>(
            value: _selectedSurgeryType,
            decoration: const InputDecoration(hintText: 'Select surgery type…'),
            items: _surgeryTypes
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedSurgeryType = v),
          ),
          const SizedBox(height: 16),

          _buildLabel('Surgery Date'),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _surgeryDate = date);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                hintText: 'Pick a date',
                suffixIcon: Icon(Icons.calendar_today, size: 20),
              ),
              child: Text(
                _surgeryDate != null
                    ? '${_surgeryDate!.day}/${_surgeryDate!.month}/${_surgeryDate!.year}'
                    : 'Pick a date',
                style: TextStyle(
                  color: _surgeryDate != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _nextStep,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Save & Continue'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2: Medical Details
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Help your care team support you',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildLabel('Hospital'),
          TextField(
            controller: _hospitalController,
            decoration: const InputDecoration(
              hintText: 'e.g. Kenyatta National Hospital',
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Surgeon Name (optional)'),
          TextField(
            controller: _surgeonController,
            decoration: const InputDecoration(hintText: 'e.g. Dr. Ochieng'),
          ),
          const SizedBox(height: 16),

          _buildLabel('Weight (kg)'),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 68'),
          ),
          const SizedBox(height: 16),

          _buildLabel('Blood Type'),
          DropdownButtonFormField<String>(
            value: _selectedBloodType,
            decoration: const InputDecoration(hintText: 'Select blood type'),
            items: _bloodTypes
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _selectedBloodType = v),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _nextStep,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Save & Continue'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 3: Allergies & Diet Preferences
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allergies & Diet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'We\'ll exclude these from your diet plan',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildLabel('Food Allergies'),
          ..._allergies.entries.map((entry) {
            final icons = {
              'Milk/Dairy': '🥛',
              'Eggs': '🥚',
              'Peanuts': '🥜',
              'Soya': '🫘',
              'Seafood': '🦐',
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Text(icons[entry.key] ?? '', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(entry.key),
                  ],
                ),
                value: entry.value,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _allergies[entry.key] = v);
                },
              ),
            );
          }),

          const SizedBox(height: 16),

          _buildLabel('Other allergies'),
          TextField(
            controller: _otherAllergiesController,
            decoration: const InputDecoration(
              hintText: 'e.g. Sulphur drugs',
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Complete Setup'),
                SizedBox(width: 8),
                Icon(Icons.check, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
