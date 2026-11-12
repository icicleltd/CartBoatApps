import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../features/product/add_to_cart_flow.dart';
import '../../state/preferences.dart';
import 'common.dart';
import 'net_image.dart';
import 'pressable.dart';

/// Shared decode width so the product page can reuse the card's cached
/// bitmap as an instant placeholder during the hero flight.
const kCardImageDecodeWidth = 220.0;

class PriceLine extends StatelessWidget {
  const PriceLine({super.key, required this.price, this.original, this.size = 15, this.prefix, this.wrap = false});

  final double price;
  final double? original;
  final double size;
  final String? prefix;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final showOriginal = original != null && original! > price + 0.5;
    final children = [
      Text(
        '${prefix ?? ''}${money(price)}',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: p.ink,
          letterSpacing: -0.3,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      if (showOriginal)
        Text(
          money(original!.roundToDouble()),
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: size * 0.72,
            fontWeight: FontWeight.w500,
            color: p.muted,
            decoration: TextDecoration.lineThrough,
            decorationColor: p.muted,
          ),
        ),
    ];
    if (wrap) {
      return Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.end, children: children);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: children.first),
        ),
        if (showOriginal) ...[
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: children.last),
          ),
        ],
      ],
    );
  }
}

/// Animated heart that toggles a product in the local wishlist.
class WishlistButton extends ConsumerStatefulWidget {
  const WishlistButton({super.key, required this.product, this.size = 34, this.onImage = true});

  final ProductSummary product;
  final double size;
  final bool onImage;

  @override
  ConsumerState<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends ConsumerState<WishlistButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final saved = ref.watch(isWishlistedProvider(widget.product.id));
    final scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 65),
    ]).animate(_pop);

    return Pressable(
      scale: 0.88,
      onTap: () {
        HapticFeedback.lightImpact();
        final nowSaved = ref.read(wishlistProvider.notifier).toggle(widget.product);
        if (nowSaved) _pop.forward(from: 0);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.onImage ? p.surface.withValues(alpha: 0.92) : p.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: ScaleTransition(
          scale: scale,
          child: AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: AppIcon(
              saved ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
              key: ValueKey(saved),
              size: widget.size * 0.5,
              color: saved ? p.accent : p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.heroScope, this.width});

  final ProductSummary product;

  /// Distinguishes the same product appearing in several sections so hero
  /// tags stay unique per screen.
  final String heroScope;
  final double? width;

  String get heroTag => 'product-$heroScope-${product.id}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final t = context.text;
    final pct = product.discount.round();

    return SizedBox(
      width: width,
      child: Pressable(
        onTap: () => ProductRoute.open(context, product, heroTag: heroTag),
        scale: 0.97,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: NetImage(product.image, decodeWidth: kCardImageDecodeWidth),
                    ),
                    if (!product.inStock)
                      ColoredBox(
                        color: p.surface.withValues(alpha: 0.55),
                        child: Center(
                          child: Pill('Sold out', color: p.ink, background: p.surface),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pct > 0) Pill.accent(context, '-$pct%'),
                          if (product.condition == ProductCondition.preOwned) ...[
                            if (pct > 0) const SizedBox(height: 4),
                            Pill(
                              'Pre-owned',
                              dense: true,
                              icon: PhosphorIconsBold.recycle,
                              color: BrandColors.tide800,
                              background: BrandColors.seafoamSoft,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(right: 8, top: 8, child: WishlistButton(product: product)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (product.category != null)
              Text(
                product.category!.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelSmall?.copyWith(color: p.muted, fontSize: 10, letterSpacing: 0.6),
              ),
            const SizedBox(height: 3),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.3),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: PriceLine(
                    price: product.displayPrice,
                    original: product.hasDiscount ? product.originalPrice : null,
                    prefix: product.hasPriceRange ? 'from ' : null,
                  ),
                ),
                const SizedBox(width: 6),
                _QuickAddButton(product: product),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends ConsumerStatefulWidget {
  const _QuickAddButton({required this.product});
  final ProductSummary product;

  @override
  ConsumerState<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends ConsumerState<_QuickAddButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.product.inStock && !_busy;
    return Pressable(
      scale: 0.85,
      onTap: enabled
          ? () async {
              setState(() => _busy = true);
              await quickAddToCart(context, ref, widget.product);
              if (mounted) setState(() => _busy = false);
            }
          : null,
      child: AnimatedContainer(
        duration: Motion.fast,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled || _busy ? p.primary : p.line,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: _busy
            ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary))
            : AppIcon(PhosphorIconsBold.plus, size: 16, color: enabled ? p.onPrimary : p.muted),
      ),
    );
  }
}

/// Horizontal list of product cards used by home rails and "similar" rows.
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.products, required this.heroScope, this.cardWidth = 164});

  final List<ProductSummary> products;
  final String heroScope;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardWidth + 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.page),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) => ProductCard(product: products[i], heroScope: heroScope, width: cardWidth),
      ),
    );
  }
}
