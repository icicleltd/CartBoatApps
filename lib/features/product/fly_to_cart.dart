import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/net_image.dart';

/// Animates a product thumbnail along an arc from [from] into the widget
/// identified by [targetKey] (the cart button), then calls [onArrive].
void flyToCart({
  required BuildContext context,
  required Rect from,
  required GlobalKey targetKey,
  required String? image,
  VoidCallback? onArrive,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
  if (overlay == null || targetBox == null || !targetBox.attached) {
    onArrive?.call();
    return;
  }
  final to = targetBox.localToGlobal(targetBox.size.center(Offset.zero));
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Flight(
      from: from,
      to: to,
      image: image,
      onDone: () {
        entry.remove();
        onArrive?.call();
      },
    ),
  );
  overlay.insert(entry);
}

class _Flight extends StatefulWidget {
  const _Flight({required this.from, required this.to, required this.image, required this.onDone});

  final Rect from;
  final Offset to;
  final String? image;
  final VoidCallback onDone;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 720))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final start = widget.from.center;
    final end = widget.to;
    // Control point lifts the arc above both endpoints.
    final control = Offset((start.dx + end.dx) / 2, (start.dy < end.dy ? start.dy : end.dy) - 140);
    final startSize = widget.from.shortestSide.clamp(60.0, 180.0);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final pos = Offset(
            (1 - t) * (1 - t) * start.dx + 2 * (1 - t) * t * control.dx + t * t * end.dx,
            (1 - t) * (1 - t) * start.dy + 2 * (1 - t) * t * control.dy + t * t * end.dy,
          );
          final size = startSize * (1 - t) + 22 * t;
          final opacity = _c.value < 0.85 ? 1.0 : (1 - (_c.value - 0.85) / 0.15);
          return Stack(
            children: [
              Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                width: size,
                height: size,
                child: Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: Transform.rotate(
                    angle: t * 0.6,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * 0.28),
                        border: Border.all(color: p.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NetImage(widget.image, decodeWidth: 220),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
