# CartBoat — mobile app

Flutter shopping app for the CartBoat multi-vendor marketplace. Customers browse every shop, fill one cart and check out once; the app splits the order per seller exactly like the web storefront.

## Run it

```bash
flutter pub get
flutter run                      # Android / iOS device or emulator
```

The API host defaults to `https://multivendorbackend.vercel.app/api/v1`. Point it elsewhere without code changes:

```bash
flutter run --dart-define=API_BASE_URL=https://staging.example.com/api/v1
```

Release builds: `flutter build apk --release` / `flutter build appbundle` / `flutter build ipa`.

**Web preview (optional).** The backend's CORS list only allows a few origins, so preview the web build through the bundled same-origin proxy:

```bash
flutter build web --dart-define=API_BASE_URL=http://localhost:3100/api/v1
python tool/dev_web_proxy.py     # http://localhost:3100
```

## Features

| Area | What's there |
| --- | --- |
| Onboarding | Animated splash (sails hoist, wave rolls), 3-step parallax onboarding |
| Home | Search hero, auto-advancing promo carousel, category strip, Flash Sale with live countdown, Top deals, Pre-owned, New arrivals, Trending, infinite "Just for you" grid, pull-to-refresh |
| Explore | Category rail + animated sub-category panel built from the menu tree |
| Search | Debounced suggestions (products, categories, shops) with match highlighting, recent searches, quick picks, popular categories |
| Listing | Infinite scroll, sort (recommended, newest, price ↑↓, name), filters (condition, on sale, collections, category) |
| Product | Hero gallery, variant picker with colour swatches, stock state, quantity, seller & delivery info, parsed specs, similar items, fly-to-cart animation, Buy now |
| Cart | Grouped per seller (one shipment each, ৳60 delivery), swipe-to-remove with undo, price/stock re-sync on pull, counting totals |
| Checkout | Contact + address (saved for next time), 4 payment methods, notes, review, one order per seller, success screen with confetti |
| Account | Sign in / create account, orders with status timeline, notifications, saved items, become-a-seller with email OTP, light/dark/auto theme |

Cart, saved items, recent searches and theme are stored on device; the access token lives in the platform keystore (`flutter_secure_storage`).

## API mapping (Postman collection → app)

| Endpoint | Used for |
| --- | --- |
| `POST /auth/login`, `GET /auth/me` | Sign in, session restore |
| `POST /users` | Create account (then auto sign-in) |
| `POST /auth/be-seller`, `/auth/be-seller-otp`, `/auth/resend-otp` | Become a seller |
| `GET /public/categories/menu` | Category strip, Explore |
| `GET /public/product-filter-categories` | Search: popular categories |
| `GET /public/products` (`search`, `categorySlug`, `tags`, `productType`, `hasDiscount`, `sortBy`, `sortOrder`, `page`, `limit`) | Every product list and rail |
| `GET /public/search/suggest` | Live search suggestions |
| `GET /products/slug/:slug` | Product page (product + variants) |
| `GET /products/cart/view` | Cart price/stock refresh |
| `POST /orders`, `GET /orders`, `GET /orders/:id` | Checkout, order history, order detail |
| `GET /notifications/` | Notifications |

Seller/admin endpoints in the collection (inventory, POS sales, customers, user stats, dev utilities) belong to the seller dashboard and are intentionally not exposed in this customer app.

The orders and notifications response shapes aren't documented in the collection, so `Order.fromJson` / `AppNotification.fromJson` read several common field names defensively. Check them against a real signed-in response and tighten if needed.

## Project structure

```
lib/
  core/        config, network (Dio + error mapping), router, storage, theme, utils
  data/        models + repositories (one per API area)
  state/       Riverpod controllers (auth, cart, catalog, orders, preferences)
  shared/      design-system widgets (logo, cards, buttons, skeletons, toast…)
  features/    one folder per screen/flow
assets/brand/  logo sources (SVG) and rendered PNGs
tool/          gen_icons.py (icon table), dev_web_proxy.py (web preview)
test/          logic tests + render smoke tests for every offline screen
```

## Brand

- **Logo:** a boat whose hull is a shopping basket (handle at the stern) under a price-tag sail. Sources in `assets/brand/` (`cartboat_icon.svg` app icon, `cartboat_mark.svg`, `cartboat_foreground.svg` for Android adaptive icons). In-app it's drawn by `CartBoatMark` so it stays crisp and can animate.
- **Palette:** Tide `#0E5F68` (primary), Deep Tide `#0A4550`, Sail `#FF6A3D` (deals/accent), Seafoam `#6FE0D2` (highlight), Ink `#0F1B24`, Sand `#FAF8F4` (background). Full light/dark tokens in `lib/core/theme/app_colors.dart`.
- **Type:** Plus Jakarta Sans (400–800), bundled.
- **Motion:** one set of tokens in `lib/core/theme/tokens.dart` (emphasized curves, 160/280/420 ms). Pushes glide in, tabs fade through, modals rise up, iOS keeps native swipe-back.

## Icons

Icons are [Phosphor](https://phosphoricons.com) (MIT). The `phosphor_flutter` package no longer compiles on Flutter 3.44 (it extends `IconData`, which is now `final`), so the fonts are bundled in `assets/fonts/phosphor/` and `lib/core/theme/phosphor_icons.g.dart` lists only the glyphs in use. After using a new icon name, regenerate:

```bash
dart pub cache add phosphor_flutter --version 2.1.0   # once, to get the glyph tables
python tool/gen_icons.py <pub-cache>/hosted/pub.dev/phosphor_flutter-2.1.0
```

Use `AppIcon` instead of `Icon` so duotone glyphs render both layers.
