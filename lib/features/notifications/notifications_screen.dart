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
import '../../shared/widgets/skeleton.dart';
import '../../state/auth_controller.dart';
import '../../state/order_providers.dart';
import '../orders/order_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(AppNotification n) {
    final t = '${n.type ?? ''} ${n.title}'.toLowerCase();
    if (t.contains('order')) return PhosphorIconsDuotone.package;
    if (t.contains('ship') || t.contains('deliver')) return PhosphorIconsDuotone.truck;
    if (t.contains('pay')) return PhosphorIconsDuotone.wallet;
    if (t.contains('stock')) return PhosphorIconsDuotone.warehouse;
    if (t.contains('deal') || t.contains('sale') || t.contains('offer')) return PhosphorIconsDuotone.tag;
    return PhosphorIconsDuotone.bell;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final signedIn = ref.watch(isSignedInProvider);
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
        title: const Text('Notifications'),
      ),
      body: !signedIn
          ? const SignInPrompt(
              icon: PhosphorIconsDuotone.bellRinging,
              title: 'Stay in the loop',
              message: 'Sign in to get updates when shops confirm, ship and deliver your orders.',
            )
          : RefreshIndicator(
              color: p.primary,
              onRefresh: () => ref.refresh(notificationsProvider.future),
              child: ref
                  .watch(notificationsProvider)
                  .when(
                    skipLoadingOnRefresh: true,
                    data: (items) => items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 60),
                              EmptyState(
                                icon: PhosphorIconsDuotone.bellSimple,
                                title: 'All caught up',
                                message: 'Order updates and offers will appear here.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, 32),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final n = items[i];
                              return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: n.isRead ? p.surface : p.primarySoft,
                                      borderRadius: Radii.card,
                                      border: Border.all(color: n.isRead ? p.line : p.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: n.isRead ? p.surfaceAlt : p.surface,
                                            borderRadius: BorderRadius.circular(13),
                                          ),
                                          child: AppIcon(_icon(n), color: p.primary, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(child: Text(n.title, style: context.text.titleSmall)),
                                                  if (n.createdAt != null)
                                                    Text(
                                                      relativeTime(n.createdAt!),
                                                      style: context.text.bodySmall?.copyWith(fontSize: 11),
                                                    ),
                                                ],
                                              ),
                                              if (n.message.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Text(n.message, style: context.text.bodyMedium),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (!n.isRead)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8, top: 6),
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: (40 * i.clamp(0, 8)).ms, duration: 300.ms)
                                  .slideX(begin: 0.06, delay: (40 * i.clamp(0, 8)).ms, curve: Motion.emphasized);
                            },
                          ),
                    loading: () => Shimmer(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(Gap.page),
                        itemCount: 6,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, _) => const Skeleton(height: 76, radius: 20),
                      ),
                    ),
                    error: (e, _) => ListView(
                      children: [
                        const SizedBox(height: 60),
                        ErrorState(error: e, onRetry: () => ref.invalidate(notificationsProvider)),
                      ],
                    ),
                  ),
            ),
    );
  }
}
