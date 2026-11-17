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

class PaymentSession {
  const PaymentSession({required this.tranId, required this.paymentUrl});
  final String tranId;
  final String paymentUrl;
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

  /// Opens an SSLCommerz session for already-created orders. The amount is
  /// computed by the server from the orders, never sent by the app.
  Future<PaymentSession> initPayment(List<String> orderIds) async {
    final res = await _api.post('/payments/sslcommerz/init', body: {'orderIds': orderIds, 'platform': 'mobile'});
    final data = asJson(res['data']);
    return PaymentSession(tranId: str(data['tranId'], ''), paymentUrl: str(data['paymentUrl'], ''));
  }

  /// Server-verified payment state: pending | paid | failed | cancelled | review.
  Future<String> paymentStatus(String tranId) async {
    final res = await _api.get('/payments/status/$tranId');
    return str(asJson(res['data'])['status'], 'pending');
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
