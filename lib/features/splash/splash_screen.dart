import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/cartboat_logo.dart';
import '../../state/auth_controller.dart';
import '../../state/catalog_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward();
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();

  late final _hull = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
  );
  late final _hoist = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.25, 0.7, curve: Curves.easeOutBack),
  );
  late final _word = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
  );
  late final _tagline = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _boot();
  }

  Future<void> _boot() async {
    // Warm up data the home screen needs while the intro plays.
    ref.read(categoryMenuProvider.future).ignore();
    final auth = ref.read(authControllerProvider.future).timeout(const Duration(seconds: 5)).catchError((_) => null);
    await Future.wait([Future<void>.delayed(const Duration(milliseconds: 1900)), auth]);
    if (!mounted) return;
    final onboarded = ref.read(prefsProvider).getBool(PrefKeys.onboarded) ?? false;
    context.go(onboarded ? Paths.home : Paths.onboarding);
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandColors.tide600, BrandColors.tide700, BrandColors.tide900],
          ),
        ),
        child: Stack(
          children: [
            // Soft light blooms for depth.
            Positioned(
              top: -120,
              right: -80,
              child: _Bloom(size: 320, color: BrandColors.seafoam.withValues(alpha: 0.16)),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _Bloom(size: 360, color: BrandColors.sail500.withValues(alpha: 0.12)),
            ),
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_intro, _loop]),
                builder: (context, _) {
                  final phase = _loop.value * 2 * math.pi;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CartBoatMark(
                        size: 196,
                        colors: MarkColors.onTide,
                        hullReveal: _hull.value,
                        hoist: _hoist.value,
                        bob: math.sin(phase) * 0.6,
                        wavePhase: -phase,
                      ),
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: _word.value,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - _word.value)),
                          child: const CartBoatWordmark(fontSize: 38, onDark: true),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _tagline.value,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - _tagline.value)),
                          child: Text(
                            'Every shop. One cart.',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
