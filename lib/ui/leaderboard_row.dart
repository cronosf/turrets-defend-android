import 'package:flutter/material.dart';

/// Prev/next pager shown below a leaderboard page (top 15 per page).
/// Arrows disable themselves at the first/last page instead of hiding, so
/// the control's position doesn't jump around as you page through.
class LeaderboardPagination extends StatelessWidget {
  const LeaderboardPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? () => onChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFFCB7B2A),
            disabledColor: Colors.white24,
          ),
          Text(
            '$page / $totalPages',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: page < totalPages ? () => onChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFFCB7B2A),
            disabledColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}

/// Column widths shared by [LeaderboardHeader] and [LeaderboardRow] so the
/// header labels line up exactly over their values.
const double _rankColumnWidth = 36;
const double _countryColumnWidth = 40;
const double _scoreColumnWidth = 64;
const double _waveColumnWidth = 48;

/// Header labels shown once above the leaderboard list, aligned over
/// [LeaderboardRow]'s columns. [countryLabel] is only passed by the global
/// ranking (every row there can be a different country) — the national
/// ranking omits it since every row is already the same country shown in
/// that screen's own title.
class LeaderboardHeader extends StatelessWidget {
  const LeaderboardHeader({
    super.key,
    required this.scoreLabel,
    required this.waveLabel,
    this.countryLabel,
  });

  final String scoreLabel;
  final String waveLabel;
  final String? countryLabel;

  static const _labelStyle = TextStyle(
    color: Colors.white38,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: _rankColumnWidth),
          const Expanded(child: SizedBox.shrink()),
          if (countryLabel != null) ...[
            SizedBox(
              width: _countryColumnWidth,
              child: Text(countryLabel!, textAlign: TextAlign.center, style: _labelStyle),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: _scoreColumnWidth,
            child: Text(scoreLabel, textAlign: TextAlign.right, style: _labelStyle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: _waveColumnWidth,
            child: Text(waveLabel, textAlign: TextAlign.right, style: _labelStyle),
          ),
        ],
      ),
    );
  }
}

/// A single leaderboard row: gold/silver/bronze trophy + highlight for
/// ranks 1-3, then the player's name, country (own column, only when
/// [countryCode] is given — see [LeaderboardHeader]), best score and best
/// wave. Shared by [RankingScreen] (global) and [NationalRankingScreen]
/// (per-country) so both use the same design.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.username,
    required this.bestScore,
    required this.bestWave,
    this.countryCode,
  });

  final int rank;
  final String username;
  final int bestScore;
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
    final showCountry = countryCode != null && countryCode!.isNotEmpty;

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
            width: _rankColumnWidth,
            child: trophyColor != null
                ? Icon(Icons.emoji_events_rounded, color: trophyColor, size: 26)
                : Text(
                    '#$rank',
                    style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
          ),
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: trophyColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showCountry) ...[
            SizedBox(
              width: _countryColumnWidth,
              child: Text(
                countryCode!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: _scoreColumnWidth,
            child: Text(
              '$bestScore',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: trophyColor ?? Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: _waveColumnWidth,
            child: Text(
              '$bestWave',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: trophyColor ?? Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
