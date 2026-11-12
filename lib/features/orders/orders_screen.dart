import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/auth_controller.dart';
import '../../state/order_providers.dart';
import 'order_widgets.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
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
        title: const Text('My orders'),
      ),
      body: !signedIn
          ? const SignInPrompt(
              icon: PhosphorIconsDuotone.package,
              title: 'Sign in to see your orders',
              message: 'Orders you place while signed in show up here, with live status from each shop.',
            )
          : Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: 6),
                    children: [
                      _FilterChip(label: 'All', selected: _status == null, onTap: () => setState(() => _status = null)),
                      for (final s in OrderStage.values)
                        _FilterChip(
                          label: s.label,
                          selected: _status == s.api,
                          onTap: () => setState(() => _status = s.api),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.medium,
                    child: _OrdersList(key: ValueKey(_status), status: _status),
                  ),
                ),
              ],
            ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({super.key, required this.status});
  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider(status));
    final p = context.palette;
    return RefreshIndicator(
      color: p.primary,
      onRefresh: () => ref.refresh(ordersProvider(status).future),
      child: orders.when(
        skipLoadingOnRefresh: true,
        data: (page) {
          if (page.items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: PhosphorIconsDuotone.package,
                  title: status == null
                      ? 'No orders yet'
                      : 'No ${OrderStage.fromApi(status)?.label.toLowerCase() ?? ''} orders',
                  message: 'When you place an order it will appear here so you can follow it to your door.',
                  actionLabel: status == null ? 'Start shopping' : null,
                  onAction: () => context.go(Paths.home),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, MediaQuery.paddingOf(context).bottom + 24),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => OrderCard(order: page.items[i])
                .animate()
                .fadeIn(delay: (40 * i.clamp(0, 8)).ms, duration: 320.ms)
                .slideY(begin: 0.08, delay: (40 * i.clamp(0, 8)).ms, duration: 440.ms, curve: Motion.emphasized),
          );
        },
        loading: () => Shimmer(
          child: ListView.separated(
            padding: const EdgeInsets.all(Gap.page),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, _) => const Skeleton(height: 128, radius: 20),
          ),
        ),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 60),
            ErrorState(error: e, onRetry: () => ref.invalidate(ordersProvider(status))),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        scale: 0.94,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? p.ink : p.surface,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: selected ? p.ink : p.line),
          ),
          child: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: selected ? p.background : p.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
