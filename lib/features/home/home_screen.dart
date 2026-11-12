import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/cartboat_logo.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/product_grid.dart';
import '../../state/auth_controller.dart';
import '../../state/catalog_providers.dart';
import 'widgets/home_sections.dart';
import 'widgets/promo_carousel.dart';

const _forYou = ProductQuery();
const _flash = ProductQuery(tag: 'FLASH_SALE');
const _deals = ProductQuery(onlyDiscounted: true, tag: 'TOP_DEALS');
const _newArrivals = ProductQuery(tag: 'NEW_ARRIVAL', sort: ProductSort.newest);
const _preOwned = ProductQuery(condition: ProductCondition.preOwned);
const _trending = ProductQuery(tag: 'TRENDING');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refresh() async {
    ref.invalidate(categoryMenuProvider);
    for (final q in [_flash, _deals, _newArrivals, _preOwned, _trending]) {
      ref.invalidate(productRailProvider(q));
    }
    await ref.read(productListProvider(_forYou).notifier).refresh();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 900) {
      ref.read(productListProvider(_forYou).notifier).loadMore();
    }
    return false;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = ref.watch(currentUserProvider);
    final forYou = ref.watch(productListProvider(_forYou));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget gap(double h) => SliverToBoxAdapter(child: SizedBox(height: h));
    Widget enter(Widget child, int i) => child
        .animate()
        .fadeIn(delay: (60 * i).ms, duration: 420.ms)
        .slideY(begin: 0.06, delay: (60 * i).ms, duration: 520.ms, curve: Motion.emphasized);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: p.primary,
            backgroundColor: p.surface,
            edgeOffset: 8,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.page, 10, Gap.page, 0),
                    child: Row(
                      children: [
                        const CartBoatMark(size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user == null ? '${_greeting()} 👋' : '${_greeting()}, ${user.firstName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              const CartBoatWordmark(fontSize: 20),
                            ],
                          ),
                        ),
                        CircleIconButton(
                          icon: PhosphorIconsRegular.heart,
                          tooltip: 'Saved',
                          onTap: () => context.push(Paths.wishlist),
                        ),
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: PhosphorIconsRegular.bell,
                          tooltip: 'Notifications',
                          onTap: () => context.push(Paths.notifications),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 380.ms),
                ),
                gap(18),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                    child: enter(const SearchPill(), 0),
                  ),
                ),
                gap(20),
                SliverToBoxAdapter(child: enter(const PromoCarousel(), 1)),
                gap(26),
                SliverToBoxAdapter(
                  child: enter(
                    SectionHeader(title: 'Shop by category', action: 'All', onAction: () => context.go(Paths.explore)),
                    2,
                  ),
                ),
                gap(14),
                SliverToBoxAdapter(child: enter(const CategoryStrip(), 3)),
                gap(22),
                SliverToBoxAdapter(
                  child: enter(
                    const ProductRailSection(
                      title: 'Flash Sale',
                      subtitle: 'Ends at midnight',
                      leading: FlashBadge(),
                      trailing: FlashCountdown(),
                      query: _flash,
                      heroScope: 'flash',
                    ),
                    4,
                  ),
                ),
                gap(28),
                const SliverToBoxAdapter(
                  child: ProductRailSection(
                    title: 'Top deals',
                    subtitle: 'Biggest markdowns right now',
                    query: _deals,
                    heroScope: 'deals',
                  ),
                ),
                gap(28),
                const SliverToBoxAdapter(child: PreOwnedBanner()),
                gap(18),
                const SliverToBoxAdapter(
                  child: ProductRailSection(title: 'Second-life finds', query: _preOwned, heroScope: 'preowned'),
                ),
                gap(28),
                const SliverToBoxAdapter(
                  child: ProductRailSection(
                    title: 'New arrivals',
                    subtitle: 'Fresh from our sellers',
                    query: _newArrivals,
                    heroScope: 'new',
                  ),
                ),
                gap(28),
                const SliverToBoxAdapter(
                  child: ProductRailSection(title: 'Trending now', query: _trending, heroScope: 'trending'),
                ),
                gap(30),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Just for you',
                    subtitle: forYou.total > 0 ? '${forYou.total} products from every shop' : null,
                  ),
                ),
                gap(16),
                if (forYou.loading && forYou.items.isEmpty)
                  const ProductGridSkeleton(count: 4)
                else if (forYou.error != null && forYou.items.isEmpty)
                  SliverToBoxAdapter(
                    child: InlineError(onRetry: () => ref.read(productListProvider(_forYou).notifier).refresh()),
                  )
                else
                  ProductSliverGrid(products: forYou.items, heroScope: 'foryou'),
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: Motion.medium,
                    child: forYou.loadingMore
                        ? const Padding(
                            key: ValueKey('more'),
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            ),
                          )
                        : (!forYou.hasNext && forYou.items.isNotEmpty)
                        ? Padding(
                            key: const ValueKey('end'),
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: [
                                CartBoatMark(size: 36, colors: MarkColors.muted(p)),
                                const SizedBox(height: 8),
                                Text('You\'ve reached the shore', style: context.text.bodySmall),
                              ],
                            ),
                          )
                        : const SizedBox(height: 24, key: ValueKey('idle')),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
