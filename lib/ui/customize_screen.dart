import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import '../theme/app_fonts.dart';
import 'shop_item_card.dart';

/// "Mi personalización": lets the player equip owned items (turret skins,
/// bullet effects, etc.), grouped by category, one equipped item per
/// category. Reads/writes the same `user_items` / `user_equipped_items`
/// data the shop purchase flow already populates.
class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  late Future<_ProfileItems> _future;
  int? _equippingItemId;
  String? _equippingBasicCategory;
  String _selectedCategory = shopCategoryOrder.first;
  // Remembers the last sub-slot picked per category (mob_skin's kind /
  // boss_skin's slot — see shopSubSlotsFor), same idea as ShopScreen.
  final Map<String, String> _selectedSubSlot = {};

  /// The actual key used with `/profile/equip` and to read equipped state
  /// — plain category for slot-less categories, "category:subSlot" for
  /// mob_skin/boss_skin so e.g. a ground skin and a hybrid skin (or a
  /// golem skin and a future goblin skin) are independent equip slots
  /// instead of fighting over one shared row.
  String _equipCategoryKey(String category, String? subSlot) =>
      subSlot == null ? category : '$category:$subSlot';

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_ProfileItems> _fetch() async {
    final data = await ApiClient.get('/profile') as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final equipped = (data['equipped'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final equippedByCategory = <String, int?>{
      for (final e in equipped)
        e['category'].toString(): (e['shop_item_id'] as num?)?.toInt(),
    };
    return _ProfileItems(items: items, equippedByCategory: equippedByCategory);
  }

  Future<void> _reload() async {
    setState(() => _future = _fetch());
    await _future;
  }

  /// [itemId] null means "equip Basic" (the unmodified default look) —
  /// the server already treats a null shop_item_id as an explicit
  /// unequip for that category.
  Future<void> _equip(String category, int? itemId, Strings s) async {
    setState(() {
      if (itemId == null) {
        _equippingBasicCategory = category;
      } else {
        _equippingItemId = itemId;
      }
    });
    try {
      await ApiClient.post(
        '/profile/equip',
        body: {'category': category, 'shop_item_id': itemId},
      );
      await _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _equippingItemId = null;
          _equippingBasicCategory = null;
        });
      }
    }
  }

  /// A representative "default game look" image for the Basic entry in
  /// each category/sub-slot, so it's visually obvious what "no skin"
  /// looks like — falls back to the shared generic icon (imagePath null)
  /// for categories without an obvious single default sprite.
  String? _basicImagePathFor(String category, String? subSlot) {
    switch (category) {
      case 'turret_skin':
        return 'assets/images/turrets/t1/T1-Shoot_00.png';
      case 'bullet_effect':
        return 'assets/images/projectile/Projectile1.png';
      case 'mob_skin':
        switch (subSlot) {
          case 'fly':
            return 'assets/images/enemies/fly/flyingblue/FlyingBlue-Move_00.png';
          case 'hybrid':
            return 'assets/images/enemies/hybrid/hybridblue/HybridPur-Move_00.png';
          default:
            return 'assets/images/enemies/ground/redbeetle/RedBeetle-move_00.png';
        }
      case 'boss_skin':
        switch (subSlot) {
          case 'goblin':
            return 'assets/images/bosses/goblin/0_Goblin_Walking_000.png';
          case 'ogre':
            return 'assets/images/bosses/ogre/0_Ogre_Walking_000.png';
          case 'orc':
            return 'assets/images/bosses/orc/0_Orc_Walking_000.png';
          default:
            return 'assets/images/bosses/golem2/0_Golem_Walking_000.png';
        }
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A2A1C),
        foregroundColor: Colors.white,
        title: Text(s.customizeTitle),
      ),
      body: FutureBuilder<_ProfileItems>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFCB7B2A)),
            );
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reload,
              color: const Color(0xFFCB7B2A),
              child: ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      s.profileLoadError,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton(
                      onPressed: _reload,
                      child: Text(s.retry),
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final byCategory = <String, List<Map<String, dynamic>>>{};
          for (final item in data.items) {
            final category = item['category']?.toString() ?? '';
            byCategory.putIfAbsent(category, () => []).add(item);
          }
          final subSlots = shopSubSlotsFor(_selectedCategory);
          final currentSubSlot = subSlots == null
              ? null
              : (_selectedSubSlot[_selectedCategory] ?? subSlots.first);
          final equipCategoryKey = _equipCategoryKey(
            _selectedCategory,
            currentSubSlot,
          );
          final categoryItems = byCategory[_selectedCategory] ?? [];
          final selectedItems = currentSubSlot == null
              ? categoryItems
              : categoryItems
                    .where((item) => shopItemSubSlot(item) == currentSubSlot)
                    .toList();
          // A sub-slot (or whole category) with nothing purchasable yet
          // (e.g. boss_skin's goblin/ogre/orc, mob_skin's flying) gets a
          // "coming soon" note alongside Basic — there's nothing to buy
          // there yet, but Basic still shows what "no skin" looks like.
          final isComingSoon = selectedItems.isEmpty;
          // Basic (no skin equipped) is "equipped" whenever this equip
          // slot has no row in user_equipped_items yet, or an explicit
          // null.
          final equippedId = data.equippedByCategory[equipCategoryKey];
          final basicEquipped =
              !data.equippedByCategory.containsKey(equipCategoryKey) ||
              equippedId == null;

          return Row(
            children: [
              CategoryRail(
                selected: _selectedCategory,
                onSelect: (c) => setState(() => _selectedCategory = c),
                s: s,
                headerIcon: Icons.brush_rounded,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  color: const Color(0xFFCB7B2A),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (subSlots != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShopSubSlotTabs(
                            category: _selectedCategory,
                            slots: subSlots,
                            selected: currentSubSlot!,
                            onSelect: (slot) => setState(
                              () => _selectedSubSlot[_selectedCategory] = slot,
                            ),
                            s: s,
                          ),
                        ),
                      if (isComingSoon)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            s.comingSoon,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // See the identical comment in shop_screen.dart:
                          // a fixed aspect ratio doesn't account for the
                          // text area's fixed dp height, so cards could
                          // overflow into the row below (the Equip button
                          // underneath became untappable). An explicit
                          // mainAxisExtent computed from the real column
                          // width avoids that at any screen size. This
                          // GridView sits inside the outer ListView's own
                          // EdgeInsets.all(16), so constraints.maxWidth here
                          // is already net of that padding.
                          const columns = 2;
                          const crossAxisSpacing = 14.0;
                          const textAreaHeight = 116.0;
                          final columnWidth =
                              (constraints.maxWidth -
                                  crossAxisSpacing * (columns - 1)) /
                              columns;
                          final cardExtent = columnWidth + textAreaHeight;

                          return GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: crossAxisSpacing,
                                  mainAxisExtent: cardExtent,
                                ),
                            children: [
                              _OwnedItemCard(
                                imagePath: _basicImagePathFor(
                                  _selectedCategory,
                                  currentSubSlot,
                                ),
                                name: s.basicItemName,
                                description: s.basicItemDescription,
                                equipped: basicEquipped,
                                busy:
                                    _equippingBasicCategory == equipCategoryKey,
                                equippedLabel: s.equippedLabel,
                                equipLabel: s.equipAction,
                                onTap: () => _equip(equipCategoryKey, null, s),
                              ),
                              for (final item in selectedItems)
                                _OwnedItemCard(
                                  imagePath: shopItemImagePath(item),
                                  name: s.shopItemName(
                                    item['sku']?.toString() ?? '',
                                    item['name']?.toString() ?? '',
                                  ),
                                  description: s.shopItemDescription(
                                    item['sku']?.toString() ?? '',
                                    item['description']?.toString() ?? '',
                                  ),
                                  equipped:
                                      equippedId == (item['id'] as num).toInt(),
                                  busy:
                                      _equippingItemId ==
                                      (item['id'] as num).toInt(),
                                  equippedLabel: s.equippedLabel,
                                  equipLabel: s.equipAction,
                                  onTap: () => _equip(
                                    equipCategoryKey,
                                    (item['id'] as num).toInt(),
                                    s,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileItems {
  const _ProfileItems({required this.items, required this.equippedByCategory});

  final List<Map<String, dynamic>> items;
  final Map<String, int?> equippedByCategory;
}

/// Owned-item card matching the shop's look (gold-bordered square image,
/// name below), so an item looks the same whether you're buying it or
/// equipping it. Border turns green and an "Equipped" badge replaces the
/// Equip button once it's the active item for its category.
class _OwnedItemCard extends StatelessWidget {
  const _OwnedItemCard({
    required this.imagePath,
    required this.name,
    required this.description,
    required this.equipped,
    required this.busy,
    required this.equippedLabel,
    required this.equipLabel,
    required this.onTap,
  });

  final String? imagePath;
  final String name;
  final String description;
  final bool equipped;
  final bool busy;
  final String equippedLabel;
  final String equipLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShopItemImageTile(imagePath: imagePath, highlighted: equipped),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.title(color: Colors.white, fontSize: 13),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (busy)
          const SizedBox(
            height: 34,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Color(0xFFCB7B2A),
                  strokeWidth: 2.2,
                ),
              ),
            ),
          )
        else if (equipped)
          Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3E9B4F).withAlpha(38),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3E9B4F)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF3E9B4F),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  equippedLabel,
                  style: const TextStyle(
                    color: Color(0xFF3E9B4F),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            // Pinned to the same 34px height as the busy/equipped states
            // above (Material's default minimum tap target would otherwise
            // make this taller than the other two, which would make the
            // card's overall height inconsistent depending on its state).
            height: 34,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFCB7B2A),
                side: const BorderSide(color: Color(0xFFCB7B2A)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(equipLabel, style: const TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }
}
