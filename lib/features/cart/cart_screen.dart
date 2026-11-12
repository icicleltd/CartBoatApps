import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/config/env.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item.dart';
import '../../shared/widgets/animated_money.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/toast.dart';
import '../../state/cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear your cart?'),
        content: const Text('All items will be removed. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep items')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.palette.danger),
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      ref.read(cartProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final summary = ref.watch(cartSummaryProvider);
    final navInset = MediaQuery.paddingOf(context).bottom;
    final isEmpty = summary.groups.isEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.page, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My cart', style: context.text.headlineMedium),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: Motion.medium,
                              child: Text(
                                isEmpty
                                    ? 'Nothing here yet'
                                    : '${summary.itemCount} ${summary.itemCount == 1 ? 'item' : 'items'} from ${summary.groups.length} ${summary.groups.length == 1 ? 'shop' : 'shops'}',
                                key: ValueKey('${summary.itemCount}-${summary.groups.length}'),
                                style: context.text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isEmpty)
                        TextButton.icon(
                          onPressed: () => _confirmClear(context, ref),
                          style: TextButton.styleFrom(foregroundColor: p.muted),
                          icon: const AppIcon(PhosphorIconsRegular.trash, size: 18),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.slow,
                    switchInCurve: Motion.emphasized,
                    child: isEmpty
                        ? Padding(
                            key: const ValueKey('empty'),
                            padding: EdgeInsets.only(bottom: navInset),
                            child: EmptyState(
                              title: 'Your cart is empty',
                              message:
                                  'Find something you love from shops across CartBoat and it will sail right in here.',
                              actionLabel: 'Start shopping',
                              onAction: () => context.go(Paths.home),
                            ),
                          )
                        : RefreshIndicator(
                            key: const ValueKey('list'),
                            color: p.primary,
                            onRefresh: () => ref.read(cartProvider.notifier).refreshPrices(),
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, navInset + 190),
                              children: [
                                if (summary.savings > 0)
                                  _SavingsBanner(amount: summary.savings).animate().fadeIn(duration: 300.ms),
                                for (var g = 0; g < summary.groups.length; g++)
                                  _SellerGroupCard(
                                        key: ValueKey(summary.groups[g].sellerId),
                                        group: summary.groups[g],
                                        index: g,
                                        count: summary.groups.length,
                                      )
                                      .animate()
                                      .fadeIn(delay: (70 * g).ms, duration: 360.ms)
                                      .slideY(
                                        begin: 0.06,
                                        delay: (70 * g).ms,
                                        duration: 480.ms,
                                        curve: Motion.emphasized,
                                      ),
                                const SizedBox(height: 4),
                                _SummaryCard(summary: summary),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: navInset + 10,
              child: AnimatedSlide(
                duration: Motion.slow,
                curve: Motion.emphasized,
                offset: isEmpty ? const Offset(0, 1.6) : Offset.zero,
                child: AnimatedOpacity(
                  duration: Motion.medium,
                  opacity: isEmpty ? 0 : 1,
                  child: _CheckoutBar(total: summary.total),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsBanner extends StatelessWidget {
  const _SavingsBanner({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: BrandColors.seafoamSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const AppIcon(PhosphorIconsFill.confetti, color: BrandColors.tide700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Nice! You\'re saving '),
                  TextSpan(
                    text: money(amount.roundToDouble()),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' on this order'),
                ],
              ),
              style: context.text.labelMedium?.copyWith(color: BrandColors.tide800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerGroupCard extends ConsumerWidget {
  const _SellerGroupCard({super.key, required this.group, required this.index, required this.count});
  final SellerGroup group;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.card,
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(9)),
                  child: AppIcon(PhosphorIconsFill.storefront, size: 16, color: p.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.sellerName ?? 'Shop ${index + 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                      Text(
                        count > 1 ? 'Shipment ${index + 1} of $count' : 'Single shipment',
                        style: context.text.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Pill(
                  'Delivery ${money(Env.shippingPerSeller)}',
                  icon: PhosphorIconsBold.truck,
                  color: p.inkSoft,
                  background: p.surfaceAlt,
                  dense: true,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.line),
          for (final item in group.items) _CartLine(key: ValueKey(item.variantId), item: item),
        ],
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({super.key, required this.item});
  final CartItem item;

  void _remove(BuildContext context, WidgetRef ref) {
    final items = ref.read(cartProvider);
    final index = items.indexWhere((i) => i.variantId == item.variantId);
    final removed = ref.read(cartProvider.notifier).remove(item.variantId);
    HapticFeedback.mediumImpact();
    if (removed == null) return;
    final notifier = ref.read(cartProvider.notifier);
    AppToast.show(
      context,
      message: 'Removed ${item.name}',
      icon: PhosphorIconsFill.trash,
      actionLabel: 'Undo',
      onAction: () => notifier.restore(removed, index),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Dismissible(
      key: ValueKey('dismiss-${item.variantId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context, ref),
      background: Container(
        color: p.dangerSoft,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove',
              style: context.text.labelMedium?.copyWith(color: p.danger, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            AppIcon(PhosphorIconsBold.trash, color: p.danger, size: 20),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pressable(
              onTap: () => ProductRoute.openSlug(context, item.slug),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(width: 84, height: 84, child: NetImage(item.image, decodeWidth: 120)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                      Pressable(
                        onTap: () => _remove(context, ref),
                        scale: 0.85,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: AppIcon(PhosphorIconsRegular.x, size: 18, color: p.muted),
                        ),
                      ),
                    ],
                  ),
                  if (item.variantLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.variantLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PriceLine(
                          price: item.price,
                          original: item.originalPrice > item.price ? item.originalPrice : null,
                          size: 15,
                        ),
                      ),
                      QuantityStepper(
                        compact: true,
                        value: item.quantity,
                        max: item.maxQuantity,
                        min: 1,
                        onChanged: (q) => ref.read(cartProvider.notifier).setQuantity(item.variantId, q),
                      ),
                    ],
                  ),
                  if (item.stock > 0 && item.stock <= 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Only ${item.stock} left',
                        style: context.text.bodySmall?.copyWith(color: p.warning, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      child: Column(
        children: [
          _AnimatedRow('Subtotal', summary.subtotal),
          _AnimatedRow(
            'Delivery · ${summary.groups.length} ${summary.groups.length == 1 ? 'shop' : 'shops'}',
            summary.shipping,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: p.line),
          ),
          _AnimatedRow('Total', summary.total, emphasize: true),
        ],
      ),
    );
  }
}

class _AnimatedRow extends StatelessWidget {
  const _AnimatedRow(this.label, this.value, {this.emphasize = false});
  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: emphasize ? t.titleMedium : t.bodyMedium)),
          AnimatedMoney(value, style: emphasize ? t.titleLarge : t.titleSmall),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.line),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: context.text.bodySmall),
                AnimatedMoney(total, style: context.text.titleLarge),
              ],
            ),
          ),
          PrimaryButton(
            expand: false,
            height: 52,
            label: 'Checkout',
            icon: PhosphorIconsBold.lockSimple,
            onPressed: () => context.push(Paths.checkout),
          ),
        ],
      ),
    );
  }
}
