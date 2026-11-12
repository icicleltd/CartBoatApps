import 'package:flutter/widgets.dart';

/// Spacing on a 4pt grid.
abstract final class Gap {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 20.0;
}

abstract final class Radii {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const field = BorderRadius.all(Radius.circular(md));
  static const button = BorderRadius.all(Radius.circular(md));
}

/// Motion tokens — every animation in the app pulls from here so the whole
/// product moves with one rhythm.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const page = Duration(milliseconds: 380);

  /// Material 3 "emphasized decelerate" — quick start, long soft landing.
  static const emphasized = Cubic(0.05, 0.7, 0.1, 1.0);
  static const standard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const exit = Cubic(0.3, 0.0, 0.8, 0.15);
  static const spring = Curves.easeOutBack;
}
