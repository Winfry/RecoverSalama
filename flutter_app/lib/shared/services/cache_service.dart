import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Simple key-value cache backed by Hive.
///
/// Used to store the last successful API responses so the app can
/// show meaningful data when the patient has no internet connection.
/// Every patient in Kenya may have intermittent connectivity — this
/// ensures they always see their recovery data, not a blank screen.
class CacheService {
  static const _boxName = 'salama_cache';
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Save any JSON-serializable value under [key].
  static Future<void> set(String key, dynamic value) async {
    await _box?.put(key, jsonEncode(value));
  }

  /// Read a cached value. Returns null if not found or box not open.
  static Map<String, dynamic>? get(String key) {
    final raw = _box?.get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear a specific key (e.g., on logout).
  static Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  /// Clear everything (e.g., on logout).
  static Future<void> clear() async {
    await _box?.clear();
  }
}

/// Cache key constants — one place to manage all cache keys.
class CacheKeys {
  CacheKeys._();
  static const dashboard = 'dashboard';
  static const profile = 'profile';
  static const dietPlan = 'diet_plan';
}
