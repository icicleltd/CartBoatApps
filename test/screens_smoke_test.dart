import 'package:cartboat/core/storage/prefs.dart';
import 'package:cartboat/core/theme/app_theme.dart';
import 'package:cartboat/features/account/about_screen.dart';
import 'package:cartboat/features/account/account_screen.dart';
import 'package:cartboat/features/auth/login_screen.dart';
import 'package:cartboat/features/auth/register_screen.dart';
import 'package:cartboat/features/cart/cart_screen.dart';
import 'package:cartboat/features/checkout/checkout_screen.dart';
import 'package:cartboat/features/onboarding/onboarding_screen.dart';
import 'package:cartboat/features/seller/become_seller_screen.dart';
import 'package:cartboat/features/wishlist/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders offline screens in both themes to catch layout/build errors.
void main() {
  final screens = <String, Widget Function()>{
    'account': () => const AccountScreen(),
    'about': () => const AboutScreen(),
    'cart': () => const CartScreen(),
    'wishlist': () => const WishlistScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'become seller': () => const BecomeSellerScreen(),
    'checkout': () => const CheckoutScreen(),
    'onboarding': () => const OnboardingScreen(),
  };

  // One line in the cart so cart/checkout render their full layouts.
  const seededCart =
      '[{"variantId":"v1","productId":"p1","sellerId":"s1","name":"Slim Fit Cargo Pants with a long descriptive name",'
      '"slug":"pants","price":1450,"originalPrice":1611,"stock":3,"quantity":2,"image":null,'
      '"attributes":[{"key":"color","value":"Olive Green"},{"key":"size","value":"32"}],"sellerName":"Rupbaan Shop"}]';

  for (final dark in [false, true]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders (${dark ? 'dark' : 'light'})', (tester) async {
        SharedPreferences.setMockInitialValues({'cb_cart': seededCart});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [prefsProvider.overrideWithValue(prefs)],
            retry: (_, _) => null,
            child: MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: entry.value(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
