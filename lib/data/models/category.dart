import '../../core/utils/json.dart';

class CategoryNode {
  CategoryNode({
    required this.name,
    required this.slug,
    required this.slugPath,
    required this.depth,
    this.image,
    this.sellerCount = 0,
    List<CategoryNode>? children,
  }) : children = children ?? [];

  final String name;
  final String slug;
  final List<String> slugPath;
  final int depth;
  final String? image;
  final int sellerCount;
  final List<CategoryNode> children;

  String get pathKey => slugPath.join('/');
  bool get hasChildren => children.isNotEmpty;

  /// All leaf-ish descendants (children and grandchildren), for grids.
  Iterable<CategoryNode> get descendants sync* {
    for (final c in children) {
      yield c;
      yield* c.descendants;
    }
  }

  factory CategoryNode.fromJson(Json j) => CategoryNode(
    name: str(j['name']).trim(),
    slug: str(j['slug']),
    slugPath: strList(j['slugPath']),
    depth: intOf(j['depth']),
    image: usableImageUrl(j['image']),
    sellerCount: intOf(j['sellerCount']),
  );

  /// Builds a tree from the flat `/public/categories/menu` payload.
  static List<CategoryNode> buildTree(List<Json> flat) {
    final byPath = <String, CategoryNode>{};
    final roots = <CategoryNode>[];
    for (final j in flat) {
      final node = CategoryNode.fromJson(j);
      if (node.slug.isEmpty) continue;
      final key = node.pathKey.isEmpty ? node.slug : node.pathKey;
      if (byPath.containsKey(key)) continue;
      byPath[key] = node;
      final parentPath = strList(j['parentSlugPath']).join('/');
      final parent = parentPath.isEmpty ? null : byPath[parentPath];
      if (parent != null) {
        parent.children.add(node);
      } else if (node.depth == 0 || parentPath.isEmpty) {
        roots.add(node);
      }
    }
    return roots;
  }
}

class FilterCategory {
  const FilterCategory({required this.name, required this.slug, required this.count});

  final String name;
  final String slug;
  final int count;

  factory FilterCategory.fromJson(Json j) =>
      FilterCategory(name: str(j['name']), slug: str(j['slug']), count: intOf(j['productCount']));
}

class SearchSuggestions {
  const SearchSuggestions({this.products = const [], this.categories = const [], this.sellers = const []});

  final List<({String name, String slug})> products;
  final List<({String name, String slug})> categories;
  final List<({String name, String slug})> sellers;

  bool get isEmpty => products.isEmpty && categories.isEmpty && sellers.isEmpty;

  factory SearchSuggestions.fromJson(Json j) {
    List<({String name, String slug})> read(Object? v) => asJsonList(v)
        .map((e) => (name: str(pick(e, ['name', 'shopName'])), slug: str(pick(e, ['slug', '_id']))))
        .where((e) => e.name.isNotEmpty)
        .toList();
    return SearchSuggestions(
      products: read(j['products']),
      categories: read(j['categories']),
      sellers: read(j['sellers']),
    );
  }
}
