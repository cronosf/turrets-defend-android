import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/achievements.dart';
import '../models/economy.dart';

/// "Logros": a sticker-album look at the 40 collectible achievement
/// figures earned by defeating bosses (see models/achievements.dart and
/// TurretDefenseGame.onBossKilled). Shown as a two-page spread — 9 figures
/// per page, 18 per spread — with pagination below for the remaining
/// figures (40 total -> 3 spreads: 18/18/4).
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _perPage = 18;
  static const _perHalf = 9;

  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    final totalPages = (kAchievementCount / _perPage).ceil();
    final start = (_page - 1) * _perPage;
    final spread = kAchievements.skip(start).take(_perPage).toList();
    // Padded to a full 9 with nulls on the last (partial) spread, so that
    // page reads as empty slots rather than a short, lopsided grid.
    final left = List<Achievement?>.generate(
        _perHalf, (i) => i < spread.length ? spread[i] : null);
    final right = List<Achievement?>.generate(
        _perHalf, (i) => _perHalf + i < spread.length ? spread[_perHalf + i] : null);

    return AnimatedBuilder(
      animation: widget.economy,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF2A2018),
          appBar: AppBar(
            backgroundColor: const Color(0xFF3A2A1C),
            foregroundColor: Colors.white,
            title: Text(s.achievementsTitle),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    s.achievementsHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: Color(0xFF54402C), width: 2)),
                          ),
                          child: _AlbumPage(entries: left, economy: widget.economy),
                        ),
                      ),
                      Expanded(child: _AlbumPage(entries: right, economy: widget.economy)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Text(
                        s.achievementsPageLabel(_page, totalPages),
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _page > 1 ? () => setState(() => _page--) : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: const Color(0xFFCB7B2A),
                            disabledColor: Colors.white24,
                          ),
                          IconButton(
                            onPressed: _page < totalPages ? () => setState(() => _page++) : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: const Color(0xFFCB7B2A),
                            disabledColor: Colors.white24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlbumPage extends StatelessWidget {
  const _AlbumPage({required this.entries, required this.economy});

  // A null entry is a blank slot — used to pad the last, partial page back
  // up to a full 9-per-side so it keeps the same height/density as every
  // other page instead of looking sparse.
  final List<Achievement?> entries;
  final Economy economy;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final achievement in entries)
          _AchievementSlot(
            achievement: achievement,
            unlocked: achievement != null && economy.unlockedAchievements.contains(achievement.id),
          ),
      ],
    );
  }
}

class _AchievementSlot extends StatelessWidget {
  const _AchievementSlot({required this.achievement, required this.unlocked});

  final Achievement? achievement;
  final bool unlocked;

  static const _gold = Color(0xFFFFC94D);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF241a11),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: unlocked ? _gold : const Color(0xFF54402C), width: 2),
        ),
        child: achievement == null
            ? null
            : unlocked
                ? Image.asset(achievement!.imagePath, fit: BoxFit.contain)
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.35, 0,
                    ]),
                    child: Image.asset(achievement!.imagePath, fit: BoxFit.contain),
                  ),
      ),
    );
  }
}
