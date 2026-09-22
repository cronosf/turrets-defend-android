import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'leaderboard_row.dart';

class _LeaderboardPage {
  const _LeaderboardPage({required this.entries, required this.totalPages});

  final List<Map<String, dynamic>> entries;
  final int totalPages;
}

/// Same leaderboard shape as [RankingScreen], but scoped to the player's own
/// country (`GET /ranking?country=XX`), with rank_position computed within
/// that country rather than the global rank filtered down.
class NationalRankingScreen extends StatefulWidget {
  const NationalRankingScreen({super.key, required this.economy, required this.countryCode});

  final Economy economy;
  final String? countryCode;

  @override
  State<NationalRankingScreen> createState() => _NationalRankingScreenState();
}

class _NationalRankingScreenState extends State<NationalRankingScreen> {
  late Future<_LeaderboardPage> _leaderboard;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _leaderboard = _fetch();
  }

  Future<_LeaderboardPage> _fetch() async {
    if (widget.countryCode == null || widget.countryCode!.isEmpty) {
      return const _LeaderboardPage(entries: [], totalPages: 1);
    }
    final data = await ApiClient.get(
      '/ranking',
      query: {'country': widget.countryCode, 'page': _page},
    ) as Map<String, dynamic>;
    final list = data['leaderboard'] as List<dynamic>? ?? [];
    return _LeaderboardPage(
      entries: list.cast<Map<String, dynamic>>(),
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<void> _reload() async {
    setState(() => _leaderboard = _fetch());
    await _leaderboard;
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _leaderboard = _fetch();
    });
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
        actions: (widget.countryCode == null || widget.countryCode!.isEmpty)
            ? null
            : [
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: s.retry,
                ),
              ],
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
              child: FutureBuilder<_LeaderboardPage>(
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
                  final result = snapshot.data ?? const _LeaderboardPage(entries: [], totalPages: 1);
                  final entries = result.entries;
                  if (entries.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(child: Text(s.noRunsYet, style: const TextStyle(color: Colors.white54))),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      LeaderboardHeader(
                        scoreLabel: s.rankingScoreColumnLabel,
                        waveLabel: s.rankingWaveColumnLabel,
                      ),
                      for (final entry in entries)
                        LeaderboardRow(
                          rank: (entry['rank_position'] as num?)?.toInt() ?? 0,
                          username: entry['username']?.toString() ?? '?',
                          bestScore: (entry['best_score'] as num?)?.toInt() ?? 0,
                          bestWave: (entry['best_wave'] as num?)?.toInt() ?? 0,
                        ),
                      LeaderboardPagination(
                        page: _page,
                        totalPages: result.totalPages,
                        onChanged: _goToPage,
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
