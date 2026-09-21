import 'package:flutter/material.dart';

/// A single leaderboard row: gold/silver/bronze trophy + highlight for
/// ranks 1-3, a plain "#N" for everyone else. Shared by [RankingScreen]
/// (global) and [NationalRankingScreen] (per-country) so both use the same
/// design.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.username,
    required this.bestWave,
    this.countryCode,
  });

  final int rank;
  final String username;
  final int bestWave;
  final String? countryCode;

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  Color? get _trophyColor {
    switch (rank) {
      case 1:
        return _gold;
      case 2:
        return _silver;
      case 3:
        return _bronze;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trophyColor = _trophyColor;
    final label =
        (countryCode != null && countryCode!.isNotEmpty) ? '$username · $countryCode' : username;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: trophyColor != null
          ? BoxDecoration(
              color: trophyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: trophyColor.withValues(alpha: 0.55), width: 1.5),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: trophyColor != null
                ? Icon(Icons.emoji_events_rounded, color: trophyColor, size: 26)
                : Text(
                    '#$rank',
                    style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: trophyColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$bestWave',
            style: TextStyle(
              color: trophyColor ?? Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
