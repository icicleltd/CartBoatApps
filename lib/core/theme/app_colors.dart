import 'package:flutter/material.dart';

/// CartBoat brand palette.
///
/// Tide (deep sea teal) carries the brand, Sail (coral) is reserved for
/// deals and moments of delight, Seafoam is a soft highlight, and the warm
/// Sand neutrals keep the UI calm so product photos stay the hero.
abstract final class BrandColors {
  // Tide — primary
  static const tide900 = Color(0xFF08353C);
  static const tide800 = Color(0xFF0A4550);
  static const tide700 = Color(0xFF0E5F68);
  static const tide600 = Color(0xFF127A80);
  static const tide500 = Color(0xFF1A9399);
  static const tide300 = Color(0xFF4CC3BA);
  static const tide100 = Color(0xFFD5EEEC);
  static const tide50 = Color(0xFFECF7F6);

  // Sail — accent
  static const sail600 = Color(0xFFF0532A);
  static const sail500 = Color(0xFFFF6A3D);
  static const sail400 = Color(0xFFFF8A5C);
  static const sailInk = Color(0xFFC93D16);
  static const sail100 = Color(0xFFFFE3D9);
  static const sail50 = Color(0xFFFFF2EC);

  // Seafoam — highlight
  static const seafoam = Color(0xFF6FE0D2);
  static const seafoamSoft = Color(0xFFDDF7F3);

  // Ink & Sand — neutrals
  static const ink900 = Color(0xFF0F1B24);
  static const ink700 = Color(0xFF3A4752);
  static const ink500 = Color(0xFF6B7782);
  static const ink300 = Color(0xFFA9B2BA);
  static const sand200 = Color(0xFFE6E2DA);
  static const sand100 = Color(0xFFF2EEE7);
  static const sand50 = Color(0xFFFAF8F4);
  static const white = Color(0xFFFFFFFF);

  // Semantic
  static const success = Color(0xFF1F9D6B);
  static const warning = Color(0xFFE9A23B);
  static const danger = Color(0xFFE5484D);
  static const info = Color(0xFF2F80ED);
}

/// Theme-aware semantic colours, available through `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.seafoam,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color line;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color seafoam;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color skeleton;
  final Color skeletonHighlight;
  final Color shadow;

  static const light = AppPalette(
    background: BrandColors.sand50,
    surface: BrandColors.white,
    surfaceAlt: BrandColors.sand100,
    line: BrandColors.sand200,
    ink: BrandColors.ink900,
    inkSoft: BrandColors.ink700,
    muted: BrandColors.ink500,
    primary: BrandColors.tide700,
    onPrimary: BrandColors.white,
    primarySoft: BrandColors.tide50,
    accent: BrandColors.sail500,
    accentInk: BrandColors.sailInk,
    accentSoft: BrandColors.sail50,
    seafoam: BrandColors.seafoam,
    success: BrandColors.success,
    successSoft: Color(0xFFE3F5EC),
    warning: Color(0xFFB7791F),
    warningSoft: Color(0xFFFDF1DC),
    danger: BrandColors.danger,
    dangerSoft: Color(0xFFFDE8E8),
    skeleton: Color(0xFFEDE9E2),
    skeletonHighlight: Color(0xFFF8F6F2),
    shadow: Color(0x140F1B24),
  );

  static const dark = AppPalette(
    background: Color(0xFF0B1418),
    surface: Color(0xFF121E23),
    surfaceAlt: Color(0xFF1A282E),
    line: Color(0xFF24353C),
    ink: Color(0xFFEEF3F2),
    inkSoft: Color(0xFFC3CFD0),
    muted: Color(0xFF8D9DA2),
    primary: BrandColors.tide300,
    onPrimary: Color(0xFF032A2E),
    primarySoft: Color(0xFF13302F),
    accent: Color(0xFFFF7A50),
    accentInk: Color(0xFFFF9B78),
    accentSoft: Color(0xFF3A2019),
    seafoam: BrandColors.seafoam,
    success: Color(0xFF3CC48D),
    successSoft: Color(0xFF13302A),
    warning: Color(0xFFF2B85B),
    warningSoft: Color(0xFF3A2D16),
    danger: Color(0xFFFF6B6F),
    dangerSoft: Color(0xFF3A1A1C),
    skeleton: Color(0xFF1A282E),
    skeletonHighlight: Color(0xFF233439),
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      line: l(line, other.line),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      muted: l(muted, other.muted),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      accent: l(accent, other.accent),
      accentInk: l(accentInk, other.accentInk),
      accentSoft: l(accentSoft, other.accentSoft),
      seafoam: l(seafoam, other.seafoam),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      skeleton: l(skeleton, other.skeleton),
      skeletonHighlight: l(skeletonHighlight, other.skeletonHighlight),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
