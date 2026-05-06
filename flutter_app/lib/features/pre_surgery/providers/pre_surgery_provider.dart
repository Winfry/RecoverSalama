import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreSurgeryNotifier extends StateNotifier<Map<String, bool>> {
  static const _prefix = 'ps_check_';

  PreSurgeryNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, bool>{};
    for (final k in prefs.getKeys()) {
      if (k.startsWith(_prefix)) {
        loaded[k.substring(_prefix.length)] = prefs.getBool(k) ?? false;
      }
    }
    state = loaded;
  }

  Future<void> toggle(String key) async {
    final newVal = !(state[key] ?? false);
    state = {...state, key: newVal};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', newVal);
  }

  bool isChecked(String key) => state[key] ?? false;

  int checkedInSection(String sectionId, int itemCount) {
    int n = 0;
    for (int i = 0; i < itemCount; i++) {
      if (state['${sectionId}_$i'] ?? false) n++;
    }
    return n;
  }
}

final preSurgeryProvider =
    StateNotifierProvider<PreSurgeryNotifier, Map<String, bool>>(
  (_) => PreSurgeryNotifier(),
);
