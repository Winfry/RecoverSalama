import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../providers/mental_health_provider.dart';

/// Screen 07 — Mental Health Check-In
/// 4 mood options (Okay, Tired, Anxious, Overwhelmed) displayed as large tappable cards.
/// AI responds based on selected mood. Shows Befrienders Kenya helpline.
/// "Done for Today" dismisses the check-in.
class MentalHealthScreen extends ConsumerStatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  ConsumerState<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends ConsumerState<MentalHealthScreen> {
  String? _selectedMood;

  final _moods = [
    {'emoji': '😊', 'label': 'Okay', 'subtitle': 'Feeling well'},
    {'emoji': '😐', 'label': 'Tired', 'subtitle': 'Exhausted'},
    {'emoji': '😟', 'label': 'Anxious', 'subtitle': 'Worried'},
    {'emoji': '😢', 'label': 'Overwhelmed', 'subtitle': 'Struggling'},
  ];

  String _getAiResponse(String mood) {
    switch (mood) {
      case 'Okay':
        return 'That is wonderful! Keep the positivity — it genuinely supports healing.';
      case 'Tired':
        return 'Rest is your body\'s way of healing. Try a 20-minute nap and keep hydrated with warm water.';
      case 'Anxious':
        return 'Anxiety after surgery is very common. Try deep breathing: inhale 4 seconds, hold 4, exhale 6. You are safe.';
      case 'Overwhelmed':
        return 'You don\'t have to do this alone. Please reach out to a loved one or call Befrienders Kenya at 0722 178 177.';
      default:
        return 'Thank you for checking in. Your feelings matter.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('🧠', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                'Mental Health Check-In',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your emotional wellbeing matters as much as physical healing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'How are you feeling today?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap what describes you now',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Mood cards — 2x2 grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['label'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMood = mood['label'] as String);
                      ref.read(mentalHealthProvider.notifier).selectMood(
                            mood['label'] as String,
                          );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood['emoji'] as String,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            mood['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // AI Response (shows after mood selection)
              if (_selectedMood != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💚 AI Response',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getAiResponse(_selectedMood!),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Done for Today button
              ElevatedButton(
                onPressed: _selectedMood != null
                    ? () => Navigator.of(context).pop()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Done for Today'),
                    SizedBox(width: 8),
                    Icon(Icons.check, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Befrienders Kenya helpline
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Text('📞', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Befrienders Kenya',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '0722 178 177 — Free & confidential',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
}
