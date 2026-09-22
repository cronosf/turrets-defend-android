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

  Future<void> _equip(String category, int itemId, Strings s) async {
    setState(() => _equippingItemId = itemId);
    try {
      await ApiClient.post('/profile/equip', body: {'category': category, 'shop_item_id': itemId});
      await _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _equippingItemId = null);
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
      body: RefreshIndicator(
        onRefresh: _reload,
        color: const Color(0xFFCB7B2A),
        child: FutureBuilder<_ProfileItems>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFCB7B2A)));
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(s.profileLoadError, style: const TextStyle(color: Colors.redAccent))),
                  const SizedBox(height: 12),
                  Center(child: OutlinedButton(onPressed: _reload, child: Text(s.retry))),
                ],
              );
            }

            final data = snapshot.data!;
            if (data.items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(s.noItemsOwnedYet, style: const TextStyle(color: Colors.white54))),
                ],
              );
            }

            final byCategory = <String, List<Map<String, dynamic>>>{};
            for (final item in data.items) {
              final category = item['category']?.toString() ?? '';
              byCategory.putIfAbsent(category, () => []).add(item);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in byCategory.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 6),
                    child: Text(
                      s.categoryLabel(entry.key).toUpperCase(),
                      style: AppFonts.title(color: const Color(0xFFCB7B2A), fontSize: 15, letterSpacing: 1),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                    children: [
                      for (final item in entry.value)
                        _OwnedItemCard(
                          imagePath: shopItemImagePath(item),
                          name: s.shopItemName(
                            item['sku']?.toString() ?? '',
                            item['name']?.toString() ?? '',
                          ),
                          equipped: data.equippedByCategory[entry.key] == (item['id'] as num).toInt(),
                          busy: _equippingItemId == (item['id'] as num).toInt(),
                          equippedLabel: s.equippedLabel,
                          equipLabel: s.equipAction,
                          onTap: () => _equip(entry.key, (item['id'] as num).toInt(), s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            );
          },
        ),
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
    required this.equipped,
    required this.busy,
    required this.equippedLabel,
    required this.equipLabel,
    required this.onTap,
  });

  final String? imagePath;
  final String name;
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
