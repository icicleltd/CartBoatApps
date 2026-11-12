import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/category_visuals.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';
import '../../state/catalog_providers.dart';
import '../../state/preferences.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _term = '';

  @override
  void initState() {
    super.initState();
    // Focus after the hero lands so the keyboard doesn't fight the flight.
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final term = raw.trim();
    if (term.isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(recentSearchesProvider.notifier).add(term);
    ProductListRoute.open(
      context,
      title: '"$term"',
      subtitle: 'Search results',
      query: ProductQuery(search: term),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, Gap.page, 8),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: PhosphorIconsBold.arrowLeft,
                    size: 44,
                    iconSize: 18,
                    border: false,
                    background: Colors.transparent,
                    onTap: () => context.popOrHome(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Hero(
                      tag: 'search-field',
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _submit,
                          onChanged: (v) => setState(() => _term = v),
                          style: context.text.bodyLarge?.copyWith(color: p.ink),
                          decoration: InputDecoration(
                            hintText: 'Search products, brands, categories',
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            prefixIcon: AppIcon(PhosphorIconsRegular.magnifyingGlass, color: p.muted, size: 21),
                            suffixIcon: AnimatedSwitcher(
                              duration: Motion.fast,
                              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                              child: _term.isEmpty
                                  ? const SizedBox.shrink()
                                  : IconButton(
                                      key: const ValueKey('clear'),
                                      icon: AppIcon(PhosphorIconsFill.xCircle, color: p.muted, size: 20),
                                      onPressed: () {
                                        _controller.clear();
                                        setState(() => _term = '');
                                      },
                                    ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: p.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: p.primary, width: 1.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Motion.medium,
                switchInCurve: Motion.emphasized,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
                    child: c,
                  ),
                ),
                child: _term.trim().length < 2
                    ? _Discover(key: const ValueKey('discover'), onSearch: _submit)
                    : _Suggestions(key: const ValueKey('suggest'), term: _term.trim(), onSearch: _submit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Discover extends ConsumerWidget {
  const _Discover({super.key, required this.onSearch});
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final recent = ref.watch(recentSearchesProvider);
    final cats = ref.watch(filterCategoriesProvider);

    final quick = [
      (PhosphorIconsDuotone.lightning, 'Flash Sale', const ProductQuery(tag: 'FLASH_SALE'), p.accent),
      (PhosphorIconsDuotone.sealPercent, 'On sale', const ProductQuery(onlyDiscounted: true), const Color(0xFF5B4BDB)),
      (
        PhosphorIconsDuotone.sparkle,
        'New arrivals',
        const ProductQuery(tag: 'NEW_ARRIVAL', sort: ProductSort.newest),
        p.primary,
      ),
      (
        PhosphorIconsDuotone.recycle,
        'Pre-owned',
        const ProductQuery(condition: ProductCondition.preOwned),
        BrandColors.tide800,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.page, 12, Gap.page, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: Text('Recent searches', style: context.text.titleMedium)),
              TextButton(
                onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in recent)
                Pressable(
                  onTap: () => onSearch(r),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(PhosphorIconsRegular.clockCounterClockwise, size: 15, color: p.muted),
                        const SizedBox(width: 6),
                        Text(r, style: context.text.labelMedium),
                        Pressable(
                          onTap: () => ref.read(recentSearchesProvider.notifier).remove(r),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AppIcon(PhosphorIconsBold.x, size: 12, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
        ],
        Text('Quick picks', style: context.text.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.7,
          children: [
            for (final q in quick)
              Pressable(
                onTap: () => ProductListRoute.open(context, title: q.$2, query: q.$3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: q.$4.withValues(alpha: context.isDark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      AppIcon(q.$1, color: q.$4, size: 24),
                      const SizedBox(width: 10),
                      Expanded(child: Text(q.$2, style: context.text.titleSmall)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Text('Popular categories', style: context.text.titleMedium),
        const SizedBox(height: 12),
        cats.when(
          data: (list) {
            final top = [...list]..sort((a, b) => b.count.compareTo(a.count));
            return Column(
              children: [
                for (final c in top.take(8))
                  Pressable(
                    onTap: () => ProductListRoute.open(
                      context,
                      title: c.name,
                      query: ProductQuery(categorySlug: c.slug),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          CategoryAvatar(name: c.name, slug: c.slug, size: 40, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(child: Text(c.name, style: context.text.titleSmall)),
                          Text('${c.count}', style: context.text.bodySmall),
                          const SizedBox(width: 6),
                          AppIcon(PhosphorIconsBold.caretRight, size: 13, color: p.muted),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
          ),
          error: (e, _) => InlineError(onRetry: () => ref.invalidate(filterCategoriesProvider)),
        ),
      ].animate(interval: 40.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, curve: Motion.emphasized),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({super.key, required this.term, required this.onSearch});
  final String term;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(searchSuggestProvider(term));
    final data = async.value;

    Widget row({
      required IconData icon,
      required String text,
      String? trailing,
      required VoidCallback onTap,
      bool accent = false,
    }) => Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent ? p.primary : p.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcon(icon, size: 18, color: accent ? p.onPrimary : p.inkSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Highlighted(text: text, term: term),
            ),
            if (trailing != null) Text(trailing, style: context.text.bodySmall),
            const SizedBox(width: 4),
            AppIcon(PhosphorIconsRegular.arrowUpLeft, size: 16, color: p.muted),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.page, 4, Gap.page, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        row(
          icon: PhosphorIconsBold.magnifyingGlass,
          text: 'Search for "$term"',
          accent: true,
          onTap: () => onSearch(term),
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.emphasized,
          alignment: Alignment.topCenter,
          child: async.isLoading && data == null
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2)),
                  ),
                )
              : (data == null || data.isEmpty)
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    async.hasError
                        ? 'Suggestions are unavailable right now.'
                        : 'No quick matches. Press search to look everywhere.',
                    style: context.text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.categories.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('CATEGORIES', style: context.text.labelSmall?.copyWith(color: p.muted, letterSpacing: 1)),
                      for (final c in data.categories)
                        row(
                          icon: categoryIcon(c.slug),
                          text: c.name,
                          onTap: () => ProductListRoute.open(
                            context,
                            title: c.name,
                            query: ProductQuery(categorySlug: c.slug),
                          ),
                        ),
                    ],
                    if (data.products.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('PRODUCTS', style: context.text.labelSmall?.copyWith(color: p.muted, letterSpacing: 1)),
                      for (final s in data.products)
                        row(
                          icon: PhosphorIconsRegular.bag,
                          text: s.name,
                          onTap: () {
                            ref.read(recentSearchesProvider.notifier).add(s.name);
                            ProductRoute.openSlug(context, s.slug);
                          },
                        ),
                    ],
                    if (data.sellers.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('SHOPS', style: context.text.labelSmall?.copyWith(color: p.muted, letterSpacing: 1)),
                      for (final s in data.sellers)
                        row(icon: PhosphorIconsRegular.storefront, text: s.name, onTap: () => onSearch(s.name)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.term});
  final String text;
  final String term;

  @override
  Widget build(BuildContext context) {
    final base = context.text.bodyLarge?.copyWith(color: context.palette.inkSoft);
    final idx = text.toLowerCase().indexOf(term.toLowerCase());
    if (idx < 0 || term.isEmpty) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + term.length),
            style: TextStyle(color: context.palette.ink, fontWeight: FontWeight.w800),
          ),
          TextSpan(text: text.substring(idx + term.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
  }
}
