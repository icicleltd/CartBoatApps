import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Colour recipe for the boat mark.
class MarkColors {
  const MarkColors({
    required this.hull,
    required this.mast,
    required this.jib,
    required this.sailTop,
    required this.sailBottom,
    required this.wave,
    required this.cutout,
    this.background,
  });

  final Color hull;
  final Color mast;
  final Color jib;
  final Color sailTop;
  final Color sailBottom;
  final Color wave;
  final Color cutout;
  final Gradient? background;

  /// The app-icon look: white boat on a tide gradient tile.
  static const tile = MarkColors(
    hull: Colors.white,
    mast: Colors.white,
    jib: Color(0xFFE6F6F3),
    sailTop: BrandColors.sail400,
    sailBottom: Color(0xFFFF5A2E),
    wave: BrandColors.seafoam,
    cutout: BrandColors.tide700,
    background: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [BrandColors.tide600, BrandColors.tide800],
    ),
  );

  /// White-on-tide without the tile (splash, dark hero areas).
  static const onTide = MarkColors(
    hull: Colors.white,
    mast: Colors.white,
    jib: Color(0xFFE6F6F3),
    sailTop: BrandColors.sail400,
    sailBottom: Color(0xFFFF5A2E),
    wave: BrandColors.seafoam,
    cutout: BrandColors.tide700,
  );

  /// Ink-coloured mark for light surfaces.
  static MarkColors onSurface(AppPalette p) => MarkColors(
    hull: p.primary,
    mast: p.primary,
    jib: p.seafoam.withValues(alpha: 0.55),
    sailTop: BrandColors.sail400,
    sailBottom: BrandColors.sail600,
    wave: p.seafoam,
    cutout: p.surface,
  );

  /// Quiet, desaturated mark for empty states.
  static MarkColors muted(AppPalette p) => MarkColors(
    hull: p.line,
    mast: p.line,
    jib: p.surfaceAlt,
    sailTop: p.accent.withValues(alpha: 0.55),
    sailBottom: p.accent.withValues(alpha: 0.75),
    wave: p.seafoam.withValues(alpha: 0.6),
    cutout: p.background,
  );
}

/// The CartBoat mark: a boat whose hull is a shopping basket (handle at the
/// stern), sailing under a price-tag sail.
///
/// Every part is animatable — [hoist] raises the sails, [bob] rocks the boat
/// and [wavePhase] rolls the water — so the same painter powers the static
/// logo and the animated splash.
class CartBoatMark extends StatelessWidget {
  const CartBoatMark({
    super.key,
    this.size = 48,
    this.colors = MarkColors.tile,
    this.hoist = 1,
    this.bob = 0,
    this.wavePhase = 0,
    this.hullReveal = 1,
  });

  final double size;
  final MarkColors colors;
  final double hoist;
  final double bob;
  final double wavePhase;
  final double hullReveal;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(colors, hoist, bob, wavePhase, hullReveal)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.c, this.hoist, this.bob, this.wavePhase, this.hullReveal);

  final MarkColors c;
  final double hoist;
  final double bob;
  final double wavePhase;
  final double hullReveal;

  // Artwork is authored on the 1024 icon grid; this 860×860 artboard at
  // (82,116) centres the mark (shifted by (24,-6)) with even margins.
  static const _box = 860.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / _box;
    canvas.save();
    canvas.scale(s);
    canvas.translate(-82, -116);

    if (c.background != null) {
      final rect = const Rect.fromLTWH(82, 116, _box, _box);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(196)),
        Paint()..shader = c.background!.createShader(rect),
      );
    }

    canvas.translate(24, -6);

    // Wave — drawn as a sine so it can roll.
    final wave = Path();
    const waveY = 870.0, x0 = 206.0, x1 = 818.0, amp = 20.0, length = 204.0;
    for (double x = x0; x <= x1; x += 4) {
      final y = waveY - amp * math.sin(((x - x0) / length) * 2 * math.pi + wavePhase);
      x == x0 ? wave.moveTo(x, y) : wave.lineTo(x, y);
    }
    canvas.drawPath(
      wave,
      Paint()
        ..color = c.wave
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Boat group bobs together.
    canvas.save();
    canvas.translate(0, bob * 10);
    canvas.rotate(bob * 0.012);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Sails hoist up from the boom (y = 578).
    if (hoist > 0) {
      canvas.save();
      canvas.translate(0, 578 * (1 - hoist));
      canvas.scale(1, hoist.clamp(0.001, 1));

      final jib = Path()
        ..moveTo(470, 318)
        ..lineTo(470, 562)
        ..quadraticBezierTo(470, 578, 454, 578)
        ..lineTo(326, 578)
        ..quadraticBezierTo(306, 578, 318, 562)
        ..close();
      canvas.drawPath(jib, Paint()..color = c.jib);
      canvas.drawPath(
        jib,
        Paint.from(stroke)
          ..color = c.jib
          ..strokeWidth = 10,
      );

      final sail = Path()
        ..moveTo(532, 236)
        ..lineTo(532, 562)
        ..quadraticBezierTo(532, 578, 548, 578)
        ..lineTo(768, 578)
        ..quadraticBezierTo(792, 578, 776, 558)
        ..close();
      final sailShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.sailTop, c.sailBottom],
      ).createShader(const Rect.fromLTRB(532, 236, 792, 578));
      canvas.drawPath(sail, Paint()..shader = sailShader);
      canvas.drawPath(
        sail,
        Paint.from(stroke)
          ..shader = sailShader
          ..strokeWidth = 12,
      );
      canvas.drawCircle(const Offset(586, 452), 24, Paint()..color = c.cutout);
      canvas.restore();
    }

    // Mast
    canvas.drawLine(
      Offset(501, 606 - 392 * hoist.clamp(0.25, 1)),
      const Offset(501, 606),
      Paint.from(stroke)
        ..color = c.mast
        ..strokeWidth = 24,
    );

    // Hull + handle reveal from the stern.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(140, 520, 140 + 700 * hullReveal, 820));
    final handle = Path()
      ..moveTo(276, 634)
      ..lineTo(218, 548)
      ..lineTo(160, 548);
    canvas.drawPath(
      handle,
      Paint.from(stroke)
        ..color = c.hull
        ..strokeWidth = 28,
    );

    final hull = Path()
      ..moveTo(262, 618)
      ..lineTo(800, 618)
      ..quadraticBezierTo(822, 618, 815, 640)
      ..lineTo(752, 778)
      ..quadraticBezierTo(744, 796, 724, 796)
      ..lineTo(350, 796)
      ..quadraticBezierTo(330, 796, 322, 778)
      ..lineTo(246, 640)
      ..quadraticBezierTo(238, 618, 262, 618)
      ..close();
    canvas.drawPath(hull, Paint()..color = c.hull);

    final slot = Paint.from(stroke)
      ..color = c.cutout
      ..strokeWidth = 18;
    canvas.drawLine(const Offset(420, 666), const Offset(430, 748), slot);
    canvas.drawLine(const Offset(534, 666), const Offset(534, 748), slot);
    canvas.drawLine(const Offset(648, 666), const Offset(638, 748), slot);
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.hoist != hoist || old.bob != bob || old.wavePhase != wavePhase || old.hullReveal != hullReveal || old.c != c;
}

/// "CartBoat" wordmark set in Plus Jakarta Sans ExtraBold.
class CartBoatWordmark extends StatelessWidget {
  const CartBoatWordmark({super.key, this.fontSize = 22, this.onDark = false});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w800,
      fontSize: fontSize,
      letterSpacing: -fontSize * 0.035,
      height: 1,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Cart',
            style: base.copyWith(color: onDark ? Colors.white : p.ink),
          ),
          TextSpan(
            text: 'Boat',
            style: base.copyWith(color: onDark ? BrandColors.seafoam : p.primary),
          ),
        ],
      ),
    );
  }
}

/// Horizontal lockup: tile mark + wordmark.
class CartBoatLockup extends StatelessWidget {
  const CartBoatLockup({super.key, this.markSize = 34, this.fontSize = 21, this.onDark = false});

  final double markSize;
  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CartBoatMark(size: markSize),
        SizedBox(width: markSize * 0.3),
        CartBoatWordmark(fontSize: fontSize, onDark: onDark),
      ],
    );
  }
}
