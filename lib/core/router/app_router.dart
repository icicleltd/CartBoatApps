import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/product.dart';
import '../../data/repositories/order_repository.dart';
import '../../features/account/about_screen.dart';
import '../../features/account/account_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/catalog/product_list_screen.dart';
import '../../features/categories/explore_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/seller/become_seller_screen.dart';
import '../../features/seller/verify_otp_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../theme/transitions.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Paths.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: Paths.splash,
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: Paths.onboarding,
        pageBuilder: (context, state) => riseUpPage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      StatefulShellRoute(
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughBranches(currentIndex: shell.currentIndex, children: children),
        pageBuilder: (context, state, shell) => riseUpPage(
          key: state.pageKey,
          child: MainShell(shell: shell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Paths.home, builder: (context, state) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Paths.explore, builder: (context, state) => const ExploreScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Paths.cart, builder: (context, state) => const CartScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Paths.account, builder: (context, state) => const AccountScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:slug',
        builder: (context, state) {
          final args = state.extra is ProductRouteArgs ? state.extra as ProductRouteArgs : const ProductRouteArgs();
          return ProductDetailScreen(slug: state.pathParameters['slug']!, initial: args.summary, heroTag: args.heroTag);
        },
      ),
      GoRoute(
        path: Paths.products,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ProductListArgs) return ProductListScreen(args: extra);
          final q = state.uri.queryParameters;
          return ProductListScreen(
            args: ProductListArgs(
              title: q['title'] ?? (q['q'] != null ? '"${q['q']}"' : 'All products'),
              query: ProductQuery(
                search: q['q'],
                categorySlug: q['category'],
                tag: q['tag'],
                onlyDiscounted: q['sale'] == 'true',
                condition: q['type'] == null ? null : ProductCondition.fromApi(q['type']),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: Paths.search,
        pageBuilder: (context, state) => riseUpPage(key: state.pageKey, child: const SearchScreen()),
      ),
      GoRoute(path: Paths.checkout, builder: (context, state) => const CheckoutScreen()),
      GoRoute(
        path: Paths.orderSuccess,
        pageBuilder: (context, state) => riseUpPage(
          key: state.pageKey,
          child: OrderSuccessScreen(
            orders: state.extra is List<PlacedOrder> ? state.extra as List<PlacedOrder> : const [],
          ),
        ),
      ),
      GoRoute(
        path: Paths.login,
        pageBuilder: (context, state) => slideUpPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(path: Paths.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: Paths.becomeSeller, builder: (context, state) => const BecomeSellerScreen()),
      GoRoute(
        path: Paths.verifyOtp,
        builder: (context, state) => VerifyOtpScreen(email: state.extra is String ? state.extra as String : ''),
      ),
      GoRoute(
        path: Paths.orders,
        builder: (context, state) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: Paths.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: Paths.wishlist, builder: (context, state) => const WishlistScreen()),
      GoRoute(path: Paths.about, builder: (context, state) => const AboutScreen()),
    ],
  );
});
