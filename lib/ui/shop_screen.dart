import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import '../theme/app_fonts.dart';
import 'paypal_checkout_screen.dart';
import 'shop_item_card.dart';

/// Real shop backed by `GET /shop/items`, with purchases going through
/// PayPal via `POST /shop/orders` (create) -> [PaypalCheckoutScreen]
/// (approval) -> `POST /shop/orders/{id}/capture` (finalize, which is what
/// actually grants the item server-side). A left-side "Categories" rail
/// picks which category's items show on the right, one category at a
/// time, instead of one long scrolling list of every section — categories
/// with no catalog items yet (mobs, bosses) show a "coming soon" message.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const categoryOrder = ['turret_skin', 'bullet_effect', 'mob_skin', 'boss_skin', 'bundle'];

  late Future<List<Map<String, dynamic>>> _items;
  final Set<int> _purchasing = {};
  String _selectedCategory = categoryOrder.first;

  @override
  void initState() {
    super.initState();
    _items = _fetchItems();
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    final data = await ApiClient.get('/shop/items') as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() => _items = _fetchItems());
    await _items;
  }

  Future<void> _buy(Map<String, dynamic> item, Strings s) async {
    if (!ApiClient.hasToken) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.shopLoginRequired)));
      return;
    }
    final itemId = (item['id'] as num).toInt();
    setState(() => _purchasing.add(itemId));
    try {
      final order = await ApiClient.post('/shop/orders', body: {'sku': item['sku']}) as Map<String, dynamic>;
      final approveUrl = order['approve_url'] as String?;
      final orderId = order['order_id'];
      if (approveUrl == null || orderId == null) {
        throw ApiException(s.purchaseError, 0);
      }

      if (!mounted) return;
      final approved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => PaypalCheckoutScreen(approveUrl: approveUrl)),
      );
      if (approved != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.purchaseCancelled)));
        }
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.purchaseApproving)));
      await ApiClient.post('/shop/orders/$orderId/capture');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.purchaseSuccess)));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _purchasing.remove(itemId));
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
        title: Text(s.shopTitle),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _items,
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
                  Center(
                    child: Text(s.shopLoadError, style: const TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(height: 12),
                  Center(child: OutlinedButton(onPressed: _reload, child: Text(s.retry))),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          final byCategory = <String, List<Map<String, dynamic>>>{};
          for (final item in items) {
            final category = item['category']?.toString() ?? '';
            byCategory.putIfAbsent(category, () => []).add(item);
          }
          final selectedItems = byCategory[_selectedCategory] ?? [];

          return Row(
            children: [
              _CategoryRail(
                selected: _selectedCategory,
                onSelect: (c) => setState(() => _selectedCategory = c),
                s: s,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  color: const Color(0xFFCB7B2A),
                  child: selectedItems.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(s.comingSoon, style: const TextStyle(color: Colors.white54)),
                            ),
                          ],
                        )
                      : GridView.count(
                          padding: const EdgeInsets.all(16),
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.68,
                          children: [
                            for (final item in selectedItems)
                              _ShopItemCard(
                                imagePath: shopItemImagePath(item),
                                name: s.shopItemName(
                                  item['sku']?.toString() ?? '',
                                  item['name']?.toString() ?? '',
                                ),
                                description: s.shopItemDescription(
                                  item['sku']?.toString() ?? '',
                                  item['description']?.toString() ?? '',
                                ),
                                buyLabel: s.buyItem(
                                  item['price_amount']?.toString() ?? '0',
                                  item['price_currency']?.toString() ?? 'USD',
                                ),
                                busy: _purchasing.contains((item['id'] as num).toInt()),
                                onBuy: _purchasing.contains((item['id'] as num).toInt())
                                    ? null
                                    : () => _buy(item, s),
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

/// Left-side "Categories" navigation: one entry per catalog category,
/// always shown (even for categories with no items yet) so mobs/bosses
/// are visible with their "coming soon" state instead of just missing.
class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.selected, required this.onSelect, required this.s});

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
          for (final category in _ShopScreenState.categoryOrder)
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

/// Item card matching the app icon's badge look: the gold border frames
/// *only* the preview image (turret/bullet/effect sprite), nothing else —
/// name, description and the Buy button (with its price) sit below it as
/// their own separate elements, not overlaid on the image.
class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.imagePath,
    required this.name,
    required this.description,
    required this.buyLabel,
    required this.busy,
    required this.onBuy,
  });

  final String? imagePath;
  final String name;
  final String description;
  final String buyLabel;
  final bool busy;
  final VoidCallback? onBuy;

  static const _gold = Color(0xFFFFC94D);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShopItemImageTile(imagePath: imagePath),
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF241a11),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Color(0xFF241a11), strokeWidth: 2),
                  )
                : Text(buyLabel, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
