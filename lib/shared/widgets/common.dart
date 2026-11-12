import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import 'cartboat_logo.dart';
import 'pressable.dart';

/// Small rounded label used for tags, conditions and statuses.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.background, this.icon, this.dense = false});

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;
  final bool dense;

  factory Pill.accent(BuildContext context, String label, {IconData? icon}) {
    final p = context.palette;
    return Pill(label, color: Colors.white, background: p.accent, icon: icon, dense: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = color ?? p.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: background ?? fg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[AppIcon(icon, size: dense ? 11 : 13, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.2,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round translucent icon button used over imagery and in headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize = 20,
    this.background,
    this.color,
    this.border = true,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? color;
  final bool border;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final child = Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? p.surface,
          shape: BoxShape.circle,
          border: border ? Border.all(color: p.line) : null,
        ),
        child: AppIcon(icon, size: iconSize, color: color ?? p.ink),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action, this.onAction, this.leading});

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page - 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: context.text.bodySmall)],
              ],
            ),
          ),
          if (action != null)
            Pressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      action!,
                      style: context.text.labelMedium?.copyWith(color: p.primary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 2),
                    AppIcon(PhosphorIconsBold.caretRight, size: 13, color: p.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Primary call to action with an animated loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.color,
    this.foreground,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;
  final Color? color;
  final Color? foreground;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    final bg = color ?? p.primary;
    final fg = foreground ?? p.onPrimary;
    final button = Pressable(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      scale: 0.97,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.standard,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: onPressed == null ? p.line : bg,
          borderRadius: Radii.button,
          boxShadow: onPressed == null
              ? null
              : [BoxShadow(color: bg.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: Motion.fast,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(a), child: child),
          ),
          child: loading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      AppIcon(icon, size: 20, color: onPressed == null ? p.muted : fg),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelLarge?.copyWith(color: onPressed == null ? p.muted : fg),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon, this.height = 56});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onPressed,
      scale: 0.97,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: Radii.button,
          border: Border.all(color: p.line, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[AppIcon(icon, size: 20, color: p.ink), const SizedBox(width: 8)],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final h = compact ? 34.0 : 44.0;
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) => Pressable(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      scale: 0.85,
      child: SizedBox(
        width: h,
        height: h,
        child: AppIcon(icon, size: compact ? 14 : 17, color: enabled ? p.ink : p.muted.withValues(alpha: 0.5)),
      ),
    );
    return Container(
      height: h,
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(PhosphorIconsBold.minus, value > min, () => onChanged(value - 1)),
          SizedBox(
            width: compact ? 22 : 30,
            child: AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, a) => ScaleTransition(
                scale: a,
                child: FadeTransition(opacity: a, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: (compact ? context.text.labelMedium : context.text.titleSmall)?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          btn(PhosphorIconsBold.plus, value < max, () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

/// Friendly empty / zero-data state with the muted boat mark.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: compact ? 96 : 132,
                  height: compact ? 96 : 132,
                  decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: icon != null
                      ? AppIcon(icon, size: compact ? 38 : 52, color: p.primary)
                      : CartBoatMark(size: compact ? 70 : 96, colors: MarkColors.onSurface(p)),
                )
                .animate()
                .scale(begin: const Offset(0.85, 0.85), duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(begin: 0.3, curve: Motion.emphasized),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: p.muted),
            ).animate().fadeIn(delay: 140.ms, duration: 300.ms).slideY(begin: 0.3, curve: Motion.emphasized),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.3, curve: Motion.emphasized),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final e = ApiException.from(error);
    return EmptyState(
      compact: compact,
      icon: e.isNetwork ? PhosphorIconsDuotone.wifiSlash : PhosphorIconsDuotone.warningCircle,
      title: e.isNetwork ? 'No connection' : 'Something went off course',
      message: e.message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

/// Inline retry row for compact areas such as home rails.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.onRetry, this.message = 'Couldn\'t load this section'});
  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: Radii.card,
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            AppIcon(PhosphorIconsDuotone.cloudWarning, color: p.muted),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: context.text.bodyMedium)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Card surface used throughout forms and summaries.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(Gap.md), this.margin});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.card,
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }
}

/// Thin labelled divider row for summaries: "Subtotal ........ ৳1,200".
class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key, this.emphasize = false, this.valueColor});

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: emphasize ? t.titleMedium : t.bodyMedium)),
          Text(
            value,
            style: (emphasize ? t.titleLarge : t.titleSmall)?.copyWith(
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
