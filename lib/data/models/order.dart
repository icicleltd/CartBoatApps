import '../../core/utils/json.dart';

/// Order lifecycle used for timelines and filters. Unknown statuses from the
/// API are still displayed using their raw (title-cased) value.
enum OrderStage {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  processing('processing', 'Processing'),
  shipped('shipped', 'Shipped'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStage(this.api, this.label);
  final String api;
  final String label;

  static OrderStage? fromApi(String? s) {
    final v = (s ?? '').toLowerCase();
    for (final st in values) {
      if (st.api == v) return st;
    }
    if (v == 'canceled' || v == 'rejected' || v == 'returned' || v == 'failed') return cancelled;
    if (v == 'completed') return delivered;
    if (v == 'on_the_way' || v == 'in_transit' || v == 'out_for_delivery') return shipped;
    return null;
  }

  static const timeline = [pending, confirmed, processing, shipped, delivered];
}

class PaymentMethodOption {
  const PaymentMethodOption(this.value, this.label, this.hint);
  final String value;
  final String label;
  final String hint;

  static const all = [
    PaymentMethodOption('cash_on_delivery', 'Cash on Delivery', 'Pay when your order arrives'),
    PaymentMethodOption('mobile_banking', 'Mobile Banking', 'bKash, Nagad, Rocket'),
    PaymentMethodOption('card', 'Card', 'Visa, Mastercard'),
    PaymentMethodOption('online', 'Online Payment', 'Pay securely online'),
  ];

  static String labelOf(String? value) {
    for (final m in all) {
      if (m.value == value) return m.label;
    }
    return value == null ? '—' : value.replaceAll('_', ' ');
  }
}

class OrderLine {
  const OrderLine({required this.name, required this.quantity, required this.price, this.image, this.variant});

  final String name;
  final int quantity;
  final double price;
  final String? image;
  final String? variant;

  factory OrderLine.fromJson(Json j) {
    final product = asJson(pick(j, ['productId', 'product']));
    final variant = asJson(pick(j, ['variantId', 'variant', 'variant_id']));
    final attrs = asJsonList(pick(j, ['attributes']) ?? variant['attributes']);
    return OrderLine(
      name: str(pick(j, ['productName', 'name', 'title']) ?? pick(product, ['name']), 'Item'),
      quantity: intOf(j['quantity'], 1),
      price: numOf(pick(j, ['unitPrice', 'sellingPrice', 'price']) ?? pick(variant, ['sellingPrice'])),
      image: usableImageUrl(
        pick(j, ['image', 'productImage']) ??
            pick(variant, ['image']) ??
            (strList(product['images']).isNotEmpty ? strList(product['images']).first : null),
      ),
      variant: attrs.isEmpty ? strOrNull(j['variantName']) : attrs.map((a) => str(a['value'])).join(' · '),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.lines,
    required this.total,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    this.paymentMethod,
    this.paymentStatus,
    this.createdAt,
    this.address,
    this.customerName,
    this.customerPhone,
    this.note,
  });

  final String id;
  final String number;
  final String status;
  final List<OrderLine> lines;
  final double total;
  final double subtotal;
  final double shipping;
  final double discount;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime? createdAt;
  final String? address;
  final String? customerName;
  final String? customerPhone;
  final String? note;

  OrderStage? get stage => OrderStage.fromApi(status);
  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  factory Order.fromJson(Json j) {
    final lines = asJsonList(pick(j, ['items', 'orderItems', 'products'])).map(OrderLine.fromJson).toList();
    final shipping = numOf(pick(j, ['shippingCharge', 'shipping_charge', 'deliveryCharge']));
    final computedSubtotal = lines.fold<double>(0, (s, l) => s + l.price * l.quantity);
    final subtotal = numOf(pick(j, ['subTotal', 'subtotal', 'itemsTotal']), computedSubtotal);
    final discount = numOf(pick(j, ['discountAmount', 'discount_amount', 'discount']));
    final total = numOf(
      pick(j, ['totalAmount', 'grandTotal', 'total', 'payableAmount', 'netAmount']),
      subtotal + shipping - discount,
    );
    final addr = asJson(pick(j, ['shippingAddress', 'shipping_address']));
    final addressText = [
      addr['address'],
      addr['city'],
      addr['zip'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    return Order(
      id: str(pick(j, ['_id', 'id'])),
      number: str(pick(j, ['orderNumber', 'orderNo', 'invoiceNumber', 'orderId']), ''),
      status: str(pick(j, ['orderStatus', 'status']), 'pending'),
      lines: lines,
      total: total,
      subtotal: subtotal,
      shipping: shipping,
      discount: discount,
      paymentMethod: strOrNull(pick(j, ['paymentMethod', 'payment_method'])),
      paymentStatus: strOrNull(pick(j, ['paymentStatus', 'payment_status'])),
      createdAt: dateOf(pick(j, ['createdAt', 'orderDate'])),
      address: addressText.isEmpty ? null : addressText,
      customerName: strOrNull(pick(addr, ['name']) ?? j['name']),
      customerPhone: strOrNull(pick(addr, ['phone']) ?? j['phone']),
      note: strOrNull(j['note']),
    );
  }

  String get displayNumber {
    if (number.isNotEmpty) return number.startsWith('#') ? number : '#$number';
    return '#${id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase()}';
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.type,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String? type;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Json j) => AppNotification(
    id: str(pick(j, ['_id', 'id'])),
    title: str(pick(j, ['title', 'subject', 'type']), 'Notification'),
    message: str(pick(j, ['message', 'body', 'content', 'description'])),
    isRead: boolOf(pick(j, ['isRead', 'read', 'seen'])),
    type: strOrNull(j['type']),
    createdAt: dateOf(j['createdAt']),
  );
}
