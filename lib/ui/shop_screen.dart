import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import '../theme/app_fonts.dart';
import 'paypal_checkout_screen.dart';

/// Real shop backed by `GET /shop/items`, with purchases going through
/// PayPal via `POST /shop/orders` (create) -> [PaypalCheckoutScreen]
/// (approval) -> `POST /shop/orders/{id}/capture` (finalize, which is what
/// actually grants the item server-side). Items are grouped by category
/// (turret skins, bullet effects, ...) in a 2-column grid; each card is a
/// gold-bordered square image (same gold as the splash logo's badge) with
/// the name, a short description and a Buy button below it.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Future<List<Map<String, dynamic>>> _items;
  final Set<int> _purchasing = {};

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

  /// The shop item's preview image, generated from the base game sprites
  /// (see assets/images/shop/) and referenced by the `asset_key` in the
  /// item's `metadata` JSON. Bundles don't carry their own asset_key (their
  /// metadata just lists what they include), so fall back to the shared
  /// bundle icon.
  String? _imagePathFor(Map<String, dynamic> item) {
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
      body: RefreshIndicator(
        onRefresh: _reload,
        color: const Color(0xFFCB7B2A),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFCB7B2A)));
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(s.shopLoadError, style: const TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(height: 12),
                  Center(child: OutlinedButton(onPressed: _reload, child: Text(s.retry))),
                ],
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(s.shopEmpty, style: const TextStyle(color: Colors.white54))),
                ],
              );
            }

            final byCategory = <String, List<Map<String, dynamic>>>{};
            for (final item in items) {
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
                    childAspectRatio: 0.62,
                    children: [
                      for (final item in entry.value)
                        _ShopItemCard(
                          imagePath: _imagePathFor(item),
                          name: item['name']?.toString() ?? '',
                          description: item['description']?.toString() ?? '',
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
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF241a11),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x55FFC94D), blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: imagePath != null
                ? Image.asset(imagePath!, fit: BoxFit.contain)
                : const Icon(Icons.redeem_rounded, color: _gold, size: 48),
          ),
        ),
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
