import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with a ready instance.
final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider must be overridden at startup');
});

extension PrefsJson on SharedPreferences {
  List<Map<String, dynamic>> readJsonList(String key) {
    final raw = getString(key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> value) => setString(key, jsonEncode(value));
}

abstract final class PrefKeys {
  static const onboarded = 'cb_onboarded';
  static const themeMode = 'cb_theme_mode';
  static const cart = 'cb_cart';
  static const wishlist = 'cb_wishlist';
  static const recentSearches = 'cb_recent_searches';
  static const lastCheckout = 'cb_last_checkout';
}
