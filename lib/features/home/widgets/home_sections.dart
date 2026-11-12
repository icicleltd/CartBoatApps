import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../state/catalog_providers.dart';

/// Horizontal strip of top-level categories.
class CategoryStrip extends ConsumerWidget {
  const CategoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(categoryMenuProvider);
    return SizedBox(
      height: 104,
      child: menu.when(
        skipLoadingOnRefresh: true,
        data: (roots) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.page),
          itemCount: roots.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            final c = roots[i];
            return Pressable(
              onTap: () => ProductListRoute.open(
                context,
                title: c.name,
                query: ProductQuery(categorySlug: c.slug),
              ),
              child: SizedBox(
                width: 70,
                child: Column(
                  children: [
                    CategoryAvatar(name: c.name, slug: c.slug, image: c.image, size: 64, radius: 22),
                    const SizedBox(height: 8),
                    Text(
                      c.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => Shimmer(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Gap.page),
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, _) => const Column(
              children: [
                Skeleton(width: 64, height: 64, radius: 22),
                SizedBox(height: 10),
                Skeleton(width: 52, height: 10),
              ],
            ),
          ),
        ),
        error: (e, _) => InlineError(onRetry: () => ref.invalidate(categoryMenuProvider)),
      ),
    );
  }
}

/// A titled horizontal rail of products driven by a [ProductQuery].
class ProductRailSection extends ConsumerWidget {
  const ProductRailSection({
    super.key,
    required this.title,
    required this.query,
    required this.heroScope,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final ProductQuery query;
  final String heroScope;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rail = ref.watch(productRailProvider(query));
    // Hide sections that come back empty rather than showing a hole.
    if (rail.hasValue && rail.value!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: title,
                subtitle: subtitle,
                leading: leading,
                action: trailing == null ? 'See all' : null,
                onAction: () => ProductListRoute.open(context, title: title, query: query),
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: Gap.page)],
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.medium,
          child: rail.when(
            skipLoadingOnRefresh: true,
            data: (items) => ProductRail(key: const ValueKey('data'), products: items, heroScope: heroScope),
            loading: () => Shimmer(
              key: const ValueKey('loading'),
              child: SizedBox(
                height: 164 + 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (_, _) => const ProductCardSkeleton(width: 164),
                ),
              ),
            ),
            error: (e, _) =>
                InlineError(key: const ValueKey('error'), onRetry: () => ref.invalidate(productRailProvider(query))),
          ),
        ),
      ],
    );
  }
}

/// Live HH:MM:SS countdown to local midnight, when flash deals refresh.
class FlashCountdown extends StatefulWidget {
  const FlashCountdown({super.key});

  @override
  State<FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<FlashCountdown> {
  late Timer _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (mounted) setState(() => _left = midnight.difference(now));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    String two(int n) => n.toString().padLeft(2, '0');
    Widget box(String v) => Container(
      width: 28,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(8)),
      child: Text(
        v,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
          color: Colors.white,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
    Widget colon() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        ':',
        style: TextStyle(color: p.accent, fontWeight: FontWeight.w800),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        box(two(_left.inHours)),
        colon(),
        box(two(_left.inMinutes % 60)),
        colon(),
        box(two(_left.inSeconds % 60)),
      ],
    );
  }
}

class FlashBadge extends StatelessWidget {
  const FlashBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(11)),
      child: AppIcon(PhosphorIconsFill.lightning, color: p.accent, size: 19),
    );
  }
}

/// Banner introducing the pre-owned collection.
class PreOwnedBanner extends StatelessWidget {
  const PreOwnedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      child: Pressable(
        scale: 0.98,
        onTap: () => ProductListRoute.open(
          context,
          title: 'Pre-owned picks',
          subtitle: 'Expertly checked, second-life products',
          query: const ProductQuery(condition: ProductCondition.preOwned),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: BrandColors.seafoamSoft, borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill('SUSTAINABLE STYLE', color: BrandColors.tide800, background: Colors.white, dense: true),
                    const SizedBox(height: 10),
                    Text('Pre-owned picks', style: context.text.headlineSmall?.copyWith(color: BrandColors.tide900)),
                    const SizedBox(height: 4),
                    Text(
                      'Great products that deserve a second life, at prices that feel just right.',
                      style: context.text.bodySmall?.copyWith(color: BrandColors.tide800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: BrandColors.tide700, shape: BoxShape.circle),
                child: const AppIcon(PhosphorIconsFill.recycle, color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tappable search pill on Home/Explore. Shares a hero with the search
/// screen's field so it appears to expand into it.
class SearchPill extends StatelessWidget {
  const SearchPill({super.key, this.hint = 'Search products, brands, categories'});
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      scale: 0.98,
      onTap: () => context.push(Paths.search),
      child: Hero(
        tag: 'search-field',
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                AppIcon(PhosphorIconsRegular.magnifyingGlass, color: p.muted, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(color: p.muted),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(11)),
                  child: AppIcon(PhosphorIconsBold.slidersHorizontal, color: p.onPrimary, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
