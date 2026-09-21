import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'leaderboard_row.dart';

/// Same leaderboard shape as [RankingScreen], but scoped to the player's own
/// country (`GET /ranking?country=XX`), with rank numbers computed within
/// that country rather than the global rank filtered down.
class NationalRankingScreen extends StatefulWidget {
  const NationalRankingScreen({super.key, required this.economy, required this.countryCode});

  final Economy economy;
  final String? countryCode;

  @override
  State<NationalRankingScreen> createState() => _NationalRankingScreenState();
}

class _NationalRankingScreenState extends State<NationalRankingScreen> {
  late Future<List<Map<String, dynamic>>> _leaderboard;

  @override
  void initState() {
    super.initState();
    _leaderboard = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    if (widget.countryCode == null || widget.countryCode!.isEmpty) return [];
    final data = await ApiClient.get('/ranking', query: {'country': widget.countryCode, 'limit': 50});
    final list = (data as Map<String, dynamic>)['leaderboard'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() => _leaderboard = _fetch());
    await _leaderboard;
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A2A1C),
        foregroundColor: Colors.white,
        title: Text(s.nationalRankingTitle),
      ),
      body: (widget.countryCode == null || widget.countryCode!.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.nationalRankingNoCountry,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _reload,
              color: const Color(0xFFCB7B2A),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _leaderboard,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFCB7B2A)));
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(s.globalRankingLoadError, style: const TextStyle(color: Colors.redAccent)),
                        ),
                        const SizedBox(height: 12),
                        Center(child: OutlinedButton(onPressed: _reload, child: Text(s.retry))),
                      ],
                    );
                  }
                  final entries = snapshot.data ?? [];
                  if (entries.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(child: Text(s.noRunsYet, style: const TextStyle(color: Colors.white54))),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return LeaderboardRow(
                        rank: (entry['rank_position'] as num?)?.toInt() ?? 0,
                        username: entry['username']?.toString() ?? '?',
                        bestWave: (entry['best_wave'] as num?)?.toInt() ?? 0,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
