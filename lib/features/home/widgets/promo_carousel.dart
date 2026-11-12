import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/pressable.dart';

class Promo {
  const Promo({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.cta,
    required this.icon,
    required this.colors,
    required this.listTitle,
    required this.query,
    this.accent = BrandColors.seafoam,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final String listTitle;
  final ProductQuery query;
}

const promos = [
  Promo(
    eyebrow: 'TECH ESSENTIALS',
    title: 'Power meets\nportability',
    body: 'Ultra-thin laptops for creators on the move.',
    cta: 'Shop laptops',
    icon: PhosphorIconsDuotone.laptop,
    colors: [BrandColors.tide600, BrandColors.tide900],
    listTitle: 'Laptops & Computers',
    query: ProductQuery(categorySlug: 'laptops-computers'),
  ),
  Promo(
    eyebrow: 'FLASH SALE',
    title: 'Up to 50% off,\ntoday only',
    body: 'Fresh deals drop every 24 hours.',
    cta: 'Grab the deals',
    icon: PhosphorIconsDuotone.lightning,
    colors: [Color(0xFFFF7A4D), Color(0xFFE2401C)],
    accent: Color(0xFFFFE3D9),
    listTitle: 'Flash Sale',
    query: ProductQuery(tag: 'FLASH_SALE'),
  ),
  Promo(
    eyebrow: 'SUSTAINABLE STYLE',
    title: 'Pre-owned\npicks',
    body: 'A second life for great products. Gentle on your wallet.',
    cta: 'Explore pre-owned',
    icon: PhosphorIconsDuotone.recycle,
    colors: [Color(0xFF1E3A44), Color(0xFF0B1B22)],
    listTitle: 'Pre-owned picks',
    query: ProductQuery(condition: ProductCondition.preOwned),
  ),
  Promo(
    eyebrow: 'SEASON SAVINGS',
    title: 'Curated deals,\nupdated weekly',
    body: 'Hand-picked discounts across every category.',
    cta: 'See savings',
    icon: PhosphorIconsDuotone.sealPercent,
    colors: [Color(0xFF5B4BDB), Color(0xFF2E2483)],
    accent: Color(0xFFD9D4FF),
    listTitle: 'On sale',
    query: ProductQuery(onlyDiscounted: true),
  ),
];

/// Auto-advancing hero banners with parallax content and a pill indicator.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  final _page = ValueNotifier<double>(0);
  Timer? _timer;
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _page.value = _controller.page ?? 0);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _userDragging || !_controller.hasClients) return;
      final next = (_controller.page?.round() ?? 0) + 1;
      _controller.animateToPage(
        next % promos.length,
        duration: const Duration(milliseconds: 700),
        curve: Motion.emphasized,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 188,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) _userDragging = true;
              if (n is ScrollEndNotification && _userDragging) {
                _userDragging = false;
                _schedule();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: promos.length,
              padEnds: true,
              itemBuilder: (context, i) => ValueListenableBuilder<double>(
                valueListenable: _page,
                builder: (context, page, _) => _PromoCard(promo: promos[i], delta: i - page),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<double>(
          valueListenable: _page,
          builder: (context, page, _) => _PillIndicator(count: promos.length, page: page),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.delta});
  final Promo promo;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final d = delta.clamp(-1.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.scale(
        scale: 1 - d.abs() * 0.04,
        child: Pressable(
          scale: 0.98,
          onTap: () => ProductListRoute.open(context, title: promo.listTitle, query: promo.query),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: promo.colors),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -40 + d * 60,
                  top: -30,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                Positioned(
                  right: 40 + d * 90,
                  bottom: -50,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
                Positioned(
                  right: 18 + d * 110,
                  top: 0,
                  bottom: 0,
                  child: Center(child: AppIcon(promo.icon, size: 92, color: Colors.white.withValues(alpha: 0.95))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 130, 18),
                  child: Transform.translate(
                    offset: Offset(d * 40, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.eyebrow,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: promo.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          promo.title,
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 22,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          promo.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                promo.cta,
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: promo.colors.last,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AppIcon(PhosphorIconsBold.arrowRight, size: 13, color: promo.colors.last),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillIndicator extends StatelessWidget {
  const _PillIndicator({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Builder(
            builder: (context) {
              final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7 + 17 * t,
                height: 7,
                decoration: BoxDecoration(
                  color: Color.lerp(p.line, p.primary, t),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
      ],
    );
  }
}
