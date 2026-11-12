import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import 'pressable.dart';

enum ToastTone { neutral, success, error }

/// Lightweight floating toast that glides up from the bottom. Replaces
/// SnackBars so feedback floats above the nav bar and never shoves layout.
abstract final class AppToast {
  static OverlayEntry? _current;
  static _ToastState? _state;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    ToastTone tone = ToastTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2600),
    double bottomOffset = 96,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _dismissNow();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        message: message,
        icon: icon,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        bottomOffset: bottomOffset,
        onRegister: (s) => _state = s,
        onDone: () {
          if (_current == entry) {
            _current = null;
            _state = null;
          }
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) => show(
    context,
    message: message,
    tone: ToastTone.success,
    icon: PhosphorIconsFill.checkCircle,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void error(BuildContext context, Object error) => show(
    context,
    message: error.toString(),
    tone: ToastTone.error,
    icon: PhosphorIconsFill.warningCircle,
    duration: const Duration(milliseconds: 3400),
  );

  static void _dismissNow() {
    final entry = _current;
    if (entry == null) return;
    if (_state?.mounted ?? false) {
      _state!.dismiss(immediate: true);
    } else {
      entry.remove();
    }
    _current = null;
    _state = null;
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.icon,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.bottomOffset,
    required this.onRegister,
    required this.onDone,
  });

  final String message;
  final IconData? icon;
  final ToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final double bottomOffset;
  final ValueChanged<_ToastState> onRegister;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.slow,
    reverseDuration: Motion.medium,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.onRegister(this);
    _c.forward();
    _timer = Timer(widget.duration, dismiss);
  }

  void dismiss({bool immediate = false}) {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (immediate) {
      widget.onDone();
      return;
    }
    _c.reverse().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inverse = context.isDark ? BrandColors.sand50 : BrandColors.ink900;
    final onInverse = context.isDark ? BrandColors.ink900 : Colors.white;
    final iconColor = switch (widget.tone) {
      ToastTone.success => context.isDark ? BrandColors.tide700 : BrandColors.seafoam,
      ToastTone.error => p.danger,
      ToastTone.neutral => onInverse,
    };
    final curved = CurvedAnimation(parent: _c, curve: Motion.emphasized, reverseCurve: Curves.easeInCubic);
    final bottom = MediaQuery.paddingOf(context).bottom + widget.bottomOffset;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(curved),
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(curved),
              child: Dismissible(
                key: const ValueKey('toast'),
                direction: DismissDirection.down,
                onDismissed: (_) => dismiss(immediate: true),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    constraints: const BoxConstraints(minHeight: 54),
                    decoration: BoxDecoration(
                      color: inverse,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          AppIcon(widget.icon, color: iconColor, size: 22),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelMedium?.copyWith(color: onInverse, height: 1.35),
                          ),
                        ),
                        if (widget.actionLabel != null)
                          Pressable(
                            onTap: () {
                              widget.onAction?.call();
                              dismiss();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Text(
                                widget.actionLabel!,
                                style: context.text.labelMedium?.copyWith(
                                  color: context.isDark ? BrandColors.tide700 : BrandColors.seafoam,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
