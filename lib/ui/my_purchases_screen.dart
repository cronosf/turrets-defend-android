import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';

/// Simple billing-style list of the user's orders (item, price, date,
/// status) — not a full invoice/receipt, just enough to see what was bought
/// and whether it went through.
class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  late Future<List<Map<String, dynamic>>> _purchases;

  @override
  void initState() {
    super.initState();
    _purchases = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await ApiClient.get('/profile/purchases') as Map<String, dynamic>;
    final list = data['purchases'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() => _purchases = _fetch());
    await _purchases;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF3E9B4F);
      case 'pending':
        return Colors.amberAccent;
      default:
        return Colors.redAccent;
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
        title: Text(s.myPurchasesTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        color: const Color(0xFFCB7B2A),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _purchases,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFCB7B2A)));
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(s.purchasesLoadError, style: const TextStyle(color: Colors.redAccent))),
                  const SizedBox(height: 12),
                  Center(child: OutlinedButton(onPressed: _reload, child: Text(s.retry))),
                ],
              );
            }
            final purchases = snapshot.data ?? [];
            if (purchases.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(s.noPurchasesYet, style: const TextStyle(color: Colors.white54))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: purchases.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final p = purchases[index];
                final status = p['status']?.toString() ?? '';
                final createdAt = p['created_at']?.toString() ?? '';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  title: Text(
                    p['item_name']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  subtitle: Text(
                    createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p['total_currency'] ?? ''} ${p['total_amount'] ?? ''}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.purchaseStatusLabel(status),
                        style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
