import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/repositories/catalog_repository.dart';

final categoryMenuProvider = FutureProvider<List<CategoryNode>>(
  (ref) => ref.watch(catalogRepositoryProvider).categoryMenu(),
);

final filterCategoriesProvider = FutureProvider<List<FilterCategory>>(
  (ref) => ref.watch(catalogRepositoryProvider).filterCategories(),
);

/// A short, horizontally-scrolling home rail.
final productRailProvider = FutureProvider.family<List<ProductSummary>, ProductQuery>((ref, query) async {
  final page = await ref.watch(catalogRepositoryProvider).products(query, limit: 12);
  return page.items;
});

final productDetailProvider = FutureProvider.autoDispose.family<ProductDetail, String>((ref, slug) async {
  // Keep recently viewed products warm for snappy back-and-forth navigation.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(catalogRepositoryProvider).productBySlug(slug);
});

final searchSuggestProvider = FutureProvider.autoDispose.family<SearchSuggestions, String>((ref, term) async {
  if (term.trim().length < 2) return const SearchSuggestions();
  // Debounce: if the user keeps typing this provider is disposed first.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 280));
  if (cancelled) return const SearchSuggestions();
  return ref.read(catalogRepositoryProvider).suggest(term.trim());
});

class ProductListState {
  const ProductListState({
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.hasNext = true,
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.categories = const [],
  });

  final List<ProductSummary> items;
  final int page;
  final int total;
  final bool hasNext;
  final bool loading;
  final bool loadingMore;
  final ApiException? error;
  final List<FilterCategory> categories;

  ProductListState copyWith({
    List<ProductSummary>? items,
    int? page,
    int? total,
    bool? hasNext,
    bool? loading,
    bool? loadingMore,
    ApiException? error,
    bool clearError = false,
    List<FilterCategory>? categories,
  }) => ProductListState(
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    hasNext: hasNext ?? this.hasNext,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
    categories: categories ?? this.categories,
  );
}

/// Infinite, paginated product listing for any [ProductQuery].
class ProductListController extends Notifier<ProductListState> {
  ProductListController(this.query);
  final ProductQuery query;

  static const pageSize = 20;

  @override
  ProductListState build() {
    Future.microtask(refresh);
    return const ProductListState();
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await ref.read(catalogRepositoryProvider).products(query, page: 1, limit: pageSize);
      if (!ref.mounted) return;
      state = ProductListState(
        items: page.items,
        page: 1,
        total: page.total,
        hasNext: page.hasNext,
        loading: false,
        categories: page.categories,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: ApiException.from(e));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasNext || state.error != null) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final page = await ref.read(catalogRepositoryProvider).products(query, page: next, limit: pageSize);
      if (!ref.mounted) return;
      final seen = state.items.map((p) => p.id).toSet();
      state = state.copyWith(
        items: [...state.items, ...page.items.where((p) => !seen.contains(p.id))],
        page: next,
        hasNext: page.hasNext,
        loadingMore: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loadingMore: false, hasNext: false);
    }
  }
}

final productListProvider = NotifierProvider.autoDispose.family<ProductListController, ProductListState, ProductQuery>(
  ProductListController.new,
);
