import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/json.dart';
import '../models/category.dart';
import '../models/product.dart';

class ProductPage extends Paged<ProductSummary> {
  const ProductPage({
    required super.items,
    required super.page,
    required super.total,
    required super.hasNext,
    this.categories = const [],
  });

  final List<FilterCategory> categories;
}

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<ProductPage> products(ProductQuery query, {int page = 1, int limit = 20}) async {
    final res = await _api.get(
      '/public/products',
      query: query.toQuery(page: page, limit: limit),
    );
    final pagination = asJson(res['pagination']);
    final meta = asJson(res['meta']);
    return ProductPage(
      items: asJsonList(res['data']).map(ProductSummary.fromJson).toList(),
      page: intOf(pagination['page'], page),
      total: intOf(pagination['total']),
      hasNext: boolOf(pagination['hasNext']),
      categories: asJsonList(meta['categories']).map(FilterCategory.fromJson).toList(),
    );
  }

  Future<ProductDetail> productBySlug(String slug) async {
    final res = await _api.get('/products/slug/${Uri.encodeComponent(slug)}');
    return ProductDetail.fromJson(asJson(res['data']));
  }

  /// Fresh price/stock for a single cart line.
  Future<ProductVariant> cartView({required String productId, required String variantId}) async {
    final res = await _api.get('/products/cart/view', query: {'productId': productId, 'variantId': variantId});
    return ProductVariant.fromJson(asJson(res['data']));
  }

  Future<List<CategoryNode>> categoryMenu() async {
    final res = await _api.get('/public/categories/menu', query: {'limit': 100});
    return CategoryNode.buildTree(asJsonList(res['data']));
  }

  Future<List<FilterCategory>> filterCategories() async {
    final res = await _api.get('/public/product-filter-categories');
    return asJsonList(res['data']).map(FilterCategory.fromJson).toList();
  }

  Future<SearchSuggestions> suggest(String term) async {
    final res = await _api.get('/public/search/suggest', query: {'search': term});
    return SearchSuggestions.fromJson(asJson(res['data']));
  }
}

final catalogRepositoryProvider = Provider((ref) => CatalogRepository(ref.watch(apiClientProvider)));
