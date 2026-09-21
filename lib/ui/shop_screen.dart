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
/// (turret skins, bullet effects, ...) in a 2-column grid of square,
/// gold-bordered cards — same gold as the splash logo's badge.
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
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                    children: [
                      for (final item in entry.value)
                        _ShopItemCard(
                          imagePath: _imagePathFor(item),
                          name: item['name']?.toString() ?? '',
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

/// Square item card: gold border like the splash logo's badge, preview
/// image on top, name + price on a translucent strip at the bottom. The
/// whole card is the buy target (there isn't room for a separate button at
/// this size).
class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.imagePath,
    required this.name,
    required this.buyLabel,
    required this.busy,
    required this.onBuy,
  });

  final String? imagePath;
  final String name;
  final String buyLabel;
  final bool busy;
  final VoidCallback? onBuy;

  static const _gold = Color(0xFFFFC94D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF241a11),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x55FFC94D), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 34),
                child: imagePath != null
                    ? Image.asset(imagePath!, fit: BoxFit.contain)
                    : const Icon(Icons.redeem_rounded, color: _gold, size: 48),
              ),
            ),
            if (busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.black.withValues(alpha: 0.68),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.title(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      buyLabel,
                      style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
