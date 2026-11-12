import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/storage/prefs.dart';
import '../data/models/cart_item.dart';
import '../data/repositories/catalog_repository.dart';

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    final prefs = ref.read(prefsProvider);
    return prefs.readJsonList(PrefKeys.cart).map(CartItem.fromJson).where((i) => i.variantId.isNotEmpty).toList();
  }

  void _commit(List<CartItem> items) {
    state = items;
    ref.read(prefsProvider).writeJsonList(PrefKeys.cart, items.map((e) => e.toJson()).toList());
  }

  /// Adds (or merges) a line. Returns the resulting quantity.
  int add(CartItem item) {
    final items = [...state];
    final idx = items.indexWhere((i) => i.variantId == item.variantId);
    int qty;
    if (idx >= 0) {
      final existing = items[idx];
      qty = (existing.quantity + item.quantity).clamp(1, item.maxQuantity);
      items[idx] = existing.copyWith(quantity: qty, price: item.price, stock: item.stock);
    } else {
      qty = item.quantity.clamp(1, item.maxQuantity);
      items.insert(0, item.copyWith(quantity: qty));
    }
    _commit(items);
    return qty;
  }

  void setQuantity(String variantId, int quantity) {
    if (quantity <= 0) {
      remove(variantId);
      return;
    }
    _commit([
      for (final i in state)
        if (i.variantId == variantId) i.copyWith(quantity: quantity.clamp(1, i.maxQuantity)) else i,
    ]);
  }

  CartItem? remove(String variantId) {
    final removed = state.where((i) => i.variantId == variantId).firstOrNull;
    _commit(state.where((i) => i.variantId != variantId).toList());
    return removed;
  }

  void restore(CartItem item, int index) {
    final items = [...state];
    items.insert(index.clamp(0, items.length), item);
    _commit(items);
  }

  void clear() => _commit(const []);

  /// Re-syncs price and stock for every line from the server.
  Future<void> refreshPrices() async {
    final repo = ref.read(catalogRepositoryProvider);
    final updated = <CartItem>[];
    for (final item in state) {
      try {
        final v = await repo.cartView(productId: item.productId, variantId: item.variantId);
        updated.add(
          item.copyWith(
            price: v.price,
            stock: v.stock,
            quantity: v.stock > 0 ? item.quantity.clamp(1, v.stock) : item.quantity,
          ),
        );
      } catch (_) {
        updated.add(item);
      }
    }
    _commit(updated);
  }
}

final cartProvider = NotifierProvider<CartController, List<CartItem>>(CartController.new);

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity));

class SellerGroup {
  const SellerGroup(this.sellerId, this.sellerName, this.items);
  final String sellerId;
  final String? sellerName;
  final List<CartItem> items;

  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);
}

class CartSummary {
  const CartSummary({required this.groups, required this.subtotal, required this.savings});

  final List<SellerGroup> groups;
  final double subtotal;
  final double savings;

  double get shipping => groups.isEmpty ? 0 : groups.length * Env.shippingPerSeller;
  double get total => subtotal + shipping;
  int get itemCount => groups.fold(0, (s, g) => s + g.items.fold(0, (a, i) => a + i.quantity));
}

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final items = ref.watch(cartProvider);
  final map = <String, List<CartItem>>{};
  for (final i in items) {
    map.putIfAbsent(i.sellerId, () => []).add(i);
  }
  final groups = map.entries
      .map((e) => SellerGroup(e.key, e.value.map((i) => i.sellerName).whereType<String>().firstOrNull, e.value))
      .toList();
  final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
  final savings = items.fold<double>(
    0,
    (s, i) => s + (i.originalPrice - i.price).clamp(0, double.infinity) * i.quantity,
  );
  return CartSummary(groups: groups, subtotal: subtotal, savings: savings);
});
