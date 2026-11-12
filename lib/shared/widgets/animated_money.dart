import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';

/// Money that counts smoothly to its new value instead of jumping.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(this.value, {super.key, this.style, this.prefix = ''});

  final double value;
  final TextStyle? style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: Motion.slow,
      curve: Motion.emphasized,
      builder: (context, v, _) => Text(
        '$prefix${money(v.roundToDouble())}',
        style: (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
