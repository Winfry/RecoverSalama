import 'package:flutter/material.dart';

/// SalamaRecover brand colors
class AppColors {
  AppColors._();

  // Primary brand
  static const Color primary = Color(0xFF0077B6);
  static const Color primaryLight = Color(0xFFEBF5FB);
  static const Color primaryDark = Color(0xFF005A8D);

  // Success / Green
  static const Color success = Color(0xFF00B37E);
  static const Color successLight = Color(0xFFE6F9F1);

  // Warning / Amber
  static const Color warning = Color(0xFFFFB703);
  static const Color warningLight = Color(0xFFFFF8E1);

  // Emergency / Red
  static const Color emergency = Color(0xFFE63946);
  static const Color emergencyLight = Color(0xFFFDE8EA);

  // Neutrals
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color border = Color(0xFFDEE2E6);
  static const Color divider = Color(0xFFE9ECEF);

  // Risk level colors
  static const Color riskLow = Color(0xFF00B37E);
  static const Color riskMedium = Color(0xFFFFB703);
  static const Color riskHigh = Color(0xFFE63946);
  static const Color riskEmergency = Color(0xFFB71C1C);

  // Splash screen gradient
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, success],
  );
}
