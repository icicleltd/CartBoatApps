import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/pressable.dart';

({Color fg, Color bg, IconData icon}) statusStyle(BuildContext context, String status) {
  final p = context.palette;
  return switch (OrderStage.fromApi(status)) {
    OrderStage.pending => (fg: p.warning, bg: p.warningSoft, icon: PhosphorIconsFill.hourglassMedium),
    OrderStage.confirmed => (fg: p.primary, bg: p.primarySoft, icon: PhosphorIconsFill.checkCircle),
    OrderStage.processing => (
      fg: BrandColors.info,
      bg: BrandColors.info.withValues(alpha: 0.12),
      icon: PhosphorIconsFill.gearSix,
    ),
    OrderStage.shipped => (
      fg: const Color(0xFF7B61FF),
      bg: const Color(0xFF7B61FF).withValues(alpha: 0.12),
      icon: PhosphorIconsFill.truck,
    ),
    OrderStage.delivered => (fg: p.success, bg: p.successSoft, icon: PhosphorIconsFill.package),
    OrderStage.cancelled => (fg: p.danger, bg: p.dangerSoft, icon: PhosphorIconsFill.xCircle),
    null => (fg: p.inkSoft, bg: p.surfaceAlt, icon: PhosphorIconsFill.circle),
  };
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = statusStyle(context, status);
    return Pill(OrderStage.fromApi(status)?.label ?? titleCase(status), color: s.fg, background: s.bg, icon: s.icon);
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final thumbs = order.lines.where((l) => l.image != null).take(4).toList();
    return Pressable(
      scale: 0.98,
      onTap: () => context.push(Paths.order(order.id)),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ${order.displayNumber}', style: context.text.titleSmall),
                      if (order.createdAt != null) Text(dateTime(order.createdAt!), style: context.text.bodySmall),
                    ],
                  ),
                ),
                StatusPill(order.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (thumbs.isEmpty)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                    child: AppIcon(PhosphorIconsDuotone.package, color: p.muted),
                  )
                else
                  for (final l in thumbs)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(width: 46, height: 46, child: NetImage(l.image, decodeWidth: 70)),
                      ),
                    ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}', style: context.text.bodySmall),
                    Text(money(order.total), style: context.text.titleMedium),
                  ],
                ),
                const SizedBox(width: 4),
                AppIcon(PhosphorIconsBold.caretRight, size: 14, color: p.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Prompt shown on account-only screens for guests.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({
    super.key,
    required this.title,
    required this.message,
    this.icon = PhosphorIconsDuotone.userCircle,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: 'Sign in',
      onAction: () => context.push(Paths.login),
    );
  }
}
