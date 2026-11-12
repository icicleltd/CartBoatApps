import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/toast.dart';
import '../../state/cart_controller.dart';
import '../../state/catalog_providers.dart';
import 'variant_selector.dart';

/// Adds [variant] to the cart and confirms with haptics + a toast.
void addVariantToCart(
  BuildContext context,
  WidgetRef ref,
  ProductDetail product,
  ProductVariant variant,
  int quantity, {
  bool showToast = true,
}) {
  final router = ref.read(routerProvider);
  ref.read(cartProvider.notifier).add(CartItem.fromVariant(product, variant, quantity));
  HapticFeedback.mediumImpact();
  if (showToast) {
    AppToast.success(
      context,
      '${product.summary.name} added to cart',
      actionLabel: 'View cart',
      onAction: () => router.go(Paths.cart),
    );
  }
}

/// "+" on product cards: adds straight away for single-variant products,
/// otherwise opens a compact variant picker.
Future<void> quickAddToCart(BuildContext context, WidgetRef ref, ProductSummary summary) async {
  try {
    final detail = await ref.read(productDetailProvider(summary.slug).future);
    if (!context.mounted) return;
    final available = detail.variants.where((v) => v.inStock).toList();
    if (available.isEmpty) {
      AppToast.show(context, message: 'Sorry, this item just sold out', icon: PhosphorIconsFill.package);
      return;
    }
    if (detail.variants.length == 1) {
      addVariantToCart(context, ref, detail, available.first, 1);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => VariantPickerSheet(product: detail),
    );
  } catch (e) {
    if (context.mounted) AppToast.error(context, ApiException.from(e));
  }
}

class VariantPickerSheet extends ConsumerStatefulWidget {
  const VariantPickerSheet({super.key, required this.product});
  final ProductDetail product;

  @override
  ConsumerState<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends ConsumerState<VariantPickerSheet> {
  late ProductVariant _variant = defaultVariant(widget.product)!;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final product = widget.product;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: AnimatedSwitcher(
                      duration: Motion.medium,
                      child: NetImage(
                        _variant.image ?? product.summary.image,
                        key: ValueKey(_variant.image),
                        decodeWidth: 120,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.summary.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      PriceLine(price: _variant.price, original: _variant.originalPrice, size: 18),
                      const SizedBox(height: 4),
                      Text(
                        _variant.inStock ? '${_variant.stock} in stock' : 'Out of stock',
                        style: context.text.bodySmall?.copyWith(color: _variant.inStock ? p.success : p.danger),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            VariantSelector(
              product: product,
              selected: _variant,
              onChanged: (v) => setState(() {
                _variant = v;
                _qty = _qty.clamp(1, v.stock < 1 ? 1 : v.stock);
              }),
            ),
            Row(
              children: [
                Expanded(child: Text('Quantity', style: context.text.titleSmall)),
                QuantityStepper(
                  value: _qty,
                  max: _variant.stock < 1 ? 1 : _variant.stock,
                  onChanged: (q) => setState(() => _qty = q),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _variant.inStock ? 'Add to cart' : 'Out of stock',
              icon: PhosphorIconsBold.shoppingBagOpen,
              onPressed: _variant.inStock
                  ? () {
                      addVariantToCart(context, ref, product, _variant, _qty);
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
