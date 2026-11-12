import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';

/// Network image with a calm placeholder, a soft fade-in, decode-size hints
/// (keeps scrolling smooth) and a graceful fallback for broken URLs.
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackIcon,
    this.background,
    this.decodeWidth,
    this.fallback,
  });

  final String? url;
  final BoxFit fit;
  final IconData? fallbackIcon;
  final Color? background;

  /// Logical width hint used to downsample the decoded bitmap.
  final double? decodeWidth;

  /// Shown when the URL is missing or fails to load.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = background ?? p.surfaceAlt;
    final fallback =
        this.fallback ??
        ColoredBox(
          color: bg,
          child: Center(
            child: AppIcon(fallbackIcon ?? PhosphorIconsRegular.image, color: p.muted.withValues(alpha: 0.6), size: 28),
          ),
        );
    final u = url;
    if (u == null || u.isEmpty) return fallback;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final w = decodeWidth ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : 400);
        final cacheW = (w * dpr).clamp(64, 1600).round();
        return CachedNetworkImage(
          imageUrl: u,
          fit: fit,
          memCacheWidth: cacheW,
          fadeInDuration: const Duration(milliseconds: 240),
          fadeOutDuration: const Duration(milliseconds: 120),
          placeholder: (_, _) => this.fallback ?? ColoredBox(color: bg),
          errorWidget: (_, _, _) => fallback,
        );
      },
    );
  }
}
