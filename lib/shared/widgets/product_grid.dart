import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/product.dart';
import 'product_card.dart';
import 'skeleton.dart';

int gridColumnsFor(double width) => width >= 900 ? 4 : (width >= 600 ? 3 : 2);

SliverGridDelegate productGridDelegate(double crossAxisExtent, {double horizontalPadding = Gap.page}) {
  final cols = gridColumnsFor(crossAxisExtent);
  const spacing = 14.0;
  final itemWidth = (crossAxisExtent - horizontalPadding * 2 - spacing * (cols - 1)) / cols;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: cols,
    crossAxisSpacing: spacing,
    mainAxisSpacing: 22,
    mainAxisExtent: itemWidth + 118,
  );
}

/// Product grid that animates each card in the first time it appears (and
/// never again on scroll-back, so it stays calm).
class ProductSliverGrid extends StatefulWidget {
  const ProductSliverGrid({super.key, required this.products, required this.heroScope});

  final List<ProductSummary> products;
  final String heroScope;

  @override
  State<ProductSliverGrid> createState() => _ProductSliverGridState();
}

class _ProductSliverGridState extends State<ProductSliverGrid> {
  final _seen = <String>{};
  int _batchStart = 0;

  @override
  void didUpdateWidget(covariant ProductSliverGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products.length < oldWidget.products.length) {
      _seen.clear();
      _batchStart = 0;
    } else if (widget.products.length > oldWidget.products.length) {
      _batchStart = oldWidget.products.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) => SliverGrid(
          gridDelegate: productGridDelegate(constraints.crossAxisExtent + Gap.page * 2),
          delegate: SliverChildBuilderDelegate((context, i) {
            final product = widget.products[i];
            final card = ProductCard(product: product, heroScope: widget.heroScope);
            if (!_seen.add(product.id)) return card;
            final order = (i - _batchStart).clamp(0, 8);
            return card
                .animate()
                .fadeIn(delay: (order * 45).ms, duration: 380.ms, curve: Curves.easeOut)
                .slideY(begin: 0.12, delay: (order * 45).ms, duration: 480.ms, curve: Motion.emphasized);
          }, childCount: widget.products.length),
        ),
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.page),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) => SliverGrid(
            gridDelegate: productGridDelegate(constraints.crossAxisExtent + Gap.page * 2),
            delegate: SliverChildBuilderDelegate((context, i) => const ProductCardSkeleton(), childCount: count),
          ),
        ),
      ),
    );
  }
}
