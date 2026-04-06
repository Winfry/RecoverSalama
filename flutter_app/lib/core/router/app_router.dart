import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/landing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
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
  static const String login = '/login';
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

/// Routes that require an authenticated session
const _protectedRoutes = {
  AppRoutes.dashboard,
  AppRoutes.checkIn,
  AppRoutes.aiChat,
  AppRoutes.diet,
  AppRoutes.hospital,
  AppRoutes.mentalHealth,
  AppRoutes.settings,
  AppRoutes.profileSetup,
  AppRoutes.preSurgery,
};

/// Notifies GoRouter to re-run redirect whenever the Supabase auth
/// stream emits (login, logout, token refresh, etc.)
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isAuthenticated =
          Supabase.instance.client.auth.currentUser != null;
      final location = state.matchedLocation;

      // Unauthenticated user trying to reach a protected screen → landing
      if (!isAuthenticated && _protectedRoutes.contains(location)) {
        return AppRoutes.landing;
      }

      // Authenticated user on landing or login → skip straight to dashboard
      if (isAuthenticated &&
          (location == AppRoutes.landing || location == AppRoutes.login)) {
        return AppRoutes.dashboard;
      }

      return null; // No redirect needed
    },
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

      // Login — no bottom nav
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
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
