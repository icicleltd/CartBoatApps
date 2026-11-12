import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/category_visuals.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/catalog_providers.dart';
import '../home/widgets/home_sections.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(categoryMenuProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, 12, Gap.page, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore', style: context.text.headlineMedium),
                  const SizedBox(height: 2),
                  Text('Every aisle, every shop', style: context.text.bodySmall),
                  const SizedBox(height: 14),
                  const SearchPill(hint: 'Search in all categories'),
                ],
              ),
            ),
            Expanded(
              child: menu.when(
                skipLoadingOnRefresh: true,
                data: (roots) {
                  if (roots.isEmpty) {
                    return const EmptyState(
                      title: 'No categories yet',
                      message: 'Check back soon, sellers are stocking up.',
                    );
                  }
                  final selected = roots[_selected.clamp(0, roots.length - 1)];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Rail(roots: roots, selected: _selected, onSelect: (i) => setState(() => _selected = i)),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Motion.medium,
                          switchInCurve: Motion.emphasized,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(a),
                              child: child,
                            ),
                          ),
                          child: _Panel(key: ValueKey(selected.pathKey), root: selected),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const _ExploreSkeleton(),
                error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(categoryMenuProvider)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.roots, required this.selected, required this.onSelect});

  final List<CategoryNode> roots;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: p.surfaceAlt.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
      ),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: MediaQuery.paddingOf(context).bottom + 20),
        itemCount: roots.length,
        itemBuilder: (context, i) {
          final c = roots[i];
          final active = i == selected;
          return Pressable(
            onTap: () => onSelect(i),
            scale: 0.94,
            child: AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.emphasized,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: active ? p.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: active ? [BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: Column(
                children: [
                  AnimatedScale(
                    duration: Motion.medium,
                    curve: Motion.spring,
                    scale: active ? 1.08 : 1,
                    child: CategoryAvatar(name: c.name, slug: c.slug, image: c.image, size: 44, radius: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      fontSize: 10.5,
                      color: active ? p.primary : p.inkSoft,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.root});
  final CategoryNode root;

  void _open(BuildContext context, CategoryNode c) => ProductListRoute.open(
    context,
    title: c.name,
    query: ProductQuery(categorySlug: c.slug),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final leaves = root.children.where((c) => !c.hasChildren).toList();
    final groups = root.children.where((c) => c.hasChildren).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, Gap.page, MediaQuery.paddingOf(context).bottom + 24),
      children: [
        Pressable(
          scale: 0.98,
          onTap: () => _open(context, root),
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [categoryTint(root.slug), Color.lerp(categoryTint(root.slug), BrandColors.ink900, 0.45)!],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: AppIcon(
                    categoryIcon('${root.slug} ${root.name}'),
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        root.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleLarge?.copyWith(color: Colors.white),
                      ),
                      if (root.sellerCount > 0)
                        Text(
                          '${root.sellerCount} shops selling here',
                          style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Radii.pill)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Shop all', style: context.text.labelSmall?.copyWith(color: BrandColors.ink900)),
                            const SizedBox(width: 4),
                            const AppIcon(PhosphorIconsBold.arrowRight, size: 12, color: BrandColors.ink900),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (leaves.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Categories', style: context.text.titleSmall?.copyWith(color: p.muted)),
          const SizedBox(height: 12),
          _ChildGrid(children: leaves, onTap: (c) => _open(context, c)),
        ],
        for (final g in groups) ...[
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Text(g.name, style: context.text.titleSmall)),
              Pressable(
                onTap: () => _open(context, g),
                child: Text('See all', style: context.text.labelSmall?.copyWith(color: p.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChildGrid(children: g.children, onTap: (c) => _open(context, c)),
        ],
        if (root.children.isEmpty) ...[
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Tap above to browse everything in ${root.name}.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChildGrid extends StatelessWidget {
  const _ChildGrid({required this.children, required this.onTap});
  final List<CategoryNode> children;
  final ValueChanged<CategoryNode> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 3;
        const spacing = 10.0;
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            for (var i = 0; i < children.length; i++)
              Pressable(
                    onTap: () => onTap(children[i]),
                    child: SizedBox(
                      width: w,
                      child: Column(
                        children: [
                          CategoryAvatar(
                            name: children[i].name,
                            slug: children[i].slug,
                            image: children[i].image,
                            size: w.clamp(48, 76),
                            radius: 18,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            children[i].name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (30 * i).ms, duration: 260.ms)
                  .scaleXY(begin: 0.92, delay: (30 * i).ms, duration: 360.ms, curve: Motion.emphasized),
          ],
        );
      },
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Column(
              children: List.generate(
                6,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Skeleton(width: 44, height: 44, radius: 14),
                      SizedBox(height: 6),
                      Skeleton(width: 50, height: 9),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, Gap.page, 0),
              child: Column(
                children: [
                  Skeleton(height: 128, radius: 22),
                  SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: Skeleton(height: 76, radius: 18)),
                      SizedBox(width: 10),
                      Expanded(child: Skeleton(height: 76, radius: 18)),
                      SizedBox(width: 10),
                      Expanded(child: Skeleton(height: 76, radius: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
