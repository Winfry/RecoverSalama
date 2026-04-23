import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env first — Supabase and ApiService both depend on it.
  // If this fails, show a clear error instead of a blank screen.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('FATAL: could not load .env — $e');
    runApp(_EnvErrorApp());
    return;
  }

  try {
    await Hive.initFlutter();
    await CacheService.init();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    await NotificationService.initialize();
    await NotificationService.scheduleDailyCheckInReminder();
  } catch (e) {
    debugPrint('Startup error (non-fatal): $e');
  }

  runApp(
    const ProviderScope(
      child: SalamaRecoverApp(),
    ),
  );
}

/// Shown only when the .env asset is missing from the build.
class _EnvErrorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Configuration missing.\nPlease rebuild the app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
