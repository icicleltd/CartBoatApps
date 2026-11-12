import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/order_repository.dart';
import '../../shared/widgets/common.dart';
import '../../state/auth_controller.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  const OrderSuccessScreen({super.key, required this.orders});
  final List<PlacedOrder> orders;

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> with TickerProviderStateMixin {
  late final AnimationController _check = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _check.forward();
      _burst.forward();
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _check.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final signedIn = ref.watch(isSignedInProvider);
    final count = widget.orders.length;
    final total = widget.orders.fold<double>(0, (s, o) => s + o.total);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Paths.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_burst.value)),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(Gap.page, 48, Gap.page, 24),
                children: [
                  Center(
                    child: SizedBox(
                      width: 132,
                      height: 132,
                      child: AnimatedBuilder(
                        animation: _check,
                        builder: (context, _) => CustomPaint(
                          painter: _CheckPainter(progress: _check.value, color: p.primary, soft: p.primarySoft),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    count > 1 ? '$count orders placed!' : 'Order placed!',
                    textAlign: TextAlign.center,
                    style: context.text.headlineMedium,
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.3, curve: Motion.emphasized),
                  const SizedBox(height: 10),
                  Text(
                    count > 1
                        ? 'Your items come from $count shops, so we split them into separate orders. Each shop will confirm and ship its part.'
                        : 'The shop has received your order and will confirm it shortly.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(color: p.muted),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.3, curve: Motion.emphasized),
                  const SizedBox(height: 28),
                  if (widget.orders.isNotEmpty)
                    SurfaceCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < widget.orders.length; i++) ...[
                            if (i > 0) Divider(color: p.line, height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: p.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: AppIcon(PhosphorIconsDuotone.package, color: p.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Order ${widget.orders[i].number}', style: context.text.titleSmall),
                                      Text('Awaiting confirmation', style: context.text.bodySmall),
                                    ],
                                  ),
                                ),
                                if (widget.orders[i].total > 0)
                                  Text(money(widget.orders[i].total), style: context.text.titleSmall),
                              ],
                            ),
                          ],
                          if (total > 0 && count > 1) ...[
                            Divider(color: p.line, height: 24),
                            SummaryRow('Total', money(total), emphasize: true),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 700.ms, duration: 400.ms).slideY(begin: 0.12, curve: Motion.emphasized),
                  const SizedBox(height: 28),
                  if (signedIn)
                    PrimaryButton(
                      label: 'Track my orders',
                      icon: PhosphorIconsBold.package,
                      onPressed: () => context.go(Paths.orders),
                    )
                  else
                    PrimaryButton(
                      label: 'Create an account to track orders',
                      onPressed: () => context.push(Paths.register),
                    ),
                  const SizedBox(height: 12),
                  SecondaryButton(label: 'Continue shopping', onPressed: () => context.go(Paths.home)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color, required this.soft});
  final double progress;
  final Color color;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final grow = Curves.easeOutBack.transform((progress / 0.45).clamp(0, 1));
    canvas.drawCircle(c, r * grow, Paint()..color = soft);
    canvas.drawCircle(c, r * 0.72 * grow, Paint()..color = color);

    final t = Curves.easeOutCubic.transform(((progress - 0.4) / 0.6).clamp(0, 1));
    if (t <= 0) return;
    final path = Path()
      ..moveTo(c.dx - r * 0.3, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.08, c.dy + r * 0.24)
      ..lineTo(c.dx + r * 0.32, c.dy - r * 0.2);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static final _rand = math.Random(7);
  static final _pieces = List.generate(36, (i) {
    final angle = -math.pi / 2 + (_rand.nextDouble() - 0.5) * math.pi * 1.3;
    return (
      angle: angle,
      speed: 260 + _rand.nextDouble() * 260,
      spin: (_rand.nextDouble() - 0.5) * 10,
      color: [BrandColors.sail500, BrandColors.seafoam, BrandColors.tide600, const Color(0xFFF2C94C)][i % 4],
      w: 6 + _rand.nextDouble() * 6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final origin = Offset(size.width / 2, 48 + 66);
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final p in _pieces) {
      final d = p.speed * Curves.easeOutCubic.transform(t);
      final gravity = 420 * t * t;
      final pos = origin + Offset(math.cos(p.angle) * d, math.sin(p.angle) * d + gravity);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.w * 0.5),
          const Radius.circular(2),
        ),
        Paint()..color = p.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
