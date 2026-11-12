import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/product.dart';

abstract final class Paths {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const explore = '/explore';
  static const cart = '/cart';
  static const account = '/account';
  static const products = '/products';
  static const search = '/search';
  static const checkout = '/checkout';
  static const orderSuccess = '/order-success';
  static const login = '/login';
  static const register = '/register';
  static const becomeSeller = '/become-seller';
  static const verifyOtp = '/verify-otp';
  static const orders = '/orders';
  static const notifications = '/notifications';
  static const wishlist = '/wishlist';
  static const about = '/about';

  static String product(String slug) => '/product/${Uri.encodeComponent(slug)}';
  static String order(String id) => '/orders/$id';
}

class ProductRouteArgs {
  const ProductRouteArgs({this.summary, this.heroTag});
  final ProductSummary? summary;
  final String? heroTag;
}

abstract final class ProductRoute {
  static void open(BuildContext context, ProductSummary product, {String? heroTag}) {
    context.push(
      Paths.product(product.slug),
      extra: ProductRouteArgs(summary: product, heroTag: heroTag),
    );
  }

  static void openSlug(BuildContext context, String slug) => context.push(Paths.product(slug));
}

class ProductListArgs {
  const ProductListArgs({required this.title, required this.query, this.subtitle});
  final String title;
  final String? subtitle;
  final ProductQuery query;
}

abstract final class ProductListRoute {
  static void open(BuildContext context, {required String title, required ProductQuery query, String? subtitle}) {
    context.push(
      Paths.products,
      extra: ProductListArgs(title: title, query: query, subtitle: subtitle),
    );
  }
}

extension SafeNavigation on BuildContext {
  /// Pops when there is somewhere to go back to, otherwise lands on Home
  /// (e.g. a screen opened from a deep link or after `go`).
  void popOrHome() => canPop() ? pop() : go(Paths.home);
}
