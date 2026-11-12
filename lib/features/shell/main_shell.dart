import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/pressable.dart';
import '../../state/cart_controller.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _tabs = [
  _Tab('Home', PhosphorIconsRegular.house, PhosphorIconsFill.house),
  _Tab('Explore', PhosphorIconsRegular.squaresFour, PhosphorIconsFill.squaresFour),
  _Tab('Cart', PhosphorIconsRegular.shoppingBagOpen, PhosphorIconsFill.shoppingBagOpen),
  _Tab('Account', PhosphorIconsRegular.userCircle, PhosphorIconsFill.userCircle),
];

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: context.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: _FloatingNavBar(
          index: shell.currentIndex,
          onSelect: (i) {
            if (i != shell.currentIndex) HapticFeedback.selectionClick();
            shell.goBranch(i, initialLocation: i == shell.currentIndex);
          },
        ),
      ),
    );
  }
}

class _FloatingNavBar extends ConsumerWidget {
  const _FloatingNavBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final count = ref.watch(cartCountProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 14),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: p.line.withValues(alpha: 0.7)),
          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                flex: i == index ? 14 : 10,
                child: _NavItem(tab: _tabs[i], active: i == index, badge: i == 2 ? count : 0, onTap: () => onSelect(i)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.active, required this.badge, required this.onTap});

  final _Tab tab;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: active,
      button: true,
      label: tab.label,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        child: Center(
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.emphasized,
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: active ? 14 : 0),
            decoration: BoxDecoration(
              color: active ? p.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BadgeIcon(
                  icon: active ? tab.activeIcon : tab.icon,
                  color: active ? p.onPrimary : p.muted,
                  count: badge,
                  active: active,
                ),
                AnimatedSize(
                  duration: Motion.medium,
                  curve: Motion.emphasized,
                  child: active
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: context.text.labelMedium?.copyWith(color: p.onPrimary, fontWeight: FontWeight.w700),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon with a count badge that "bumps" whenever the count changes.
class _BadgeIcon extends StatefulWidget {
  const _BadgeIcon({required this.icon, required this.color, required this.count, required this.active});

  final IconData icon;
  final Color color;
  final int count;
  final bool active;

  @override
  State<_BadgeIcon> createState() => _BadgeIconState();
}

class _BadgeIconState extends State<_BadgeIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
  ]).animate(_bump);

  @override
  void didUpdateWidget(covariant _BadgeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) _bump.forward(from: 0);
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ScaleTransition(
      scale: _scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (c, a) => ScaleTransition(
              scale: a,
              child: FadeTransition(opacity: a, child: c),
            ),
            child: AppIcon(widget.icon, key: ValueKey(widget.icon), color: widget.color, size: 23),
          ),
          if (widget.count > 0)
            Positioned(
              right: -8,
              top: -6,
              child: AnimatedContainer(
                duration: Motion.fast,
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: widget.active ? p.primary : p.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.count > 99 ? '99+' : '${widget.count}',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Keeps every tab alive (like an IndexedStack) but cross-fades between
/// them with a Material "fade through": the old tab fades out quickly, the
/// new one fades in while gently scaling up.
class FadeThroughBranches extends StatefulWidget {
  const FadeThroughBranches({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340), value: 1)..addStatusListener((s) {
        if (s == AnimationStatus.completed && _previous != null) setState(() => _previous = null);
      });
  int? _previous;

  late final Animation<double> _inOpacity = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.28, 1, curve: Curves.easeOut),
  );
  late final Animation<double> _inScale = Tween(begin: 0.965, end: 1.0).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.28, 1, curve: Motion.emphasized),
    ),
  );
  late final Animation<double> _outOpacity = ReverseAnimation(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.28, curve: Curves.easeIn),
    ),
  );

  @override
  void didUpdateWidget(covariant FadeThroughBranches oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previous = oldWidget.currentIndex;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const still = AlwaysStoppedAnimation<double>(1);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _slot(
            i,
            current: i == widget.currentIndex,
            leaving: i == _previous,
            opacity: i == widget.currentIndex ? _inOpacity : (i == _previous ? _outOpacity : still),
            scale: i == widget.currentIndex ? _inScale : still,
          ),
      ],
    );
  }

  Widget _slot(
    int i, {
    required bool current,
    required bool leaving,
    required Animation<double> opacity,
    required Animation<double> scale,
  }) {
    return Offstage(
      offstage: !current && !leaving,
      child: TickerMode(
        enabled: current || leaving,
        // Heroes in hidden tabs would otherwise clash with the visible tab's
        // (e.g. the shared search pill) during page transitions.
        child: HeroMode(
          enabled: current,
          child: IgnorePointer(
            ignoring: !current,
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: opacity,
                child: ScaleTransition(scale: scale, child: widget.children[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
