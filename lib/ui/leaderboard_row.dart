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
const double _rankColumnWidth = 32;
const double _countryColumnWidth = 34;
const double _scoreColumnWidth = 58;
const double _bossColumnWidth = 38;
const double _waveColumnWidth = 40;
// Gap between columns, and the row's own side padding — kept tight so a
// full 12-character username (the maximum) fits in the flexible name column.
const double _colGap = 4;
const double _rowSidePadding = 8;

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
    required this.bossLabel,
    this.playerLabel,
    this.countryLabel,
  });

  final String? playerLabel;
  final String scoreLabel;
  final String bossLabel;
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
      padding: const EdgeInsets.only(left: _rowSidePadding, right: _rowSidePadding, bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: _rankColumnWidth),
          Expanded(
            child: Text(playerLabel ?? '', textAlign: TextAlign.left, style: _labelStyle),
          ),
          if (countryLabel != null) ...[
            SizedBox(
              width: _countryColumnWidth,
              child: Text(countryLabel!, textAlign: TextAlign.center, style: _labelStyle),
            ),
            const SizedBox(width: _colGap),
          ],
          SizedBox(
            width: _scoreColumnWidth,
            child: Text(scoreLabel, textAlign: TextAlign.center, style: _labelStyle),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _bossColumnWidth,
            child: Text(bossLabel, textAlign: TextAlign.center, style: _labelStyle),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _waveColumnWidth,
            child: Text(waveLabel, textAlign: TextAlign.center, style: _labelStyle),
          ),
        ],
      ),
    );
  }
}

/// Maps a rank position (1-5) to its trophy asset — 1st is Diamante down to
/// 5th as Bronce, matching the tier order the game's rank badges use
/// elsewhere. `null` for rank 6+ (no trophy, just the "#N" text).
String? _trophyAssetForRank(int rank) {
  switch (rank) {
    case 1:
      return 'assets/images/ranking/trophy_diamante.png';
    case 2:
      return 'assets/images/ranking/trophy_platino.png';
    case 3:
      return 'assets/images/ranking/trophy_oro.png';
    case 4:
      return 'assets/images/ranking/trophy_plata.png';
    case 5:
      return 'assets/images/ranking/trophy_bronce.png';
    default:
      return null;
  }
}

const _vipTrophyAsset = 'assets/images/ranking/trophy_blackvip.png';

/// Score/wave text color per rank tier — 1st yellow, 2nd silver, 3rd
/// orange, 4th/5th (the two remaining "bronce"-tier ranks) a bronze tone.
/// Independent of [_trophyAssetForRank]'s icon colors (which follow the
/// Diamante/Platino/Oro/Plata/Bronce theme instead) — this is specifically
/// what the score/wave numbers use. `null` for rank 6+, same as the
/// trophy itself.
Color? _scoreColorForRank(int rank) {
  switch (rank) {
    case 1:
      return const Color(0xFFFFE066);
    case 2:
      return const Color(0xFFD6D6D6);
    case 3:
      return const Color(0xFFFF9642);
    case 4:
    case 5:
      return const Color(0xFFCD7F32);
    default:
      return null;
  }
}

/// Diagonal light-sweep translation for [_ShimmerTrophy]'s gradient — the
/// same technique as Flutter's own shimmer-loading cookbook recipe: the
/// gradient's colors/stops stay fixed (a narrow bright band inside a
/// transparent field), and only its position is translated per frame, so
/// `TileMode.clamp`'s transparent edges naturally hide the band for most of
/// the cycle instead of it looping back and forth.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Wraps a trophy image with a soft diagonal shine that sweeps across it
/// once every 2 seconds — purely decorative polish for the rank-1..5 and
/// VIP badges.
class _ShimmerTrophy extends StatefulWidget {
  const _ShimmerTrophy({required this.assetPath});

  final String assetPath;

  @override
  State<_ShimmerTrophy> createState() => _ShimmerTrophyState();
}

class _ShimmerTrophyState extends State<_ShimmerTrophy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(widget.assetPath, fit: BoxFit.contain);
    return AnimatedBuilder(
      animation: _controller,
      child: image,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Color(0xCCFFFFFF),
                Colors.transparent,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlidingGradientTransform(
                -1.5 + _controller.value * 3.0,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// A single leaderboard row: a trophy image for ranks 1-5 (Diamante down to
/// Bronce) plus a highlight, then the player's name, country (own column,
/// only when [countryCode] is given — see [LeaderboardHeader]), best score
/// and best wave. [isVip] (a player with $10+ in paid orders) shows the
/// Black VIP trophy instead, regardless of rank — a separate "top spender"
/// badge rather than another rank tier, so it can apply outside the top 5
/// too. Shared by [RankingScreen] (global) and [NationalRankingScreen]
/// (per-country) so both use the same design.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.username,
    required this.bestScore,
    required this.bestWave,
    this.bestBosses = 0,
    this.countryCode,
    this.isVip = false,
  });

  final int rank;
  final String username;
  final int bestScore;
  final int bestWave;
  final int bestBosses;
  final String? countryCode;
  final bool isVip;

  static const _tierHighlight = Color(0xFFCB7B2A);
  static const _vipHighlight = Color(0xFFB98A3A);

  @override
  Widget build(BuildContext context) {
    final trophyAsset = isVip ? _vipTrophyAsset : _trophyAssetForRank(rank);
    final highlightColor = trophyAsset == null
        ? null
        : (isVip ? _vipHighlight : _tierHighlight);
    // Score/wave numbers get their own per-rank color scheme (see
    // _scoreColorForRank) rather than sharing the row's single highlight
    // tone — falls back to that highlight for VIP (no per-rank scheme
    // applies there, it's orthogonal to rank) and to white70 outside the
    // top 5.
    final scoreColor = isVip
        ? highlightColor
        : (_scoreColorForRank(rank) ?? Colors.white70);
    final showCountry = countryCode != null && countryCode!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: _rowSidePadding, vertical: 10),
      decoration: highlightColor != null
          ? BoxDecoration(
              color: highlightColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlightColor.withValues(alpha: 0.55),
                width: 1.5,
              ),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: _rankColumnWidth,
            height: 34,
            child: trophyAsset != null
                ? _ShimmerTrophy(assetPath: trophyAsset)
                : Text(
                    '#$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                username,
                maxLines: 1,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: highlightColor != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
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
            const SizedBox(width: _colGap),
          ],
          SizedBox(
            width: _scoreColumnWidth,
            child: Text(
              '$bestScore',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scoreColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _bossColumnWidth,
            child: Text(
              '$bestBosses',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scoreColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _waveColumnWidth,
            child: Text(
              '$bestWave',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scoreColor,
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
