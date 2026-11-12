import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/models/product.dart';
import '../data/repositories/order_repository.dart';
import 'auth_controller.dart';

/// Orders for a status filter (`null` = all). Re-fetches when the user changes.
final ordersProvider = FutureProvider.autoDispose.family<Paged<Order>, String?>((ref, status) {
  ref.watch(currentUserProvider);
  return ref.watch(orderRepositoryProvider).list(status: status);
});

final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, id) => ref.watch(orderRepositoryProvider).byId(id),
);

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(orderRepositoryProvider).notifications();
});
