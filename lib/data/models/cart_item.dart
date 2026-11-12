import '../../core/utils/json.dart';
import 'product.dart';

class CartItem {
  const CartItem({
    required this.variantId,
    required this.productId,
    required this.sellerId,
    required this.name,
    required this.slug,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.quantity,
    this.image,
    this.sku,
    this.attributes = const [],
    this.sellerName,
  });

  final String variantId;
  final String productId;
  final String sellerId;
  final String name;
  final String slug;
  final double price;
  final double originalPrice;
  final int stock;
  final int quantity;
  final String? image;
  final String? sku;
  final List<VariantAttribute> attributes;
  final String? sellerName;

  double get lineTotal => price * quantity;
  String get variantLabel => attributes.map((a) => a.value).join(' · ');
  int get maxQuantity => stock <= 0 ? 1 : stock;

  CartItem copyWith({int? quantity, double? price, int? stock}) => CartItem(
    variantId: variantId,
    productId: productId,
    sellerId: sellerId,
    name: name,
    slug: slug,
    price: price ?? this.price,
    originalPrice: originalPrice,
    stock: stock ?? this.stock,
    quantity: quantity ?? this.quantity,
    image: image,
    sku: sku,
    attributes: attributes,
    sellerName: sellerName,
  );

  factory CartItem.fromVariant(ProductDetail product, ProductVariant variant, int quantity) => CartItem(
    variantId: variant.id,
    productId: product.summary.id,
    sellerId: variant.sellerId.isNotEmpty ? variant.sellerId : product.summary.sellerId,
    name: product.summary.name,
    slug: product.summary.slug,
    price: variant.price,
    originalPrice: variant.originalPrice,
    stock: variant.stock,
    quantity: quantity,
    image: variant.image ?? product.summary.image,
    sku: variant.sku,
    attributes: variant.attributes,
    sellerName: product.sellerName,
  );

  factory CartItem.fromJson(Json j) => CartItem(
    variantId: str(j['variantId']),
    productId: str(j['productId']),
    sellerId: str(j['sellerId']),
    name: str(j['name']),
    slug: str(j['slug']),
    price: numOf(j['price']),
    originalPrice: numOf(j['originalPrice'], numOf(j['price'])),
    stock: intOf(j['stock']),
    quantity: intOf(j['quantity'], 1),
    image: strOrNull(j['image']),
    sku: strOrNull(j['sku']),
    attributes: asJsonList(j['attributes']).map(VariantAttribute.fromJson).toList(),
    sellerName: strOrNull(j['sellerName']),
  );

  Json toJson() => {
    'variantId': variantId,
    'productId': productId,
    'sellerId': sellerId,
    'name': name,
    'slug': slug,
    'price': price,
    'originalPrice': originalPrice,
    'stock': stock,
    'quantity': quantity,
    'image': image,
    'sku': sku,
    'attributes': attributes.map((a) => a.toJson()).toList(),
    'sellerName': sellerName,
  };
}
