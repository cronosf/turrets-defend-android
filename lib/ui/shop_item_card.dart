import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_fonts.dart';

/// The catalog's fixed category order, shared by the shop grid and "My
/// customization" so both screens list categories the same way.
const List<String> shopCategoryOrder = [
  'turret_skin',
  'bullet_effect',
  'mob_skin',
  'boss_skin',
  'bundle',
];

/// The shop item's preview image, generated from the base game sprites
/// (see assets/images/shop/) and referenced by the `asset_key` in the
/// item's `metadata` JSON. Bundles don't carry their own asset_key (their
/// metadata just lists what they include), so this returns null and the
/// caller falls back to a generic icon.
String? shopItemImagePath(Map<String, dynamic> item) {
  final rawMetadata = item['metadata'];
  if (rawMetadata is! String || rawMetadata.isEmpty) return null;
  try {
    final metadata = jsonDecode(rawMetadata) as Map<String, dynamic>;
    final assetKey = metadata['asset_key'] as String?;
    if (assetKey == null) return null;
    return 'assets/images/shop/$assetKey.png';
  } catch (_) {
    return null;
  }
}

/// Square bordered image tile shared by the shop grid and "My
/// customization", so an owned/equipped item looks the same in both
/// places. Gold border normally, green when [highlighted] (equipped).
class ShopItemImageTile extends StatelessWidget {
  const ShopItemImageTile({super.key, required this.imagePath, this.highlighted = false});

  final String? imagePath;
  final bool highlighted;

  static const _gold = Color(0xFFFFC94D);
  static const _green = Color(0xFF3E9B4F);
  static const _goldShadow = Color(0x55FFC94D);
  static const _greenShadow = Color(0x553E9B4F);

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted ? _green : _gold;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF241a11),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: highlighted ? _greenShadow : _goldShadow,
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: imagePath != null
            ? Image.asset(imagePath!, fit: BoxFit.contain)
            : Icon(Icons.redeem_rounded, color: borderColor, size: 40),
      ),
    );
  }
}

/// Left-side "Categories" navigation, shared by the shop and "My
/// customization": one entry per catalog category (see
/// [shopCategoryOrder]), always shown — even for categories with no
/// items/ownership yet — so the caller can show a "coming soon" or
/// "nothing owned here" state per category instead of it just being
/// missing from the list.
class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key, required this.selected, required this.onSelect, required this.s});

  final String selected;
  final ValueChanged<String> onSelect;
  final Strings s;

  static const _icons = {
    'turret_skin': Icons.gps_fixed_rounded,
    'bullet_effect': Icons.bolt_rounded,
    'mob_skin': Icons.bug_report_rounded,
    'boss_skin': Icons.emoji_events_rounded,
    'bundle': Icons.card_giftcard_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: const Color(0xFF241a11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Text(
              s.shopCategoriesTitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppFonts.title(color: const Color(0xFFCB7B2A), fontSize: 11, letterSpacing: 0.5),
            ),
          ),
          for (final category in shopCategoryOrder)
            _CategoryButton(
              label: s.shopCategoryShortLabel(category),
              icon: _icons[category] ?? Icons.category_rounded,
              selected: category == selected,
              onTap: () => onSelect(category),
            ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3A2A1C) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? const Color(0xFFCB7B2A) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? const Color(0xFFCB7B2A) : Colors.white54, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
