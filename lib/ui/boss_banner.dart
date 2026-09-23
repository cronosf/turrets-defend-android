import 'package:flutter/material.dart';

import '../game/turret_defense_game.dart';
import '../l10n/app_strings.dart';
import '../theme/app_fonts.dart';

/// Shown briefly (see TurretDefenseGame's _bossBannerTimer) whenever a boss
/// wave starts. IgnorePointer so it never blocks a tap on the game canvas
/// underneath while it's up.
class BossBanner extends StatelessWidget {
  const BossBanner({super.key, required this.game});

  final TurretDefenseGame game;

  @override
  Widget build(BuildContext context) {
    final s = Strings(game.economy.language);
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE05A3A), width: 3),
          ),
          child: Text(
            s.bossFightTitle,
            style: AppFonts.title(color: const Color(0xFFE05A3A), fontSize: 28, letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}
