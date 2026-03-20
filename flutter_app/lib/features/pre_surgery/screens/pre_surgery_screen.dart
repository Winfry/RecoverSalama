import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';

/// Screen 03 — Pre-Surgery Guidance
/// Health prep checklist, questions for doctor, emotional readiness section.
/// CTA: "Start Recovery" navigates to the recovery dashboard.
class PreSurgeryScreen extends ConsumerStatefulWidget {
  const PreSurgeryScreen({super.key});

  @override
  ConsumerState<PreSurgeryScreen> createState() => _PreSurgeryScreenState();
}

class _PreSurgeryScreenState extends ConsumerState<PreSurgeryScreen> {
  final Map<String, bool> _checklist = {
    'Complete blood tests': false,
    'Fast 8hrs before surgery': false,
    'Arrange transport home': false,
    'Pack hospital bag': false,
    'Sign consent forms': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: 0.55,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 24),

              const Text(
                'Pre-Surgery Guidance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Get ready — physically & emotionally',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Health Prep Checklist
              _buildSection(
                icon: '🏃',
                title: 'Health Prep Checklist',
                child: Column(
                  children: _checklist.entries.map((entry) {
                    return CheckboxListTile(
                      value: entry.value,
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: entry.value
                              ? TextDecoration.lineThrough
                              : null,
                          color: entry.value
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                      activeColor: AppColors.success,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        setState(() => _checklist[entry.key] = v ?? false);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Questions for Doctor
              _buildSection(
                icon: '❓',
                title: 'Questions for Doctor',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'How long is recovery?',
                    'What medications will I need?',
                    'When can I return to work?',
                    'What warning signs should I watch for?',
                  ].map((q) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✦ ',
                              style: TextStyle(color: AppColors.primary)),
                          Expanded(
                            child: Text(q,
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Emotional Readiness
              _buildSection(
                icon: '💚',
                title: 'Emotional Readiness',
                child: const Text(
                  'It is normal to feel nervous before surgery. '
                  'Talk to someone you trust — a family member, friend, '
                  'or call Befrienders Kenya at 0722 178 177.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // CTA
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Recovery'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
