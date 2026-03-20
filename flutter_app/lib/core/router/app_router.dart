import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/landing_screen.dart';
import '../../features/profile/screens/profile_setup_screen.dart';
import '../../features/pre_surgery/screens/pre_surgery_screen.dart';
import '../../features/recovery/screens/dashboard_screen.dart';
import '../../features/recovery/screens/checkin_screen.dart';
import '../../features/ai_chat/screens/ai_chat_screen.dart';
import '../../features/mental_health/screens/mental_health_screen.dart';
import '../../features/diet/screens/diet_screen.dart';
import '../../features/hospital/screens/hospital_connect_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

/// Route path constants
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String landing = '/landing';
  static const String profileSetup = '/profile-setup';
  static const String preSurgery = '/pre-surgery';
  static const String dashboard = '/dashboard';
  static const String checkIn = '/check-in';
  static const String aiChat = '/ai-chat';
  static const String mentalHealth = '/mental-health';
  static const String diet = '/diet';
  static const String hospital = '/hospital';
  static const String settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash — no bottom nav
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Landing — no bottom nav
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingScreen(),
      ),

      // Profile Setup — no bottom nav
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Pre-Surgery — no bottom nav
      GoRoute(
        path: AppRoutes.preSurgery,
        builder: (context, state) => const PreSurgeryScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.checkIn,
            builder: (context, state) => const CheckInScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            builder: (context, state) => const AiChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.diet,
            builder: (context, state) => const DietScreen(),
          ),
          GoRoute(
            path: AppRoutes.hospital,
            builder: (context, state) => const HospitalConnectScreen(),
          ),
        ],
      ),

      // Mental Health — accessed from dashboard
      GoRoute(
        path: AppRoutes.mentalHealth,
        builder: (context, state) => const MentalHealthScreen(),
      ),

      // Settings
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
