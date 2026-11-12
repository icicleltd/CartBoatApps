import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'tokens.dart';

/// The default push transition: the new page glides in from the right while
/// fading up, and the page underneath eases back and dims slightly. Built on
/// emphasized curves so it starts fast and lands softly.
class CartBoatPageTransitionsBuilder extends PageTransitionsBuilder {
  const CartBoatPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.page;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return GlideTransition(animation: animation, secondaryAnimation: secondaryAnimation, child: child);
  }
}

class GlideTransition extends StatelessWidget {
  const GlideTransition({super.key, required this.animation, required this.secondaryAnimation, required this.child});

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  static final _inSlide = Tween(begin: const Offset(0.18, 0), end: Offset.zero);
  static final _outSlide = Tween(begin: Offset.zero, end: const Offset(-0.06, 0));

  @override
  Widget build(BuildContext context) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: Motion.emphasized,
      reverseCurve: Motion.emphasized.flipped,
    );
    final outgoing = CurvedAnimation(parent: secondaryAnimation, curve: Motion.standard);
    return SlideTransition(
      position: _outSlide.animate(outgoing),
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.85).animate(outgoing),
        child: SlideTransition(
          position: _inSlide.animate(incoming),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0, 0.6, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pages that feel like they rise out of the current context (search,
/// checkout success, auth): a soft fade with a gentle scale-up.
CustomTransitionPage<T> riseUpPage<T>({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.medium,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.emphasized, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// Bottom-up sheet-like page used for flows such as checkout.
CustomTransitionPage<T> slideUpPage<T>({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.medium,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.emphasized, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
