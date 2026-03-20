import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/recovery_provider.dart';

/// Screen 04 — Daily Check-In
/// Pain slider (0-10), symptom toggles (with critical flags for fever/bleeding),
/// mood selection (4 emoji options), and "Update Recovery Plan" CTA.
/// Critical symptom banner appears if fever or wound bleeding selected.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  double _painLevel = 3;
  final Map<String, bool> _symptoms = {
    'Fever above 38°C': false,
    'Wound bleeding': false,
    'Nausea': false,
    'Mild headache': false,
    'Swelling': false,
    'Dizziness': false,
  };
  String? _selectedMood;

  // Critical symptoms that trigger alerts
  static const _criticalSymptoms = {'Fever above 38°C', 'Wound bleeding'};

  bool get _hasCriticalSymptoms =>
      _symptoms.entries.any((e) => e.value && _criticalSymptoms.contains(e.key));

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final day = profile.daysSinceSurgery;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Critical symptom banner
              if (_hasCriticalSymptoms)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppColors.emergencyLight,
                  child: const Row(
                    children: [
                      Text('⚠️', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Critical symptom detected — contact your hospital',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emergency,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Check-In',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'How are you feeling today?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Days since surgery counter
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Days Since Surgery',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$day',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pain Level Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pain Level',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_painLevel.toInt()}/10',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: _painLevel > 7
                          ? AppColors.emergency
                          : _painLevel > 4
                              ? AppColors.warning
                              : AppColors.success,
                      label: _painLevel.toInt().toString(),
                      onChanged: (v) => setState(() => _painLevel = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'No pain',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        Text(
                          'Severe',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Symptoms
                    const Text(
                      'Symptoms',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symptoms.entries.map((entry) {
                        final isCritical =
                            _criticalSymptoms.contains(entry.key);
                        final isSelected = entry.value;
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(entry.key),
                              if (isCritical && isSelected) ...[
                                const SizedBox(width: 4),
                                const Text('⚠',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: isCritical
                              ? AppColors.emergencyLight
                              : AppColors.primaryLight,
                          checkmarkColor: isCritical
                              ? AppColors.emergency
                              : AppColors.primary,
                          onSelected: (v) {
                            setState(() => _symptoms[entry.key] = v);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Mood Selection
                    const Text(
                      'How is your mood?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMoodButton('😊', 'Good'),
                        _buildMoodButton('😐', 'Tired'),
                        _buildMoodButton('😟', 'Anxious'),
                        _buildMoodButton('😢', 'Low'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit
                    ElevatedButton(
                      onPressed: _submitCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasCriticalSymptoms
                            ? AppColors.emergency
                            : AppColors.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _hasCriticalSymptoms
                                ? 'Submit & Alert Hospital'
                                : 'Update Recovery Plan',
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String label) {
    final isSelected = _selectedMood == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCheckIn() async {
    final selectedSymptoms =
        _symptoms.entries.where((e) => e.value).map((e) => e.key).toList();

    ref.read(recoveryProvider.notifier).submitCheckIn(
      painLevel: _painLevel.toInt(),
      symptoms: selectedSymptoms,
      mood: _selectedMood ?? 'Good',
      hasCriticalSymptoms: _hasCriticalSymptoms,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasCriticalSymptoms
                ? 'Alert sent to your hospital team'
                : 'Check-in submitted successfully',
          ),
          backgroundColor:
              _hasCriticalSymptoms ? AppColors.emergency : AppColors.success,
        ),
      );
    }
  }
}
