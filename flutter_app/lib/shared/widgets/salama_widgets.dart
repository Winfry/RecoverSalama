// ─────────────────────────────────────────────────────────────
// SalamaRecover — Shared Widgets
// Reusable UI components used across all 9 screens.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

// ── Primary Button ───────────────────────────────────────────
// Full-width action button. Used on every screen.
// Set outlined=true for secondary actions (e.g., Guest Mode).
class SalamaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final bool outlined;

  const SalamaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              outlined ? Colors.transparent : (color ?? AppColors.primary),
          foregroundColor: textColor ?? Colors.white,
          side: outlined
              ? BorderSide(color: color ?? AppColors.primary, width: 1.5)
              : BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: outlined ? 0 : 2,
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ── Emergency Banner ─────────────────────────────────────────
// Red banner that appears at the top of screens when risk is
// HIGH or EMERGENCY. Shows warning message + optional Call button.
// This is a SAFETY FEATURE and must never be removed.
class EmergencyBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onCall;

  const EmergencyBanner({super.key, required this.message, this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.emergency,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text("⚠️", style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          if (onCall != null)
            GestureDetector(
              onTap: onCall,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Call",
                    style: TextStyle(
                        color: AppColors.emergency,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation Bar ────────────────────────────────────
// 5-tab bottom nav: Home, Plan, AI, Diet, Doctor.
// Uses emoji icons for cross-platform consistency.
class SalamaBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SalamaBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {"icon": "🏠", "label": "Home"},
      {"icon": "📋", "label": "Plan"},
      {"icon": "🤖", "label": "AI"},
      {"icon": "🥗", "label": "Diet"},
      {"icon": "🏥", "label": "Doctor"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(items[i]["icon"]!,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(items[i]["label"]!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: active
                          ? AppColors.primary
                          : AppColors.textHint,
                    )),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Input Field ──────────────────────────────────────────────
// Styled text field with label, placeholder, and optional helper text.
// Used in Profile Setup, Hospital Search, etc.
class SalamaInput extends StatelessWidget {
  final String label;
  final String placeholder;
  final String? helperText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const SalamaInput({
    super.key,
    required this.label,
    required this.placeholder,
    this.helperText,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle:
                const TextStyle(color: AppColors.textHint, fontSize: 14),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText!,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 11)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Progress Bar (Profile Setup) ─────────────────────────────
// Step indicator with filled/unfilled segments.
// Used in the 3-step profile setup flow.
class SalamaProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SalamaProgressBar(
      {super.key, required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: i < currentStep
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ── Benefit Card ─────────────────────────────────────────────
// Feature card shown on the Landing Page.
// Alternates between blue and green backgrounds.
class BenefitCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final bool isBlue;

  const BenefitCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.desc,
      this.isBlue = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isBlue ? AppColors.primaryLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isBlue
                ? const Color(0xFFD0E8F5)
                : const Color(0xFFC6F0DE)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
