import 'package:cartboat/core/storage/prefs.dart';
import 'package:cartboat/core/utils/formatters.dart';
import 'package:cartboat/core/utils/spec_parser.dart';
import 'package:cartboat/data/models/cart_item.dart';
import 'package:cartboat/data/models/category.dart';
import 'package:cartboat/data/models/product.dart';
import 'package:cartboat/features/product/variant_selector.dart';
import 'package:cartboat/state/cart_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('pricing', () {
    test('original price is derived from the discount percentage like the web store', () {
      final p = ProductSummary.fromJson({
        '_id': '1',
        'name': 'iPhone 11 Pro',
        'slug': 'iphone-11-pro-1',
        'images': ['https://res.cloudinary.com/x.jpg', 'blob:https://bad'],
        'sellingPrice': 28990,
        'discount': 12,
        'displayPriceMin': 28990,
        'displayPriceMax': 28990,
        'totalStock': 12,
        'productType': 'PRE_OWNED',
      });
      expect(p.originalPrice.round(), 32943);
      expect(p.images, hasLength(1), reason: 'blob: URLs are unusable');
      expect(p.condition, ProductCondition.preOwned);
      expect(money(28990), '৳28,990');
    });
  });

  test('parses quoted specification strings', () {
    final rows = parseSpecifications('"Display": "5.8-inch OLED",\n      "RAM": "4GB RAM"');
    expect(rows.map((e) => e.key), ['Display', 'RAM']);
    expect(rows.last.value, '4GB RAM');
    expect(parseSpecifications('Material: Cotton\nFit: Slim').length, 2);
  });

  test('builds the category tree from the flat menu payload', () {
    final roots = CategoryNode.buildTree([
      {
        'name': 'Electronics',
        'slug': 'electronics',
        'slugPath': ['electronics'],
        'depth': 0,
        'parentSlugPath': null,
      },
      {
        'name': 'Mobile Phones',
        'slug': 'mobile-phones',
        'slugPath': ['electronics', 'mobile-phones'],
        'depth': 1,
        'parentSlugPath': ['electronics'],
      },
      {
        'name': 'Dress',
        'slug': 'dress',
        'slugPath': ['dress'],
        'depth': 0,
        'parentSlugPath': null,
      },
    ]);
    expect(roots.map((r) => r.slug), ['electronics', 'dress']);
    expect(roots.first.children.single.slug, 'mobile-phones');
  });

  test('variant resolution keeps other selected attributes', () {
    ProductVariant v(String id, String color, String size, int stock) => ProductVariant.fromJson({
      '_id': id,
      'attributes': [
        {'key': 'color', 'value': color},
        {'key': 'size', 'value': size},
      ],
      'sellingPrice': 100,
      'stock': stock,
    });
    final product = ProductDetail(
      summary: ProductSummary.fromJson({'_id': 'p', 'name': 'Tee', 'slug': 'tee'}),
      variants: [v('a', 'Red', 'M', 1), v('b', 'Blue', 'M', 1), v('c', 'Blue', 'L', 1)],
    );
    final picked = resolveVariant(product, product.variants.first, 'color', 'Blue');
    expect(picked.id, 'b', reason: 'size M should be preserved');
  });

  test('cart splits into one shipment per seller with flat delivery each', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    CartItem item(String variant, String seller, double price, int qty) => CartItem(
      variantId: variant,
      productId: 'p-$variant',
      sellerId: seller,
      name: variant,
      slug: variant,
      price: price,
      originalPrice: price,
      stock: 5,
      quantity: qty,
    );

    final cart = container.read(cartProvider.notifier);
    cart.add(item('a', 's1', 100, 1));
    cart.add(item('b', 's2', 250, 2));
    cart.add(item('a', 's1', 100, 2)); // merges into the same line

    final summary = container.read(cartSummaryProvider);
    expect(summary.groups, hasLength(2));
    expect(summary.subtotal, 100 * 3 + 250 * 2);
    expect(summary.shipping, 120);
    expect(summary.total, 920);
    expect(container.read(cartCountProvider), 5);
    expect(prefs.getString(PrefKeys.cart), isNotNull, reason: 'cart persists locally');
  });
}
