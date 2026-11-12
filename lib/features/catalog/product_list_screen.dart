import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/product_grid.dart';
import '../../state/catalog_providers.dart';
import 'filter_sheets.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, required this.args});
  final ProductListArgs args;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late ProductQuery _query = widget.args.query;
  final _scroll = ScrollController();

  bool get _categoryLocked => widget.args.query.categorySlug != null;

  void _setQuery(ProductQuery q) {
    if (q == _query) return;
    setState(() => _query = q);
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: Motion.slow, curve: Motion.emphasized);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 800) {
      ref.read(productListProvider(_query).notifier).loadMore();
    }
    return false;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = ref.watch(productListProvider(_query));
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: RefreshIndicator(
          onRefresh: () => ref.read(productListProvider(_query).notifier).refresh(),
          color: p.primary,
          edgeOffset: 110,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 112,
                backgroundColor: p.background,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: CircleIconButton(
                      icon: PhosphorIconsBold.arrowLeft,
                      size: 40,
                      iconSize: 18,
                      onTap: () => context.popOrHome(),
                    ),
                  ),
                ),
                leadingWidth: 60,
                actions: [
                  CircleIconButton(
                    icon: PhosphorIconsRegular.magnifyingGlass,
                    size: 40,
                    iconSize: 18,
                    onTap: () => context.push(Paths.search),
                  ),
                  const SizedBox(width: 12),
                ],
                // Title rests under the back button when expanded and slides
                // beside it as the bar collapses.
                flexibleSpace: LayoutBuilder(
                  builder: (context, c) {
                    final collapsed = kToolbarHeight + MediaQuery.paddingOf(context).top;
                    final t = ((c.maxHeight - collapsed) / (112 - kToolbarHeight)).clamp(0.0, 1.0);
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        Gap.page + (72 - Gap.page) * (1 - t),
                        0,
                        64,
                        8 + 4 * t,
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.args.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(fontSize: 16 + 6 * t),
                            ),
                            AnimatedSwitcher(
                              duration: Motion.medium,
                              child: Text(
                                state.loading && state.items.isEmpty
                                    ? 'Loading…'
                                    : '${state.total} ${state.total == 1 ? 'product' : 'products'}',
                                key: ValueKey('${state.total}-${state.loading}'),
                                style: context.text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ToolbarDelegate(
                  background: p.background,
                  child: _Toolbar(
                    query: _query,
                    categoryLocked: _categoryLocked,
                    onSort: () async {
                      final s = await showSortSheet(context, _query.sort);
                      if (s != null) _setQuery(_query.copyWith(sort: s));
                    },
                    onFilter: () async {
                      final q = await showFilterSheet(
                        context,
                        current: _query,
                        categories: state.categories,
                        allowCategory: !_categoryLocked,
                      );
                      if (q != null) _setQuery(q);
                    },
                    onToggleSale: () => _setQuery(_query.copyWith(onlyDiscounted: !_query.onlyDiscounted)),
                    onTogglePreOwned: () => _setQuery(
                      _query.condition == ProductCondition.preOwned
                          ? _query.copyWith(clearCondition: true)
                          : _query.copyWith(condition: ProductCondition.preOwned),
                    ),
                    onToggleNew: () => _setQuery(
                      _query.condition == ProductCondition.brandNew
                          ? _query.copyWith(clearCondition: true)
                          : _query.copyWith(condition: ProductCondition.brandNew),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (state.loading && state.items.isEmpty)
                const ProductGridSkeleton()
              else if (state.error != null && state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(
                    error: state.error!,
                    onRetry: () => ref.read(productListProvider(_query).notifier).refresh(),
                  ),
                )
              else if (state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: PhosphorIconsDuotone.magnifyingGlass,
                    title: 'Nothing on board',
                    message: _query.activeFilterCount > (_categoryLocked ? 1 : 0)
                        ? 'No products match these filters. Try loosening them.'
                        : 'We couldn\'t find products here yet.',
                    actionLabel: _query.activeFilterCount > (_categoryLocked ? 1 : 0) ? 'Clear filters' : null,
                    onAction: () => _setQuery(
                      ProductQuery(
                        search: _query.search,
                        categorySlug: widget.args.query.categorySlug,
                        sort: _query.sort,
                      ),
                    ),
                  ),
                )
              else
                ProductSliverGrid(key: ValueKey(_query), products: state.items, heroScope: 'list'),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  child: state.loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4)),
                          ),
                        )
                      : const SizedBox(height: 16),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottom + 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarDelegate extends SliverPersistentHeaderDelegate {
  _ToolbarDelegate({required this.child, required this.background});
  final Widget child;
  final Color background;

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedContainer(
      duration: Motion.fast,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(color: overlapsContent || shrinkOffset > 0 ? context.palette.line : Colors.transparent),
        ),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_ToolbarDelegate old) => old.child != child || old.background != background;
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.categoryLocked,
    required this.onSort,
    required this.onFilter,
    required this.onToggleSale,
    required this.onTogglePreOwned,
    required this.onToggleNew,
  });

  final ProductQuery query;
  final bool categoryLocked;
  final VoidCallback onSort;
  final VoidCallback onFilter;
  final VoidCallback onToggleSale;
  final VoidCallback onTogglePreOwned;
  final VoidCallback onToggleNew;

  @override
  Widget build(BuildContext context) {
    final filters = query.activeFilterCount - (categoryLocked ? 1 : 0);
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: 10),
      children: [
        _ToolChip(
          label: filters > 0 ? 'Filters · $filters' : 'Filters',
          icon: PhosphorIconsBold.slidersHorizontal,
          selected: filters > 0,
          onTap: onFilter,
        ),
        const SizedBox(width: 8),
        _ToolChip(
          label: query.sort == ProductSort.recommended ? 'Sort' : query.sort.label,
          icon: PhosphorIconsBold.arrowsDownUp,
          trailing: PhosphorIconsBold.caretDown,
          selected: query.sort != ProductSort.recommended,
          onTap: onSort,
        ),
        const SizedBox(width: 8),
        _ToolChip(
          label: 'On sale',
          icon: PhosphorIconsBold.percent,
          selected: query.onlyDiscounted,
          onTap: onToggleSale,
        ),
        const SizedBox(width: 8),
        _ToolChip(
          label: 'Pre-owned',
          icon: PhosphorIconsBold.recycle,
          selected: query.condition == ProductCondition.preOwned,
          onTap: onTogglePreOwned,
        ),
        const SizedBox(width: 8),
        _ToolChip(
          label: 'Brand new',
          icon: PhosphorIconsBold.sparkle,
          selected: query.condition == ProductCondition.brandNew,
          onTap: onToggleNew,
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final IconData? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onPrimary : p.ink;
    return Pressable(
      scale: 0.94,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: selected ? p.primary : p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.text.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
            if (trailing != null) ...[const SizedBox(width: 4), AppIcon(trailing, size: 11, color: fg)],
          ],
        ),
      ),
    );
  }
}
