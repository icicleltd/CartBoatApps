import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/user.dart';
import '../../shared/widgets/cartboat_logo.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/toast.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/preferences.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your cart and saved items stay on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.palette.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        AppToast.show(context, message: 'Signed out. See you soon!', icon: PhosphorIconsFill.handWaving);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final auth = ref.watch(authControllerProvider);
    final user = auth.value;
    final saved = ref.watch(wishlistProvider).length;
    final inCart = ref.watch(cartCountProvider);

    final tiles = <Widget>[
      AnimatedSwitcher(
        duration: Motion.slow,
        switchInCurve: Motion.emphasized,
        child: user == null
            ? const _GuestCard(key: ValueKey('guest'))
            : _ProfileCard(key: ValueKey(user.id), user: user),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: PhosphorIconsDuotone.heart,
              label: 'Saved',
              value: '$saved',
              onTap: () => context.push(Paths.wishlist),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: PhosphorIconsDuotone.shoppingBagOpen,
              label: 'In cart',
              value: '$inCart',
              onTap: () => context.go(Paths.cart),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: PhosphorIconsDuotone.package,
              label: 'Orders',
              value: 'Track',
              onTap: () => context.push(Paths.orders),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      _Group(
        title: 'Shopping',
        children: [
          _MenuTile(
            icon: PhosphorIconsDuotone.package,
            title: 'My orders',
            subtitle: 'Track and review purchases',
            onTap: () => context.push(Paths.orders),
          ),
          _MenuTile(
            icon: PhosphorIconsDuotone.heart,
            title: 'Saved items',
            subtitle: '$saved saved',
            onTap: () => context.push(Paths.wishlist),
          ),
          _MenuTile(
            icon: PhosphorIconsDuotone.bell,
            title: 'Notifications',
            subtitle: 'Order and shop updates',
            onTap: () => context.push(Paths.notifications),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (user == null || !user.isSeller)
        Pressable(
          scale: 0.98,
          onTap: () => context.push(Paths.becomeSeller),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: Radii.card,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF7A4D), Color(0xFFE2401C)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const AppIcon(PhosphorIconsFill.storefront, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Become a seller', style: context.text.titleMedium?.copyWith(color: Colors.white)),
                      Text(
                        'Open your shop and reach every CartBoat shopper',
                        style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                const AppIcon(PhosphorIconsBold.arrowRight, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      if (user == null || !user.isSeller) const SizedBox(height: 16),
      _Group(title: 'Preferences', children: [const _AppearanceTile()]),
      const SizedBox(height: 16),
      _Group(
        title: 'About',
        children: [
          _MenuTile(
            icon: PhosphorIconsDuotone.info,
            title: 'About CartBoat',
            subtitle: 'Brand, version & credits',
            onTap: () => context.push(Paths.about),
          ),
          if (user != null)
            _MenuTile(
              icon: PhosphorIconsDuotone.signOut,
              title: 'Sign out',
              danger: true,
              onTap: () => _logout(context, ref),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Center(child: CartBoatMark(size: 30, colors: MarkColors.muted(p))),
      const SizedBox(height: 6),
      Center(child: Text('CartBoat · Every shop. One cart.', style: context.text.bodySmall)),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: p.primary,
          onRefresh: () => ref.read(authControllerProvider.notifier).refresh(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(Gap.page, 12, Gap.page, MediaQuery.paddingOf(context).bottom + 24),
            children: [
              Text('Account', style: context.text.headlineMedium),
              const SizedBox(height: 16),
              ...tiles.animate(interval: 35.ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, curve: Motion.emphasized),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.tide600, BrandColors.tide900],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CartBoatMark(size: 44, colors: MarkColors.onTide),
              Spacer(),
              Pill('GUEST', color: Colors.white, background: Color(0x33FFFFFF), dense: true),
            ],
          ),
          const SizedBox(height: 16),
          Text('Welcome aboard', style: context.text.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            'Sign in to follow your orders, sync your details and check out in seconds.',
            style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Sign in',
                  height: 48,
                  color: Colors.white,
                  foreground: BrandColors.tide800,
                  onPressed: () => context.push(Paths.login),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Pressable(
                  onTap: () => context.push(Paths.register),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: Radii.button,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.4),
                    ),
                    child: Text('Create account', style: context.text.labelLarge?.copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [BrandColors.tide500, BrandColors.tide800]),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: user.avatar != null
                ? NetImage(user.avatar)
                : Text(initials(user.name), style: context.text.titleLarge?.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleLarge),
                Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                if (user.role != null) ...[
                  const SizedBox(height: 6),
                  Pill(titleCase(user.role!), color: p.primary, dense: true, icon: PhosphorIconsFill.sealCheck),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            AppIcon(icon, color: p.primary, size: 24),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: Motion.medium,
              child: Text(value, key: ValueKey(value), style: context.text.titleLarge),
            ),
            Text(label, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(), style: context.text.labelSmall?.copyWith(color: p.muted, letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: Radii.card,
            border: Border.all(color: p.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 64, color: p.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, this.subtitle, this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? p.danger : p.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: danger ? p.dangerSoft : p.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall?.copyWith(color: danger ? p.danger : p.ink)),
                    if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              AppIcon(PhosphorIconsBold.caretRight, size: 14, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceTile extends ConsumerWidget {
  const _AppearanceTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(themeModeProvider);
    final options = [
      (ThemeMode.system, 'Auto', PhosphorIconsBold.circleHalf),
      (ThemeMode.light, 'Light', PhosphorIconsBold.sun),
      (ThemeMode.dark, 'Dark', PhosphorIconsBold.moon),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: AppIcon(PhosphorIconsDuotone.palette, color: p.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Appearance', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              // Inner width excludes the 1px border on each side.
              final w = (c.maxWidth - 2) / options.length;
              final idx = options.indexWhere((o) => o.$1 == mode);
              // The thumb must read as "raised" above the track in both themes.
              final track = context.isDark ? p.background : p.surfaceAlt;
              final thumb = context.isDark ? p.line : p.surface;
              return Container(
                height: 44,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line.withValues(alpha: context.isDark ? 1 : 0)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedPositioned(
                      duration: Motion.medium,
                      curve: Motion.emphasized,
                      left: w * idx + 3,
                      top: 3,
                      bottom: 3,
                      width: w - 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: thumb,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: context.isDark
                              ? null
                              : [BoxShadow(color: p.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final o in options)
                          Expanded(
                            child: Pressable(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref.read(themeModeProvider.notifier).set(o.$1);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AppIcon(o.$3, size: 15, color: mode == o.$1 ? p.primary : p.muted),
                                  const SizedBox(width: 6),
                                  Text(
                                    o.$2,
                                    style: context.text.labelMedium?.copyWith(
                                      color: mode == o.$1 ? p.ink : p.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
