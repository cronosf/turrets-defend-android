import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'paypal_checkout_screen.dart';

/// Real shop backed by `GET /shop/items`, with purchases going through
/// PayPal via `POST /shop/orders` (create) -> [PaypalCheckoutScreen]
/// (approval) -> `POST /shop/orders/{id}/capture` (finalize, which is what
/// actually grants the item server-side).
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
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final itemId = (item['id'] as num).toInt();
                final busy = _purchasing.contains(itemId);
                final price = item['price_amount']?.toString() ?? '0';
                final currency = item['price_currency']?.toString() ?? 'USD';
                return _ShopItemCard(
                  name: item['name']?.toString() ?? '',
                  description: item['description']?.toString() ?? '',
                  busy: busy,
                  buyLabel: s.buyItem(price, currency),
                  onBuy: busy ? null : () => _buy(item, s),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.name,
    required this.description,
    required this.busy,
    required this.buyLabel,
    required this.onBuy,
  });

  final String name;
  final String description;
  final bool busy;
  final String buyLabel;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF54402C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCB7B2A),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : Text(buyLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
