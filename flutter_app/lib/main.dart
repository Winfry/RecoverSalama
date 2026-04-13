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

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive and open the cache box
  await Hive.initFlutter();
  await CacheService.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize local notifications (must happen before any notification calls)
  await NotificationService.initialize();

  // Schedule the daily 9 AM check-in reminder
  await NotificationService.scheduleDailyCheckInReminder();

  runApp(
    const ProviderScope(
      child: SalamaRecoverApp(),
    ),
  );
}
