import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/json.dart';
import '../models/order.dart';
import '../models/product.dart';

class PlacedOrder {
  const PlacedOrder({required this.id, required this.number, required this.total, required this.message});
  final String id;
  final String number;
  final double total;
  final String message;
}

class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  Future<PlacedOrder> create(Map<String, dynamic> body) async {
    final res = await _api.post('/orders', body: body);
    final data = asJson(res['data']);
    final order = Order.fromJson(data);
    return PlacedOrder(
      id: order.id,
      number: order.displayNumber,
      total: order.total,
      message: str(res['message'], 'Order placed'),
    );
  }

  Future<Paged<Order>> list({int page = 1, String? status}) async {
    final res = await _api.get(
      '/orders',
      query: {'page': page, 'limit': 15, 'orderStatus': status, 'sortBy': 'createdAt', 'sortOrder': 'desc'},
    );
    final raw = res['data'];
    final list = raw is List ? asJsonList(raw) : asJsonList(pick(asJson(raw), ['orders', 'items', 'docs', 'data']));
    final pagination = asJson(res['pagination'] ?? asJson(raw)['pagination']);
    return Paged(
      items: list.map(Order.fromJson).toList(),
      page: intOf(pagination['page'], page),
      total: intOf(pagination['total'], list.length),
      hasNext: boolOf(pagination['hasNext']),
    );
  }

  Future<Order> byId(String id) async {
    final res = await _api.get('/orders/$id');
    final data = asJson(res['data']);
    return Order.fromJson(data['order'] is Map ? asJson(data['order']) : data);
  }

  Future<List<AppNotification>> notifications() async {
    final res = await _api.get('/notifications/');
    final raw = res['data'];
    final list = raw is List ? asJsonList(raw) : asJsonList(pick(asJson(raw), ['notifications', 'items', 'docs']));
    return list.map(AppNotification.fromJson).toList();
  }
}

final orderRepositoryProvider = Provider((ref) => OrderRepository(ref.watch(apiClientProvider)));
