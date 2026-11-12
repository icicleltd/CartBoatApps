import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/product_grid.dart';
import '../../state/preferences.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            leadingWidth: 64,
            leading: Center(
              child: CircleIconButton(
                icon: PhosphorIconsBold.arrowLeft,
                size: 40,
                iconSize: 18,
                onTap: () => context.popOrHome(),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saved items'),
                Text('${items.length} ${items.length == 1 ? 'item' : 'items'}', style: context.text.bodySmall),
              ],
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: PhosphorIconsDuotone.heart,
                title: 'No saved items yet',
                message: 'Tap the heart on any product to keep it here for later.',
                actionLabel: 'Discover products',
                onAction: () => context.go(Paths.home),
              ),
            )
          else ...[
            const SliverToBoxAdapter(child: SizedBox(height: Gap.sm)),
            ProductSliverGrid(products: items, heroScope: 'saved'),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 32)),
          ],
        ],
      ),
    );
  }
}
