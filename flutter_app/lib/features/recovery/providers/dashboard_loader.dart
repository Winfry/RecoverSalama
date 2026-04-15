import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/cache_service.dart';
import '../../profile/providers/profile_provider.dart';
import 'recovery_provider.dart';

/// Loads the dashboard from the backend on app start and after each check-in.
/// Caches the result so the app works offline.
final dashboardLoaderProvider = FutureProvider.autoDispose<void>((ref) async {
  final api = ref.read(apiServiceProvider);
  final profileNotifier = ref.read(profileProvider.notifier);
  final recoveryNotifier = ref.read(recoveryProvider.notifier);

  try {
    // Load profile if not yet loaded
    final profile = ref.read(profileProvider);
    if (!profile.isLoaded) {
      await profileNotifier.loadProfile();
    }

    // Load dashboard data
    final response = await api.getDashboard();
    final data = response.data as Map<String, dynamic>;

    // Cache for offline use
    await CacheService.set(CacheKeys.dashboard, data);

    // Update recovery state with backend data
    recoveryNotifier.updateFromDashboard(data);
  } catch (_) {
    // Offline fallback — load from cache
    final cached = CacheService.get(CacheKeys.dashboard);
    if (cached != null) {
      recoveryNotifier.updateFromDashboard(cached);
    }
  }
});
