import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cartboat/core/router/routes.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/cartboat_logo.dart';
import '../../shared/widgets/common.dart';

/// Brand sheet: logo, palette and type — handy for the team and reviewers.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const swatches = [
      ('Tide', '#0E5F68', BrandColors.tide700),
      ('Deep Tide', '#0A4550', BrandColors.tide800),
      ('Sail', '#FF6A3D', BrandColors.sail500),
      ('Seafoam', '#6FE0D2', BrandColors.seafoam),
      ('Ink', '#0F1B24', BrandColors.ink900),
      ('Sand', '#FAF8F4', BrandColors.sand50),
    ];
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Center(
          child: CircleIconButton(
            icon: PhosphorIconsBold.arrowLeft,
            size: 40,
            iconSize: 18,
            onTap: () => context.popOrHome(),
          ),
        ),
        title: const Text('About CartBoat'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.page, 8, Gap.page, 40),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BrandColors.tide600, BrandColors.tide900],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CartBoatMark(size: 92, colors: MarkColors.onTide),
                const SizedBox(height: 14),
                const CartBoatWordmark(fontSize: 30, onDark: true),
                const SizedBox(height: 6),
                Text('Every shop. One cart.', style: context.text.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'CartBoat brings independent shops together in one marketplace. Browse every seller, fill one cart, and we route each part of your order to the shop that sells it.',
            style: context.text.bodyLarge,
          ),
          const SizedBox(height: 26),
          Text('The mark', style: context.text.titleMedium),
          const SizedBox(height: 8),
          Text(
            'A boat whose hull is a shopping basket, sailing under a price-tag sail. The tag\'s punch-hole doubles as a porthole.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const CartBoatMark(size: 64),
              const SizedBox(width: 14),
              CartBoatMark(size: 64, colors: MarkColors.onSurface(p)),
              const SizedBox(width: 14),
              CartBoatMark(size: 64, colors: MarkColors.muted(p)),
            ],
          ),
          const SizedBox(height: 26),
          Text('Palette', style: context.text.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: [
              for (final s in swatches)
                Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Container(color: s.$3)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1, style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                            Text(s.$2, style: context.text.bodySmall?.copyWith(fontSize: 10.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Text('Typography', style: context.text.titleMedium),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plus Jakarta Sans', style: context.text.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Geometric, warm and highly legible at small sizes. One family, five weights.',
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Aa Bb Cc 0123456789', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w400)),
                Text('Aa Bb Cc 0123456789', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text('Aa Bb Cc 0123456789', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Center(child: Text('Version 1.0.0', style: context.text.bodySmall)),
        ].animate(interval: 40.ms).fadeIn(duration: 320.ms).slideY(begin: 0.05, curve: Motion.emphasized),
      ),
    );
  }
}
