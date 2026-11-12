import 'package:flutter/material.dart';
import 'package:cartboat/core/theme/app_icons.dart';

import '../../core/theme/app_colors.dart';
import 'net_image.dart';

/// Picks a fitting icon for a category from keywords in its slug/name, so
/// categories without artwork still look intentional.
IconData categoryIcon(String slugOrName) {
  final s = slugOrName.toLowerCase();
  const map = <String, IconData>{
    'headphone': PhosphorIconsDuotone.headphones,
    'audio': PhosphorIconsDuotone.headphones,
    'phone': PhosphorIconsDuotone.deviceMobile,
    'mobile': PhosphorIconsDuotone.deviceMobile,
    'laptop': PhosphorIconsDuotone.laptop,
    'computer': PhosphorIconsDuotone.desktop,
    'keyboard': PhosphorIconsDuotone.keyboard,
    'camera': PhosphorIconsDuotone.camera,
    'electronic': PhosphorIconsDuotone.lightning,
    'fashion': PhosphorIconsDuotone.tShirt,
    'cloth': PhosphorIconsDuotone.tShirt,
    'shirt': PhosphorIconsDuotone.tShirt,
    'dress': PhosphorIconsDuotone.dress,
    'saree': PhosphorIconsDuotone.dress,
    'sharee': PhosphorIconsDuotone.dress,
    'skirt': PhosphorIconsDuotone.dress,
    'piece': PhosphorIconsDuotone.dress,
    'peice': PhosphorIconsDuotone.dress,
    'footwear': PhosphorIconsDuotone.sneaker,
    'accessor': PhosphorIconsDuotone.watch,
    'health': PhosphorIconsDuotone.heartbeat,
    'fitness': PhosphorIconsDuotone.barbell,
    'medical': PhosphorIconsDuotone.firstAidKit,
    'vitamin': PhosphorIconsDuotone.pill,
    'personal': PhosphorIconsDuotone.drop,
    'home': PhosphorIconsDuotone.house,
    'living': PhosphorIconsDuotone.armchair,
    'furniture': PhosphorIconsDuotone.armchair,
    'bedding': PhosphorIconsDuotone.bed,
    'decor': PhosphorIconsDuotone.lamp,
    'kitchen': PhosphorIconsDuotone.cookingPot,
    'automotive': PhosphorIconsDuotone.car,
    'car': PhosphorIconsDuotone.car,
    'bike': PhosphorIconsDuotone.bicycle,
    'cycling': PhosphorIconsDuotone.bicycle,
    'tool': PhosphorIconsDuotone.wrench,
    'beauty': PhosphorIconsDuotone.sparkle,
    'cosmetic': PhosphorIconsDuotone.sparkle,
    'makeup': PhosphorIconsDuotone.sparkle,
    'skincare': PhosphorIconsDuotone.drop,
    'hair': PhosphorIconsDuotone.scissors,
    'fragrance': PhosphorIconsDuotone.flowerTulip,
    'toy': PhosphorIconsDuotone.puzzlePiece,
    'game': PhosphorIconsDuotone.gameController,
    'puzzle': PhosphorIconsDuotone.puzzlePiece,
    'figure': PhosphorIconsDuotone.robot,
    'book': PhosphorIconsDuotone.books,
    'stationery': PhosphorIconsDuotone.pencilSimple,
    'art': PhosphorIconsDuotone.palette,
    'notebook': PhosphorIconsDuotone.notebook,
    'office': PhosphorIconsDuotone.briefcase,
    'grocery': PhosphorIconsDuotone.basket,
    'food': PhosphorIconsDuotone.carrot,
    'beverage': PhosphorIconsDuotone.coffee,
    'snack': PhosphorIconsDuotone.cookie,
    'spice': PhosphorIconsDuotone.pepper,
    'sport': PhosphorIconsDuotone.soccerBall,
    'camping': PhosphorIconsDuotone.tent,
    'hiking': PhosphorIconsDuotone.mountains,
    'team': PhosphorIconsDuotone.soccerBall,
  };
  for (final e in map.entries) {
    if (s.contains(e.key)) return e.value;
  }
  return PhosphorIconsDuotone.tag;
}

const _tints = [
  BrandColors.tide600,
  BrandColors.sail500,
  Color(0xFF7B61FF),
  Color(0xFF1F9D6B),
  Color(0xFFE9A23B),
  Color(0xFF2F80ED),
  Color(0xFFD94F8A),
];

Color categoryTint(String key) => _tints[key.codeUnits.fold(0, (a, b) => a + b) % _tints.length];

/// Round category avatar: the category photo when available, otherwise a
/// tinted icon tile.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.name, required this.slug, this.image, this.size = 64, this.radius});

  final String name;
  final String slug;
  final String? image;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final tint = categoryTint(slug);
    final shape = radius == null
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius!));
    final fallback = Container(
      color: tint.withValues(alpha: context.isDark ? 0.22 : 0.12),
      alignment: Alignment.center,
      child: AppIcon(categoryIcon('$slug $name'), color: tint, size: size * 0.44),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: NetImage(image, decodeWidth: size, fallback: fallback),
      ),
    );
  }
}
