import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartboat/core/router/routes.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/order_providers.dart';
import 'order_widgets.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderId));
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Center(
          child: CircleIconButton(
            icon: PhosphorIconsBold.arrowLeft,
            size: 40,
            iconSize: 18,
            onTap: () => context.popOrHome(),
          ),
        ),
        title: Text(async.value?.displayNumber == null ? 'Order' : 'Order ${async.value!.displayNumber}'),
      ),
      body: async.when(
        data: (order) => ListView(
          padding: EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status', style: context.text.bodySmall),
                            const SizedBox(height: 4),
                            StatusPill(order.status),
                          ],
                        ),
                      ),
                      if (order.createdAt != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Placed', style: context.text.bodySmall),
                            Text(shortDate(order.createdAt!), style: context.text.titleSmall),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Timeline(order: order),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: context.text.titleMedium),
                  const SizedBox(height: 10),
                  for (final line in order.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(width: 58, height: 58, child: NetImage(line.image, decodeWidth: 90)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.titleSmall,
                                ),
                                Text(
                                  [
                                    if (line.variant != null && line.variant!.isNotEmpty) line.variant!,
                                    'Qty ${line.quantity}',
                                  ].join(' · '),
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (line.price > 0) Text(money(line.price * line.quantity), style: context.text.titleSmall),
                        ],
                      ),
                    ),
                  if (order.lines.isEmpty) Text('Item details are not available.', style: context.text.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (order.address != null)
              SurfaceCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(PhosphorIconsDuotone.mapPin, color: p.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivering to', style: context.text.bodySmall),
                          if (order.customerName != null) Text(order.customerName!, style: context.text.titleSmall),
                          Text(order.address!, style: context.text.bodyMedium),
                          if (order.customerPhone != null) Text(order.customerPhone!, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: Column(
                children: [
                  SummaryRow('Payment', PaymentMethodOption.labelOf(order.paymentMethod)),
                  if (order.paymentStatus != null) SummaryRow('Payment status', titleCase(order.paymentStatus!)),
                  Divider(color: p.line, height: 20),
                  SummaryRow('Subtotal', money(order.subtotal)),
                  SummaryRow('Delivery', money(order.shipping)),
                  if (order.discount > 0)
                    SummaryRow('Discount', '−${money(order.discount)}', valueColor: BrandColors.success),
                  const SizedBox(height: 4),
                  SummaryRow('Total', money(order.total), emphasize: true),
                ],
              ),
            ),
            if (order.note != null) ...[
              const SizedBox(height: 14),
              SurfaceCard(child: Text('Note: ${order.note}', style: context.text.bodyMedium)),
            ],
          ].animate(interval: 50.ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, curve: Motion.emphasized),
        ),
        loading: () => const Shimmer(
          child: Padding(
            padding: EdgeInsets.all(Gap.page),
            child: Column(
              children: [Skeleton(height: 200, radius: 20), SizedBox(height: 14), Skeleton(height: 160, radius: 20)],
            ),
          ),
        ),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stage = order.stage;
    if (stage == OrderStage.cancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.dangerSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            AppIcon(PhosphorIconsFill.xCircle, color: p.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text('This order was cancelled.', style: context.text.titleSmall?.copyWith(color: p.danger)),
            ),
          ],
        ),
      );
    }
    final current = stage == null ? 0 : OrderStage.timeline.indexOf(stage);
    return Row(
      children: [
        for (var i = 0; i < OrderStage.timeline.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == 0 ? Colors.transparent : (i <= current ? p.primary : p.line),
                      ),
                    ),
                    AnimatedContainer(
                      duration: Motion.slow,
                      width: i == current ? 26 : 18,
                      height: i == current ? 26 : 18,
                      decoration: BoxDecoration(
                        color: i <= current ? p.primary : p.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: i <= current ? p.primary : p.line, width: 2),
                      ),
                      child: i <= current
                          ? AppIcon(PhosphorIconsBold.check, size: i == current ? 14 : 10, color: p.onPrimary)
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == OrderStage.timeline.length - 1
                            ? Colors.transparent
                            : (i < current ? p.primary : p.line),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  OrderStage.timeline[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    fontSize: 10,
                    color: i <= current ? p.ink : p.muted,
                    fontWeight: i == current ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
