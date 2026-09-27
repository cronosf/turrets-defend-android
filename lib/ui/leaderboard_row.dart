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
    this.countryCode,
    this.isVip = false,
  });

  final int rank;
  final String username;
  final int bestScore;
  final int bestWave;
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
    final showCountry = countryCode != null && countryCode!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
          ),
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: highlightColor != null ? FontWeight.bold : FontWeight.normal,
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
                color: highlightColor ?? Colors.white70,
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
                color: highlightColor ?? Colors.white70,
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
