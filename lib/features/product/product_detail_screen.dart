import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/config/env.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/spec_parser.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/cart_controller.dart';
import '../../state/catalog_providers.dart';
import 'add_to_cart_flow.dart';
import 'fly_to_cart.dart';
import 'variant_selector.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug, this.initial, this.heroTag});

  final String slug;
  final ProductSummary? initial;
  final String? heroTag;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _scroll = ScrollController();
  final _gallery = PageController();
  final _cartKey = GlobalKey();
  final _galleryKey = GlobalKey();
  final _barOpacity = ValueNotifier<double>(0);

  ProductVariant? _variant;
  int _qty = 1;
  double _galleryHeight = 360;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final h = _galleryHeight;
      _barOpacity.value = ((_scroll.offset - h * 0.55) / (h * 0.3)).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _gallery.dispose();
    _barOpacity.dispose();
    super.dispose();
  }

  void _addToCart(ProductDetail detail, ProductVariant variant, {bool buyNow = false}) {
    if (buyNow) {
      addVariantToCart(context, ref, detail, variant, _qty, showToast: false);
      context.push(Paths.checkout);
      return;
    }
    final box = _galleryKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.attached) {
      final origin = box.localToGlobal(Offset.zero);
      final rect = Rect.fromCenter(
        center: origin + box.size.center(Offset.zero),
        width: box.size.width * 0.5,
        height: box.size.width * 0.5,
      );
      HapticFeedback.lightImpact();
      flyToCart(
        context: context,
        from: rect,
        targetKey: _cartKey,
        image: variant.image ?? detail.summary.image,
        onArrive: () {
          if (mounted) addVariantToCart(context, ref, detail, variant, _qty);
        },
      );
    } else {
      addVariantToCart(context, ref, detail, variant, _qty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final async = ref.watch(productDetailProvider(widget.slug));
    final detail = async.value;
    final summary = detail?.summary ?? widget.initial;

    if (summary == null) {
      return Scaffold(
        body: async.hasError
            ? SafeArea(
                child: Column(
                  children: [
                    _TopBar(cartKey: _cartKey, opacity: _barOpacity, title: ''),
                    Expanded(
                      child: ErrorState(
                        error: async.error!,
                        onRetry: () => ref.invalidate(productDetailProvider(widget.slug)),
                      ),
                    ),
                  ],
                ),
              )
            : const _DetailSkeleton(),
      );
    }

    final variant = _variant ?? (detail == null ? null : defaultVariant(detail));
    final images = detail?.images ?? summary.images;
    final price = variant?.price ?? summary.displayPrice;
    final original = variant?.originalPrice ?? (summary.hasDiscount ? summary.originalPrice : price);
    final discountPct = variant?.discountPercent ?? summary.discount;
    final stock = variant?.stock ?? summary.totalStock;
    _galleryHeight = (MediaQuery.sizeOf(context).width * 0.95).clamp(280.0, 520.0);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: _Gallery(
                  key: _galleryKey,
                  controller: _gallery,
                  images: images,
                  heroTag: widget.heroTag,
                  height: _galleryHeight,
                ),
              ),
              SliverToBoxAdapter(
                child: ColoredBox(
                  color: p.background,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.page, 2, Gap.page, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Badges(summary: summary),
                        const SizedBox(height: 12),
                        Text(summary.name, style: context.text.headlineSmall),
                        if (summary.category != null) ...[
                          const SizedBox(height: 8),
                          Pressable(
                            onTap: () => ProductListRoute.open(
                              context,
                              title: summary.category!.name,
                              query: ProductQuery(categorySlug: summary.category!.slug),
                            ),
                            child: Row(
                              children: [
                                AppIcon(PhosphorIconsRegular.tag, size: 14, color: p.primary),
                                const SizedBox(width: 6),
                                Text(
                                  summary.category!.name,
                                  style: context.text.labelMedium?.copyWith(
                                    color: p.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppIcon(PhosphorIconsBold.caretRight, size: 11, color: p.primary),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _PriceBlock(price: price, original: original, discountPct: discountPct),
                        const SizedBox(height: 12),
                        _StockLine(stock: stock),
                        const SizedBox(height: 22),
                        AnimatedSize(
                          duration: Motion.medium,
                          curve: Motion.emphasized,
                          alignment: Alignment.topCenter,
                          child: detail == null
                              ? const Shimmer(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Skeleton(width: 110, height: 14),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Skeleton(width: 90, height: 40, radius: 14),
                                          SizedBox(width: 8),
                                          Skeleton(width: 90, height: 40, radius: 14),
                                        ],
                                      ),
                                      SizedBox(height: 22),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (variant != null)
                                      VariantSelector(
                                        product: detail,
                                        selected: variant,
                                        onChanged: (v) {
                                          setState(() {
                                            _variant = v;
                                            _qty = _qty.clamp(1, v.stock < 1 ? 1 : v.stock);
                                          });
                                          final idx = detail.images.indexOf(v.image ?? '');
                                          if (idx >= 0 && _gallery.hasClients) {
                                            _gallery.animateToPage(
                                              idx,
                                              duration: Motion.slow,
                                              curve: Motion.emphasized,
                                            );
                                          }
                                        },
                                      ),
                                    Row(
                                      children: [
                                        Expanded(child: Text('Quantity', style: context.text.titleSmall)),
                                        QuantityStepper(
                                          value: _qty,
                                          max: stock < 1 ? 1 : stock,
                                          onChanged: (q) => setState(() => _qty = q),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),
                        _Assurances(sellerName: detail?.sellerName),
                        if ((summary.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text('About this item', style: context.text.titleLarge),
                          const SizedBox(height: 10),
                          _ExpandableText(summary.description!),
                        ],
                        if (detail != null && parseSpecifications(detail.specification).isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text('Specifications', style: context.text.titleLarge),
                          const SizedBox(height: 12),
                          _SpecTable(rows: parseSpecifications(detail.specification)),
                        ],
                        if (detail?.sku != null) ...[
                          const SizedBox(height: 16),
                          Text('SKU  ${variant?.sku ?? detail!.sku}', style: context.text.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (summary.category != null)
                SliverToBoxAdapter(
                  child: _Similar(categorySlug: summary.category!.slug, excludeId: summary.id, slug: widget.slug),
                ),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 120)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _TopBar(cartKey: _cartKey, opacity: _barOpacity, title: summary.name, product: summary),
          ),
        ],
      ),
      bottomNavigationBar: _BuyBar(
        price: price * _qty,
        enabled: detail != null && variant != null && variant.inStock,
        soldOut: detail != null && (variant == null || !variant.inStock),
        onAdd: () => _addToCart(detail!, variant!),
        onBuy: () => _addToCart(detail!, variant!, buyNow: true),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.cartKey, required this.opacity, required this.title, this.product});

  final GlobalKey cartKey;
  final ValueNotifier<double> opacity;
  final String title;
  final ProductSummary? product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final count = ref.watch(cartCountProvider);
    final top = MediaQuery.paddingOf(context).top;
    return ValueListenableBuilder<double>(
      valueListenable: opacity,
      builder: (context, o, _) => Container(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 10),
        decoration: BoxDecoration(
          color: p.background.withValues(alpha: o),
          border: Border(
            bottom: BorderSide(color: p.line.withValues(alpha: o)),
          ),
        ),
        child: Row(
          children: [
            CircleIconButton(
              icon: PhosphorIconsBold.arrowLeft,
              size: 42,
              iconSize: 18,
              background: p.surface.withValues(alpha: 0.94),
              border: o > 0.5,
              onTap: () => context.popOrHome(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: o,
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
              ),
            ),
            if (product != null) ...[
              WishlistButton(product: product!, size: 42, onImage: true),
              const SizedBox(width: 8),
            ],
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleIconButton(
                  key: cartKey,
                  icon: PhosphorIconsRegular.shoppingBagOpen,
                  size: 42,
                  iconSize: 19,
                  background: p.surface.withValues(alpha: 0.94),
                  border: o > 0.5,
                  onTap: () => context.go(Paths.cart),
                ),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child:
                        Container(
                              key: ValueKey(count),
                              constraints: const BoxConstraints(minWidth: 19),
                              height: 19,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: p.surface, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                            .animate(key: ValueKey(count))
                            .scaleXY(begin: 0.4, end: 1, duration: 420.ms, curve: Curves.elasticOut),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({super.key, required this.controller, required this.images, required this.height, this.heroTag});

  final PageController controller;
  final List<String> images;
  final double height;
  final String? heroTag;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final images = widget.images;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: images.isEmpty
                ? NetImage(null, background: p.surfaceAlt)
                : PageView.builder(
                    controller: widget.controller,
                    itemCount: images.length,
                    itemBuilder: (context, i) {
                      // Low-res bitmap (already cached by the card) paints
                      // instantly; the sharp one fades in on top.
                      final image = Stack(
                        fit: StackFit.expand,
                        children: [
                          NetImage(images[i], decodeWidth: kCardImageDecodeWidth),
                          NetImage(images[i], fallback: const SizedBox.shrink()),
                        ],
                      );
                      if (i == 0 && widget.heroTag != null) {
                        return Hero(tag: widget.heroTag!, child: image);
                      }
                      return image;
                    },
                  ),
          ),
          // Rounded lip where the details sheet begins. Drawn here (above the
          // photo) because a scroll view paints earlier slivers over later
          // ones, so overlapping the sheet upward would sit under the image.
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 29,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: SmoothPageIndicator(
                    controller: widget.controller,
                    count: images.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      spacing: 5,
                      expansionFactor: 3,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.summary});
  final ProductSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tags = summary.tags.where((t) => t != 'DISCOUNT').take(3).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        summary.condition == ProductCondition.preOwned
            ? const Pill(
                'Pre-owned',
                icon: PhosphorIconsBold.recycle,
                color: BrandColors.tide800,
                background: BrandColors.seafoamSoft,
              )
            : Pill('Brand new', icon: PhosphorIconsBold.sparkle, color: p.primary),
        for (final t in tags)
          Pill(
            ProductTags.label(t),
            color: t == 'FLASH_SALE' || t == 'HOT' ? p.accentInk : p.inkSoft,
            background: t == 'FLASH_SALE' || t == 'HOT' ? p.accentSoft : p.surfaceAlt,
          ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.price, required this.original, required this.discountPct});
  final double price;
  final double original;
  final double discountPct;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final saving = (original - price).roundToDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: Motion.medium,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
              child: c,
            ),
          ),
          child: Text(
            money(price),
            key: ValueKey(price),
            style: context.text.displaySmall?.copyWith(
              fontSize: 30,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (saving > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    money(original.roundToDouble()),
                    style: context.text.bodyMedium?.copyWith(
                      color: p.muted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: p.muted,
                    ),
                  ),
                  Pill('Save ${money(saving)}', color: p.accentInk, background: p.accentSoft, dense: true),
                  if (discountPct >= 1) Pill.accent(context, '-${discountPct.round()}%'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StockLine extends StatelessWidget {
  const _StockLine({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (color, text) = stock <= 0
        ? (p.danger, 'Out of stock')
        : stock <= 5
        ? (p.warning, 'Only $stock left. Order soon')
        : (p.success, 'In stock, ready to ship');
    return AnimatedSwitcher(
      duration: Motion.medium,
      child: Row(
        key: ValueKey(text),
        children: [
          Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.8, end: 1.2, duration: 900.ms, curve: Curves.easeInOut),
          const SizedBox(width: 8),
          Text(
            text,
            style: context.text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Assurances extends StatelessWidget {
  const _Assurances({this.sellerName});
  final String? sellerName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget row(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: AppIcon(icon, color: p.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(body, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          row(
            PhosphorIconsDuotone.storefront,
            sellerName == null ? 'Sold by a CartBoat seller' : 'Sold by $sellerName',
            'Ships directly from the shop',
          ),
          Divider(color: p.line, height: 1),
          row(
            PhosphorIconsDuotone.truck,
            'Delivery ${money(Env.shippingPerSeller)} per shop',
            'Combined for items from the same seller',
          ),
          Divider(color: p.line, height: 1),
          row(PhosphorIconsDuotone.handCoins, 'Cash on delivery available', 'Or pay with mobile banking or card'),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final long = widget.text.length > 220;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.emphasized,
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: _open || !long ? null : 4,
            overflow: _open || !long ? null : TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
        if (long)
          Pressable(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _open ? 'Show less' : 'Read more',
                style: context.text.labelMedium?.copyWith(color: p.primary, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

class _SpecTable extends StatelessWidget {
  const _SpecTable({required this.rows});
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        borderRadius: Radii.card,
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              color: i.isEven ? p.surface : p.surfaceAlt.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(rows[i].key, style: context.text.labelMedium?.copyWith(color: p.muted)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(rows[i].value, style: context.text.bodyMedium?.copyWith(color: p.ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Similar extends ConsumerWidget {
  const _Similar({required this.categorySlug, required this.excludeId, required this.slug});
  final String categorySlug;
  final String excludeId;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rail = ref.watch(productRailProvider(ProductQuery(categorySlug: categorySlug)));
    final items = (rail.value ?? const []).where((p) => p.id != excludeId).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'You may also like'),
          const SizedBox(height: 14),
          ProductRail(products: items, heroScope: 'similar-$slug'),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.price,
    required this.enabled,
    required this.soldOut,
    required this.onAdd,
    required this.onBuy,
  });

  final double price;
  final bool enabled;
  final bool soldOut;
  final VoidCallback onAdd;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.fromLTRB(Gap.page, 12, Gap.page, MediaQuery.paddingOf(context).bottom + 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Row(
        children: [
          Pressable(
            onTap: enabled ? onAdd : null,
            scale: 0.92,
            child: AnimatedContainer(
              duration: Motion.medium,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: enabled ? p.primarySoft : p.surfaceAlt,
                borderRadius: Radii.button,
                border: Border.all(color: enabled ? p.primary.withValues(alpha: 0.3) : p.line),
              ),
              child: AppIcon(PhosphorIconsBold.shoppingBagOpen, color: enabled ? p.primary : p.muted, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: soldOut ? 'Sold out' : 'Buy now · ${money(price)}',
              onPressed: enabled ? onBuy : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Skeleton(height: w * 0.95, radius: 0),
          const Padding(
            padding: EdgeInsets.all(Gap.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 90, height: 22, radius: 11),
                SizedBox(height: 14),
                Skeleton(height: 22),
                SizedBox(height: 8),
                Skeleton(width: 200, height: 22),
                SizedBox(height: 20),
                Skeleton(width: 140, height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
