import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/boss_types.dart';
import '../models/enemy_types.dart';
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

/// The sub-slots a category splits into for independent equip state — a
/// mob_skin's [EnemyKind] (ground/fly/hybrid) or a boss_skin's
/// [BossType.slotId] (golem/goblin/ogre/orc, see [kBossTypes]). Returns
/// null for categories with no sub-slots (turret_skin, bullet_effect,
/// bundle), so the caller knows not to show the sub-tab row at all.
List<String>? shopSubSlotsFor(String category) {
  switch (category) {
    case 'mob_skin':
      return EnemyKind.values.map((k) => k.name).toList(growable: false);
    case 'boss_skin':
      return kBossTypes.map((b) => b.slotId).toList(growable: false);
    default:
      return null;
  }
}

/// An item's sub-slot key, read from its own metadata (`kind` for
/// mob_skin items, `slot` for boss_skin items) — null for categories
/// without sub-slots, or a malformed/legacy row missing the field.
String? shopItemSubSlot(Map<String, dynamic> item) {
  final rawMetadata = item['metadata'];
  if (rawMetadata is! String || rawMetadata.isEmpty) return null;
  try {
    final metadata = jsonDecode(rawMetadata) as Map<String, dynamic>;
    return (metadata['kind'] ?? metadata['slot']) as String?;
  } catch (_) {
    return null;
  }
}

/// Horizontal row of sub-slot chips shown below the category rail's
/// selection, when [shopSubSlotsFor] the current category is non-null —
/// e.g. "Ground / Flying / Hybrid" under Mobs, "Golem / Goblin / Ogre /
/// Orc" under Bosses. Shared by the shop and "My customization" so both
/// filter the exact same way.
class ShopSubSlotTabs extends StatelessWidget {
  const ShopSubSlotTabs({
    super.key,
    required this.category,
    required this.slots,
    required this.selected,
    required this.onSelect,
    required this.s,
  });

  final String category;
  final List<String> slots;
  final String selected;
  final ValueChanged<String> onSelect;
  final Strings s;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final slot = slots[i];
          final isSelected = slot == selected;
          return ChoiceChip(
            label: Text(s.shopSubSlotLabel(category, slot)),
            selected: isSelected,
            onSelected: (_) => onSelect(slot),
            selectedColor: const Color(0xFFCB7B2A),
            backgroundColor: const Color(0xFF3A2A1C),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected ? const Color(0xFFCB7B2A) : Colors.white24,
            ),
          );
        },
      ),
    );
  }
}

/// Square bordered image tile shared by the shop grid and "My
/// customization", so an owned/equipped item looks the same in both
/// places. Gold border normally, green when [highlighted] (equipped).
class ShopItemImageTile extends StatelessWidget {
  const ShopItemImageTile({
    super.key,
    required this.imagePath,
    this.highlighted = false,
  });

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

/// Full item detail, opened by tapping a card's icon in either the shop
/// or "My customization" — the grid card's own description is clipped to
/// 2 lines with an ellipsis (deliberately: the grid needs a predictable
/// card height), so this is where the complete, untruncated text lives.
/// Matches BossDefeatedOverlay's look exactly (same frame, same tight
/// gold-bordered icon box) rather than reusing [ShopItemImageTile]'s
/// airier padding, so a modal reads the same wherever it shows up.
void showItemDetailModal(
  BuildContext context, {
  required String? imagePath,
  required String name,
  required String description,
  required Strings s,
}) {
  const gold = Color(0xFFFFC94D);
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: name,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF3A2A1C),
            borderRadius: BorderRadius.circular(18),
            // Same tone as the fill, not gold — the outer frame doesn't
            // need to compete with the icon's own gold border for
            // attention (unlike BossDefeatedOverlay, which is a rarer,
            // celebratory moment that can afford the extra emphasis).
            border: Border.all(color: const Color(0xFF3A2A1C), width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tight padding between the border and the sprite itself —
              // same treatment as the boss-defeated achievement icon, not
              // the airier gold-border look ShopItemImageTile uses in the
              // grid.
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF241a11),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gold, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55FFC94D),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: imagePath != null
                    ? Image.asset(imagePath, fit: BoxFit.contain)
                    : const Icon(Icons.redeem_rounded, color: gold, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppFonts.title(color: Colors.white, fontSize: 17),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCB7B2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.close,
                    style: AppFonts.title(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Left-side "Categories" navigation, shared by the shop and "My
/// customization": one entry per catalog category (see
/// [shopCategoryOrder]), always shown — even for categories with no
/// items/ownership yet — so the caller can show a "coming soon" or
/// "nothing owned here" state per category instead of it just being
/// missing from the list.
class CategoryRail extends StatelessWidget {
  const CategoryRail({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.s,
    required this.headerIcon,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final Strings s;

  /// Shown above the category list in place of a "Categories" text label —
  /// that title used to wrap onto two lines in this narrow rail ("CATEGORÍA
  /// / S"), so each screen instead shows a single icon representing itself
  /// (a shop icon here, a brush icon in "My customization").
  final IconData headerIcon;

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
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Icon(headerIcon, color: const Color(0xFFCB7B2A), size: 26),
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
            Icon(
              icon,
              color: selected ? const Color(0xFFCB7B2A) : Colors.white54,
              size: 22,
            ),
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
