import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/pressable.dart';

Future<ProductSort?> showSortSheet(BuildContext context, ProductSort current) {
  return showModalBottomSheet<ProductSort>(
    context: context,
    useRootNavigator: true,
    builder: (context) {
      final p = context.palette;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort by', style: context.text.titleLarge),
              const SizedBox(height: 12),
              for (final s in ProductSort.values)
                Pressable(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, s);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: s == current ? p.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.label,
                            style: context.text.titleSmall?.copyWith(
                              color: s == current ? p.primary : p.ink,
                              fontWeight: s == current ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        AnimatedScale(
                          duration: Motion.medium,
                          curve: Motion.spring,
                          scale: s == current ? 1 : 0,
                          child: AppIcon(PhosphorIconsFill.checkCircle, color: p.primary, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<ProductQuery?> showFilterSheet(
  BuildContext context, {
  required ProductQuery current,
  required List<FilterCategory> categories,
  required bool allowCategory,
}) {
  return showModalBottomSheet<ProductQuery>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _FilterSheet(current: current, categories: categories, allowCategory: allowCategory),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.categories, required this.allowCategory});

  final ProductQuery current;
  final List<FilterCategory> categories;
  final bool allowCategory;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ProductCondition? _condition = widget.current.condition;
  late bool _discounted = widget.current.onlyDiscounted;
  late String? _tag = widget.current.tag;
  late String? _category = widget.current.categorySlug;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.page, 0, 12, 4),
            child: Row(
              children: [
                Expanded(child: Text('Filters', style: context.text.titleLarge)),
                TextButton(
                  onPressed: () => setState(() {
                    _condition = null;
                    _discounted = false;
                    _tag = null;
                    if (widget.allowCategory) _category = null;
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, 24),
              children: [
                _label(context, 'Condition'),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(context, 'Any', _condition == null, () => setState(() => _condition = null)),
                    for (final c in ProductCondition.values)
                      _chip(context, c.label, _condition == c, () => setState(() => _condition = c)),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      AppIcon(PhosphorIconsDuotone.sealPercent, color: p.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('On sale only', style: context.text.titleSmall),
                            Text('Show discounted products', style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      Switch(value: _discounted, onChanged: (v) => setState(() => _discounted = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _label(context, 'Collections'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in ProductTags.filterable)
                      _chip(
                        context,
                        ProductTags.label(t),
                        _tag == t,
                        () => setState(() => _tag = _tag == t ? null : t),
                      ),
                  ],
                ),
                if (widget.allowCategory && widget.categories.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _label(context, 'Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in widget.categories.take(24))
                        _chip(
                          context,
                          '${c.name}  ${c.count}',
                          _category == c.slug,
                          () => setState(() => _category = _category == c.slug ? null : c.slug),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, 12),
              child: PrimaryButton(
                label: 'Show results',
                onPressed: () => Navigator.pop(
                  context,
                  ProductQuery(
                    search: widget.current.search,
                    categorySlug: _category,
                    tag: _tag,
                    condition: _condition,
                    onlyDiscounted: _discounted,
                    sort: widget.current.sort,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: context.text.titleSmall?.copyWith(color: context.palette.muted)),
  );

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final p = context.palette;
    return Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      scale: 0.94,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.primary : p.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: selected ? p.primary : p.line),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(color: selected ? p.onPrimary : p.ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
