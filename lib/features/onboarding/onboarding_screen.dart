import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/router/routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/cartboat_logo.dart';
import '../../shared/widgets/common.dart';

class _Slide {
  const _Slide(this.title, this.body, this.hero, this.orbit);
  final String title;
  final String body;
  final IconData hero;
  final List<IconData> orbit;
}

const _slides = [
  _Slide(
    'Every shop,\none cart',
    'Browse products from many independent sellers and check out once. We split the order per shop for you.',
    PhosphorIconsDuotone.storefront,
    [PhosphorIconsFill.tShirt, PhosphorIconsFill.deviceMobile, PhosphorIconsFill.armchair, PhosphorIconsFill.sneaker],
  ),
  _Slide(
    'Deals that\nset sail daily',
    'Flash sales, top deals and pre-owned picks, refreshed every day so there is always something new on board.',
    PhosphorIconsDuotone.tag,
    [PhosphorIconsFill.lightning, PhosphorIconsFill.percent, PhosphorIconsFill.recycle, PhosphorIconsFill.fire],
  ),
  _Slide(
    'Pay your way,\ntrack every order',
    'Cash on delivery, mobile banking or card. Follow each shipment from the shop to your doorstep.',
    PhosphorIconsDuotone.package,
    [PhosphorIconsFill.truck, PhosphorIconsFill.wallet, PhosphorIconsFill.mapPin, PhosphorIconsFill.shieldCheck],
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(prefsProvider).setBool(PrefKeys.onboarded, true);
    context.go(Paths.home);
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page.round() >= _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: Motion.slow, curve: Motion.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = _page.round() == _slides.length - 1;
    return AnnotatedRegion(
      value: context.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.page, 8, 8, 0),
                child: Row(
                  children: [
                    const CartBoatLockup(markSize: 30, fontSize: 19),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: Motion.fast,
                      opacity: last ? 0 : 1,
                      child: TextButton(onPressed: last ? null : _finish, child: const Text('Skip')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  itemBuilder: (context, i) {
                    final delta = (i - _page);
                    return _SlideView(slide: _slides[i], delta: delta);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, Gap.lg),
                child: Row(
                  children: [
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _slides.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3.4,
                        spacing: 6,
                        activeDotColor: p.primary,
                        dotColor: p.line,
                      ),
                    ),
                    const Spacer(),
                    AnimatedSize(
                      duration: Motion.medium,
                      curve: Motion.standard,
                      child: PrimaryButton(
                        expand: false,
                        label: last ? 'Get started' : 'Next',
                        icon: last ? PhosphorIconsBold.sailboat : null,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.delta});
  final _Slide slide;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fade = (1 - delta.abs()).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Transform.translate(
              // Parallax: the art drifts slower than the page.
              offset: Offset(delta * 120, 0),
              child: _Illustration(slide: slide),
            ),
          ),
          const SizedBox(height: 28),
          Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(delta * 40, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slide.title, style: context.text.displaySmall),
                  const SizedBox(height: 12),
                  Text(slide.body, style: context.text.bodyLarge?.copyWith(color: p.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final positions = const [
      Alignment(-0.78, -0.62),
      Alignment(0.8, -0.5),
      Alignment(-0.7, 0.66),
      Alignment(0.74, 0.7),
    ];
    final tints = const [BrandColors.sail500, BrandColors.seafoam, Colors.white, BrandColors.sail400];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.tide600, BrandColors.tide800],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RingsPainter(Colors.white.withValues(alpha: 0.07)))),
          Center(
            child:
                Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: AppIcon(slide.hero, size: 64, color: Colors.white),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.96, end: 1.04, duration: 2200.ms, curve: Curves.easeInOut),
          ),
          for (var i = 0; i < slide.orbit.length; i++)
            Align(
              alignment: positions[i],
              child:
                  Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AppIcon(
                          slide.orbit[i],
                          color: tints[i] == Colors.white ? BrandColors.tide700 : tints[i],
                          size: 28,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -7, end: 7, duration: (1800 + i * 260).ms, curve: Curves.easeInOut),
            ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final c = size.center(Offset.zero);
    for (var r = 90.0; r < size.longestSide; r += 56) {
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}
