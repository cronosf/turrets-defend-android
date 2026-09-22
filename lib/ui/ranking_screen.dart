import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'leaderboard_row.dart';

/// Local player stats (best score, best wave, last run) plus the real
/// global leaderboard fetched from `GET /ranking` (backed by the
/// `v_leaderboard` view in `server/database/seed.sql`).
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<Map<String, dynamic>>> _leaderboard;

  @override
  void initState() {
    super.initState();
    _leaderboard = _fetchLeaderboard();
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboard() async {
    final data = await ApiClient.get('/ranking', query: {'limit': 50});
    final list = (data as Map<String, dynamic>)['leaderboard'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() => _leaderboard = _fetchLeaderboard());
    await _leaderboard;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.economy,
      builder: (context, _) {
        final s = Strings(widget.economy.language);
        final hasPlayed = widget.economy.lastWave > 0 || widget.economy.lastScore > 0;
        return Scaffold(
          backgroundColor: const Color(0xFF2A2018),
          appBar: AppBar(
            backgroundColor: const Color(0xFF3A2A1C),
            foregroundColor: Colors.white,
            title: Text(s.rankingTitle),
          ),
          body: RefreshIndicator(
            onRefresh: _reload,
            color: const Color(0xFFCB7B2A),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StatCard(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amberAccent,
                  label: s.bestScoreLabel,
                  value: '${widget.economy.bestScore}',
                ),
                const SizedBox(height: 14),
                _StatCard(
                  icon: Icons.military_tech_rounded,
                  iconColor: const Color(0xFFCB7B2A),
                  label: s.bestWaveLabel,
                  value: '${widget.economy.bestWave}',
                ),
                const SizedBox(height: 24),
                Text(
                  s.lastRunLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasPlayed ? s.lastRunSummary(widget.economy.lastWave, widget.economy.lastScore) : s.noRunsYet,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (!ApiClient.hasToken) ...[
                  const SizedBox(height: 16),
                  Text(
                    s.notLoggedInHint,
                    style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  s.globalRankingTitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _leaderboard,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFFCB7B2A)),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              s.globalRankingLoadError,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _reload,
                              child: Text(s.retry),
                            ),
                          ],
                        ),
                      );
                    }
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                      return Text(
                        s.noRunsYet,
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      );
                    }
                    return Column(
                      children: [
                        LeaderboardHeader(
                          scoreLabel: s.rankingScoreColumnLabel,
                          waveLabel: s.rankingWaveColumnLabel,
                        ),
                        for (final entry in entries)
                          LeaderboardRow(
                            rank: (entry['rank_position'] as num?)?.toInt() ?? 0,
                            username: entry['username']?.toString() ?? '?',
                            countryCode: entry['country_code']?.toString(),
                            bestScore: (entry['best_score'] as num?)?.toInt() ?? 0,
                            bestWave: (entry['best_wave'] as num?)?.toInt() ?? 0,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCB7B2A), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
