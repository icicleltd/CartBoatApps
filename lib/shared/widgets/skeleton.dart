import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Drives one shared shimmer sweep for every [Skeleton] beneath it, so a
/// screen full of placeholders moves in perfect unison.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  static ShimmerState? of(BuildContext context) => context.findAncestorStateOfType<ShimmerState>();

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height, this.radius = 12, this.circle = false});

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shimmer = Shimmer.of(context);
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: p.skeleton,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
    if (shimmer == null) return box;
    return AnimatedBuilder(
      animation: shimmer.controller,
      builder: (context, child) {
        final t = shimmer.controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1.5 + 3 * t, -0.3),
            end: Alignment(-0.5 + 3 * t, 0.3),
            colors: [p.skeleton, p.skeletonHighlight, p.skeleton],
            stops: const [0.1, 0.5, 0.9],
          ).createShader(rect),
          child: child,
        );
      },
      child: box,
    );
  }
}

/// Placeholder matching [ProductCard]'s silhouette.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key, this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 1, child: Skeleton(radius: 18)),
          const SizedBox(height: 12),
          Skeleton(width: width == null ? 70 : width! * 0.45, height: 10),
          const SizedBox(height: 8),
          const Skeleton(height: 12),
          const SizedBox(height: 6),
          Skeleton(width: width == null ? 90 : width! * 0.6, height: 12),
          const SizedBox(height: 12),
          const Skeleton(width: 72, height: 16),
        ],
      ),
    );
  }
}
