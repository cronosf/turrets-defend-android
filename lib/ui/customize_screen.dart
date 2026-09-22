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

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_ProfileItems> _fetch() async {
    final data = await ApiClient.get('/profile') as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final equipped = (data['equipped'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
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
      await ApiClient.post('/profile/equip', body: {'category': category, 'shop_item_id': itemId});
      await _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
  /// each category, so it's visually obvious what "no skin" looks like —
  /// falls back to the shared generic icon (imagePath null) for
  /// categories without an obvious single default sprite.
  String? _basicImagePathFor(String category) {
    switch (category) {
      case 'turret_skin':
        return 'assets/images/turrets/t1/T1-Shoot_00.png';
      case 'bullet_effect':
        return 'assets/images/projectile/Projectile1.png';
      case 'mob_skin':
        return 'assets/images/enemies/ground/redbeetle/RedBeetle-move_00.png';
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFFCB7B2A)));
          }
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reload,
              color: const Color(0xFFCB7B2A),
              child: ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(s.profileLoadError, style: const TextStyle(color: Colors.redAccent))),
                  const SizedBox(height: 12),
                  Center(child: OutlinedButton(onPressed: _reload, child: Text(s.retry))),
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
          final selectedItems = byCategory[_selectedCategory] ?? [];
          // Categories with no catalog items at all yet (mobs, bosses) get
          // the same "coming soon" note the shop shows, alongside Basic —
          // there's nothing to buy there yet, but Basic still shows what
          // "no skin" looks like for consistency.
          final isComingSoon = _selectedCategory == 'mob_skin' || _selectedCategory == 'boss_skin';
          // Basic (no skin equipped) is "equipped" whenever the category
          // has no row in user_equipped_items yet, or an explicit null.
          final equippedId = data.equippedByCategory[_selectedCategory];
          final basicEquipped = !data.equippedByCategory.containsKey(_selectedCategory) || equippedId == null;

          return Row(
            children: [
              CategoryRail(
                selected: _selectedCategory,
                onSelect: (c) => setState(() => _selectedCategory = c),
                s: s,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  color: const Color(0xFFCB7B2A),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (isComingSoon)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(s.comingSoon, style: const TextStyle(color: Colors.white54)),
                        ),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.66,
                        children: [
                          _OwnedItemCard(
                            imagePath: _basicImagePathFor(_selectedCategory),
                            name: s.basicItemName,
                            description: s.basicItemDescription,
                            equipped: basicEquipped,
                            busy: _equippingBasicCategory == _selectedCategory,
                            equippedLabel: s.equippedLabel,
                            equipLabel: s.equipAction,
                            onTap: () => _equip(_selectedCategory, null, s),
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
                              equipped: equippedId == (item['id'] as num).toInt(),
                              busy: _equippingItemId == (item['id'] as num).toInt(),
                              equippedLabel: s.equippedLabel,
                              equipLabel: s.equipAction,
                              onTap: () => _equip(_selectedCategory, (item['id'] as num).toInt(), s),
                            ),
                        ],
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
            style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.25),
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
                child: CircularProgressIndicator(color: Color(0xFFCB7B2A), strokeWidth: 2.2),
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
                const Icon(Icons.check_circle_rounded, color: Color(0xFF3E9B4F), size: 16),
                const SizedBox(width: 6),
                Text(
                  equippedLabel,
                  style: const TextStyle(color: Color(0xFF3E9B4F), fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFCB7B2A),
                side: const BorderSide(color: Color(0xFFCB7B2A)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(equipLabel, style: const TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }
}
