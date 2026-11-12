import '../../core/utils/json.dart';

enum ProductCondition {
  brandNew('NEW', 'New'),
  preOwned('PRE_OWNED', 'Pre-owned');

  const ProductCondition(this.api, this.label);
  final String api;
  final String label;

  static ProductCondition fromApi(Object? v) =>
      v?.toString() == 'PRE_OWNED' ? ProductCondition.preOwned : ProductCondition.brandNew;
}

/// Human labels for the backend's product tag enum.
abstract final class ProductTags {
  static const labels = <String, String>{
    'NEW_ARRIVAL': 'New',
    'FLASH_SALE': 'Flash Sale',
    'TOP_DEALS': 'Top Deal',
    'BEST_SELLER': 'Bestseller',
    'FEATURED': 'Featured',
    'TRENDING': 'Trending',
    'POPULAR': 'Popular',
    'HOT': 'Hot',
    'ON_SALE': 'On Sale',
    'LIMITED_EDITION': 'Limited',
    'EXCLUSIVE': 'Exclusive',
    'PRE_ORDER': 'Pre-order',
    'COMING_SOON': 'Coming Soon',
    'LOW_STOCK': 'Low Stock',
    'BACK_IN_STOCK': 'Back in Stock',
    'FREE_SHIPPING': 'Free Shipping',
    'TOP_RATED': 'Top Rated',
    'RECOMMENDED': 'Recommended',
    'CLEARANCE': 'Clearance',
    'DISCOUNT': 'Discount',
  };

  /// Tags worth surfacing as a filter.
  static const filterable = [
    'FLASH_SALE',
    'TOP_DEALS',
    'NEW_ARRIVAL',
    'BEST_SELLER',
    'TRENDING',
    'FREE_SHIPPING',
    'TOP_RATED',
    'CLEARANCE',
  ];

  static String label(String tag) => labels[tag] ?? tag;
}

double _originalPrice(double price, double discountPercent) {
  if (discountPercent <= 0 || discountPercent >= 100) return price;
  return price / (1 - discountPercent / 100);
}

class CategoryRef {
  const CategoryRef({required this.id, required this.name, required this.slug, this.slugPath = const []});

  final String id;
  final String name;
  final String slug;
  final List<String> slugPath;

  factory CategoryRef.fromJson(Json j) =>
      CategoryRef(id: str(j['_id']), name: str(j['name']), slug: str(j['slug']), slugPath: strList(j['slugPath']));

  Json toJson() => {'_id': id, 'name': name, 'slug': slug, 'slugPath': slugPath};
}

/// The shape returned by product listings — enough for cards and wishlists.
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.images,
    required this.price,
    required this.discount,
    required this.priceMin,
    required this.priceMax,
    required this.totalStock,
    required this.variantCount,
    required this.condition,
    required this.tags,
    required this.sellerId,
    this.category,
    this.description,
  });

  final String id;
  final String name;
  final String slug;
  final List<String> images;
  final double price;
  final double discount;
  final double priceMin;
  final double priceMax;
  final int totalStock;
  final int variantCount;
  final ProductCondition condition;
  final List<String> tags;
  final String sellerId;
  final CategoryRef? category;
  final String? description;

  String? get image => images.isEmpty ? null : images.first;
  bool get hasDiscount => discount > 0;
  bool get inStock => totalStock > 0;
  bool get hasPriceRange => priceMax > priceMin;
  double get originalPrice => _originalPrice(priceMin > 0 ? priceMin : price, discount);
  double get displayPrice => priceMin > 0 ? priceMin : price;

  factory ProductSummary.fromJson(Json j) {
    final images = strList(j['images']).where((u) => usableImageUrl(u) != null).toList();
    final cat = j['categoryId'];
    final price = numOf(j['sellingPrice']);
    return ProductSummary(
      id: str(j['_id']),
      name: str(j['name']).trim(),
      slug: str(j['slug']),
      images: images,
      price: price,
      discount: numOf(j['discount']),
      priceMin: numOf(j['displayPriceMin'], price),
      priceMax: numOf(j['displayPriceMax'], price),
      totalStock: intOf(j['totalStock'], intOf(j['stock'])),
      variantCount: intOf(j['variantCount'], 1),
      condition: ProductCondition.fromApi(j['productType']),
      tags: strList(j['tags']),
      sellerId: str(j['sellerId']),
      category: cat is Map ? CategoryRef.fromJson(asJson(cat)) : null,
      description: strOrNull(j['description']),
    );
  }

  Json toJson() => {
    '_id': id,
    'name': name,
    'slug': slug,
    'images': images,
    'sellingPrice': price,
    'discount': discount,
    'displayPriceMin': priceMin,
    'displayPriceMax': priceMax,
    'totalStock': totalStock,
    'variantCount': variantCount,
    'productType': condition.api,
    'tags': tags,
    'sellerId': sellerId,
    if (category != null) 'categoryId': category!.toJson(),
  };
}

class VariantAttribute {
  const VariantAttribute(this.key, this.value);
  final String key;
  final String value;

  factory VariantAttribute.fromJson(Json j) => VariantAttribute(str(j['key']), str(j['value']));
  Json toJson() => {'key': key, 'value': value};
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.attributes,
    required this.sku,
    required this.image,
    required this.price,
    required this.stock,
    required this.discountType,
    required this.discountValue,
    required this.isActive,
  });

  final String id;
  final String productId;
  final String sellerId;
  final List<VariantAttribute> attributes;
  final String sku;
  final String? image;
  final double price;
  final int stock;
  final String? discountType;
  final double discountValue;
  final bool isActive;

  bool get inStock => stock > 0 && isActive;

  double get originalPrice {
    if (discountValue <= 0) return price;
    if (discountType == 'percentage') return _originalPrice(price, discountValue);
    return price + discountValue;
  }

  double get discountPercent {
    if (discountValue <= 0) return 0;
    if (discountType == 'percentage') return discountValue;
    final orig = originalPrice;
    return orig <= 0 ? 0 : (orig - price) / orig * 100;
  }

  String? valueOf(String key) {
    for (final a in attributes) {
      if (a.key == key) return a.value;
    }
    return null;
  }

  String get label => attributes.map((a) => a.value).join(' · ');

  factory ProductVariant.fromJson(Json j) {
    final pid = j['productId'];
    return ProductVariant(
      id: str(j['_id']),
      productId: pid is Map ? str(pid['_id']) : str(pid),
      sellerId: str(j['sellerId']),
      attributes: asJsonList(j['attributes']).map(VariantAttribute.fromJson).toList(),
      sku: str(j['sku']),
      image: usableImageUrl(j['image']),
      price: numOf(j['sellingPrice']),
      stock: intOf(j['stock']),
      discountType: strOrNull(j['discountType']),
      discountValue: numOf(j['discountValue']),
      isActive: boolOf(j['isActive'], true),
    );
  }
}

class ProductDetail {
  const ProductDetail({required this.summary, required this.variants, this.specification, this.sku, this.sellerName});

  final ProductSummary summary;
  final List<ProductVariant> variants;
  final String? specification;
  final String? sku;
  final String? sellerName;

  List<String> get images {
    final all = <String>[...summary.images];
    for (final v in variants) {
      if (v.image != null && !all.contains(v.image)) all.add(v.image!);
    }
    return all;
  }

  /// Attribute keys in first-seen order, e.g. `[color, size]`.
  List<String> get attributeKeys {
    final keys = <String>[];
    for (final v in variants) {
      for (final a in v.attributes) {
        if (!keys.contains(a.key)) keys.add(a.key);
      }
    }
    return keys;
  }

  List<String> valuesFor(String key) {
    final values = <String>[];
    for (final v in variants) {
      final val = v.valueOf(key);
      if (val != null && !values.contains(val)) values.add(val);
    }
    return values;
  }

  factory ProductDetail.fromJson(Json data) {
    final p = asJson(data['product']);
    final createdBy = p['createdBy'];
    return ProductDetail(
      summary: ProductSummary.fromJson(p),
      variants: asJsonList(data['variants']).map(ProductVariant.fromJson).where((v) => v.isActive).toList(),
      specification: strOrNull(p['specification']),
      sku: strOrNull(p['sku']),
      sellerName: createdBy is Map ? strOrNull(createdBy['name']) : null,
    );
  }
}

class Paged<T> {
  const Paged({required this.items, required this.page, required this.total, required this.hasNext});

  final List<T> items;
  final int page;
  final int total;
  final bool hasNext;
}

enum ProductSort {
  recommended('Recommended', 'updatedAt', 'desc'),
  newest('Newest first', 'createdAt', 'desc'),
  priceLow('Price: low to high', 'sellingPrice', 'asc'),
  priceHigh('Price: high to low', 'sellingPrice', 'desc'),
  nameAz('Name: A to Z', 'name', 'asc');

  const ProductSort(this.label, this.field, this.order);
  final String label;
  final String field;
  final String order;
}

/// Everything that identifies a product listing. Value-equal so it can key
/// Riverpod families.
class ProductQuery {
  const ProductQuery({
    this.search,
    this.categorySlug,
    this.tag,
    this.condition,
    this.onlyDiscounted = false,
    this.sort = ProductSort.recommended,
  });

  final String? search;
  final String? categorySlug;
  final String? tag;
  final ProductCondition? condition;
  final bool onlyDiscounted;
  final ProductSort sort;

  int get activeFilterCount =>
      (tag != null ? 1 : 0) + (condition != null ? 1 : 0) + (onlyDiscounted ? 1 : 0) + (categorySlug != null ? 1 : 0);

  ProductQuery copyWith({
    String? search,
    String? categorySlug,
    String? tag,
    ProductCondition? condition,
    bool? onlyDiscounted,
    ProductSort? sort,
    bool clearCategory = false,
    bool clearTag = false,
    bool clearCondition = false,
  }) => ProductQuery(
    search: search ?? this.search,
    categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
    tag: clearTag ? null : (tag ?? this.tag),
    condition: clearCondition ? null : (condition ?? this.condition),
    onlyDiscounted: onlyDiscounted ?? this.onlyDiscounted,
    sort: sort ?? this.sort,
  );

  Map<String, dynamic> toQuery({int page = 1, int limit = 20}) => {
    'page': page,
    'limit': limit,
    'search': search,
    'categorySlug': categorySlug,
    'tags': tag,
    'productType': condition?.api,
    if (onlyDiscounted) 'hasDiscount': 'true',
    'sortBy': sort.field,
    'sortOrder': sort.order,
  };

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.search == search &&
      other.categorySlug == categorySlug &&
      other.tag == tag &&
      other.condition == condition &&
      other.onlyDiscounted == onlyDiscounted &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(search, categorySlug, tag, condition, onlyDiscounted, sort);
}
