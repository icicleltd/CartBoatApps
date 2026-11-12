import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/prefs.dart';
import '../data/models/product.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.read(prefsProvider).getString(PrefKeys.themeMode);
    return ThemeMode.values.firstWhere((m) => m.name == raw, orElse: () => ThemeMode.system);
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(prefsProvider).setString(PrefKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class WishlistController extends Notifier<List<ProductSummary>> {
  @override
  List<ProductSummary> build() =>
      ref.read(prefsProvider).readJsonList(PrefKeys.wishlist).map(ProductSummary.fromJson).toList();

  bool contains(String productId) => state.any((p) => p.id == productId);

  /// Returns true when the product is now saved.
  bool toggle(ProductSummary product) {
    final saved = contains(product.id);
    state = saved ? state.where((p) => p.id != product.id).toList() : [product, ...state];
    ref.read(prefsProvider).writeJsonList(PrefKeys.wishlist, state.map((p) => p.toJson()).toList());
    return !saved;
  }
}

final wishlistProvider = NotifierProvider<WishlistController, List<ProductSummary>>(WishlistController.new);

final isWishlistedProvider = Provider.family<bool, String>(
  (ref, id) => ref.watch(wishlistProvider).any((p) => p.id == id),
);

class RecentSearchesController extends Notifier<List<String>> {
  @override
  List<String> build() => ref.read(prefsProvider).getStringList(PrefKeys.recentSearches) ?? const [];

  void add(String term) {
    final t = term.trim();
    if (t.isEmpty) return;
    state = [t, ...state.where((s) => s.toLowerCase() != t.toLowerCase())].take(8).toList();
    ref.read(prefsProvider).setStringList(PrefKeys.recentSearches, state);
  }

  void remove(String term) {
    state = state.where((s) => s != term).toList();
    ref.read(prefsProvider).setStringList(PrefKeys.recentSearches, state);
  }

  void clear() {
    state = const [];
    ref.read(prefsProvider).remove(PrefKeys.recentSearches);
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearchesController, List<String>>(RecentSearchesController.new);

/// Saved contact/shipping details so repeat checkouts are one tap.
final lastCheckoutProvider = Provider<Map<String, dynamic>>((ref) {
  final list = ref.watch(prefsProvider).readJsonList(PrefKeys.lastCheckout);
  return list.isEmpty ? const {} : list.first;
});
