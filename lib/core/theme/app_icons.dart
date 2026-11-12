import 'package:flutter/widgets.dart';

import 'phosphor_icons.g.dart';

export 'phosphor_icons.g.dart';

/// Drop-in replacement for [Icon] that also renders Phosphor *duotone*
/// glyphs properly: a softly tinted fill layer beneath the outline.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel});

  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final base = Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    final secondary = icon?.fontFamily == 'PhosphorDuotone' ? phosphorDuotoneSecondary[icon!.codePoint] : null;
    if (secondary == null) return base;
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          secondary,
          size: size,
          color: c.withValues(alpha: c.a * 0.22),
        ),
        base,
      ],
    );
  }
}
