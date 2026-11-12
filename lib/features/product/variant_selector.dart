import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/pressable.dart';

const _swatches = <String, Color>{
  'black': Color(0xFF1B1B1F),
  'white': Color(0xFFF7F7F5),
  'red': Color(0xFFE5484D),
  'blue': Color(0xFF2F80ED),
  'navy': Color(0xFF1E2A55),
  'green': Color(0xFF2E9E5B),
  'olive': Color(0xFF6B7A3A),
  'midnight green': Color(0xFF2F4A43),
  'gray': Color(0xFF8E9399),
  'grey': Color(0xFF8E9399),
  'space gray': Color(0xFF4A4C50),
  'silver': Color(0xFFC9CCD1),
  'gold': Color(0xFFD9B871),
  'rose': Color(0xFFE8B4B8),
  'pink': Color(0xFFF08DB1),
  'purple': Color(0xFF8E5BD8),
  'yellow': Color(0xFFF2C94C),
  'orange': Color(0xFFF2994A),
  'brown': Color(0xFF8B5E3C),
  'beige': Color(0xFFE8D9BE),
  'maroon': Color(0xFF7A1F2B),
  'teal': BrandColors.tide600,
};

Color? swatchFor(String value) {
  final v = value.toLowerCase().trim();
  if (_swatches.containsKey(v)) return _swatches[v];
  for (final e in _swatches.entries) {
    if (v.contains(e.key)) return e.value;
  }
  return null;
}

/// Picks the variant that best matches [key]=[value] while keeping the
/// other currently-selected attributes, preferring in-stock options.
ProductVariant resolveVariant(ProductDetail product, ProductVariant current, String key, String value) {
  final candidates = product.variants.where((v) => v.valueOf(key) == value).toList();
  if (candidates.isEmpty) return current;
  int score(ProductVariant v) {
    var s = 0;
    for (final a in current.attributes) {
      if (a.key != key && v.valueOf(a.key) == a.value) s += 2;
    }
    if (v.inStock) s += 1;
    return s;
  }

  candidates.sort((a, b) => score(b).compareTo(score(a)));
  return candidates.first;
}

ProductVariant? defaultVariant(ProductDetail product) {
  if (product.variants.isEmpty) return null;
  return product.variants.firstWhere((v) => v.inStock, orElse: () => product.variants.first);
}

class VariantSelector extends StatelessWidget {
  const VariantSelector({super.key, required this.product, required this.selected, required this.onChanged});

  final ProductDetail product;
  final ProductVariant selected;
  final ValueChanged<ProductVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final keys = product.attributeKeys;
    if (keys.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in keys) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${titleCase(key)}  ', style: context.text.titleSmall),
                TextSpan(
                  text: selected.valueOf(key) ?? '—',
                  style: context.text.bodyMedium?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in product.valuesFor(key))
                _OptionChip(
                  label: value,
                  swatch: key.toLowerCase().contains('colo') ? swatchFor(value) : null,
                  selected: selected.valueOf(key) == value,
                  available: product.variants.any((v) => v.valueOf(key) == value && v.inStock),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(resolveVariant(product, selected, key, value));
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.available,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final bool selected;
  final bool available;
  final VoidCallback onTap;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        padding: EdgeInsets.fromLTRB(swatch != null ? 8 : 16, 9, 16, 9),
        decoration: BoxDecoration(
          color: selected ? p.primarySoft : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? p.primary : p.line, width: selected ? 1.8 : 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatch != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.line),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: available ? (selected ? p.primary : p.ink) : p.muted,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                decoration: available ? null : TextDecoration.lineThrough,
                decorationColor: p.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
