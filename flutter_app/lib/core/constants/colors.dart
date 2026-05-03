import 'package:flutter/material.dart';

/// Pona Salama brand colors — teal-green design system
class AppColors {
  AppColors._();

  // Primary brand — teal green
  static const Color primary = Color(0xFF00B494);
  static const Color primaryLight = Color(0xFFE6F9F5);
  static const Color primaryDark = Color(0xFF008B72);

  // Success / deeper green
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);

  // Warning / Amber
  static const Color warning = Color(0xFFFFB703);
  static const Color warningLight = Color(0xFFFFF8E1);

  // Emergency / Red
  static const Color emergency = Color(0xFFEF4444);
  static const Color emergencyLight = Color(0xFFFEE2E2);

  // Neutrals
  static const Color background = Color(0xFFF8FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1C1C2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Risk level colors
  static const Color riskLow = Color(0xFF22C55E);
  static const Color riskMedium = Color(0xFFFFB703);
  static const Color riskHigh = Color(0xFFEF4444);
  static const Color riskEmergency = Color(0xFFB91C1C);

  // Splash / logo gradient
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, Color(0xFF00C896)],
  );

  // Brand gradient (hero headers)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B494), Color(0xFF00C896)],
  );
}
