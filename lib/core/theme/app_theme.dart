import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'tokens.dart';
import 'transitions.dart';

const kFontFamily = 'PlusJakartaSans';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppPalette.light);
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static TextTheme _textTheme(AppPalette p) {
    TextStyle s(double size, FontWeight w, {double ls = 0, double h = 1.3, Color? c}) => TextStyle(
      fontFamily: kFontFamily,
      fontSize: size,
      fontWeight: w,
      letterSpacing: ls,
      height: h,
      color: c ?? p.ink,
    );
    return TextTheme(
      displayLarge: s(40, FontWeight.w800, ls: -1.2, h: 1.1),
      displayMedium: s(34, FontWeight.w800, ls: -1.0, h: 1.1),
      displaySmall: s(30, FontWeight.w800, ls: -0.8, h: 1.15),
      headlineLarge: s(28, FontWeight.w800, ls: -0.7, h: 1.2),
      headlineMedium: s(24, FontWeight.w800, ls: -0.5, h: 1.2),
      headlineSmall: s(21, FontWeight.w700, ls: -0.4, h: 1.25),
      titleLarge: s(19, FontWeight.w700, ls: -0.3, h: 1.3),
      titleMedium: s(16, FontWeight.w700, ls: -0.2, h: 1.35),
      titleSmall: s(14, FontWeight.w700, ls: -0.1, h: 1.35),
      bodyLarge: s(16, FontWeight.w500, h: 1.5, c: p.inkSoft),
      bodyMedium: s(14, FontWeight.w500, h: 1.5, c: p.inkSoft),
      bodySmall: s(12, FontWeight.w500, h: 1.45, c: p.muted),
      labelLarge: s(15, FontWeight.w700, ls: -0.1),
      labelMedium: s(13, FontWeight.w600),
      labelSmall: s(11, FontWeight.w700, ls: 0.2),
    );
  }

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final text = _textTheme(p);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primarySoft,
      onPrimaryContainer: p.primary,
      secondary: p.accent,
      onSecondary: Colors.white,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.accentInk,
      tertiary: p.seafoam,
      onTertiary: BrandColors.tide900,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.line,
      outline: p.line,
      outlineVariant: p.line,
      shadow: p.shadow,
      inverseSurface: isDark ? BrandColors.sand50 : BrandColors.ink900,
      onInverseSurface: isDark ? BrandColors.ink900 : BrandColors.sand50,
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: Radii.field,
      borderSide: BorderSide(color: p.line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: kFontFamily,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      extensions: [p],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CartBoatPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CartBoatPageTransitionsBuilder(),
          TargetPlatform.windows: CartBoatPageTransitionsBuilder(),
          TargetPlatform.linux: CartBoatPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.ink,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.ink, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: text.bodyMedium?.copyWith(color: p.muted),
        labelStyle: text.bodyMedium?.copyWith(color: p.muted),
        floatingLabelStyle: text.labelMedium?.copyWith(color: p.primary),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.primary, width: 1.6)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.danger)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.danger, width: 1.6)),
        errorStyle: text.bodySmall?.copyWith(color: p.danger, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.line,
          disabledForegroundColor: p.muted,
          minimumSize: const Size(64, 54),
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(64, 54),
          side: BorderSide(color: p.line, width: 1.4),
          shape: const RoundedRectangleBorder(borderRadius: Radii.button),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primary,
        side: BorderSide(color: p.line),
        labelStyle: text.labelMedium,
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        showDragHandle: true,
        dragHandleColor: p.line,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : p.muted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : p.surfaceAlt),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.line,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : Colors.transparent,
        ),
        side: BorderSide(color: p.muted, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.2),
        selectionHandleColor: p.primary,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(primaryColor: p.primary),
    );
  }
}

/// Global scroll feel: springy, iOS-style overscroll on every platform.
class CartBoatScrollBehavior extends MaterialScrollBehavior {
  const CartBoatScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
