import 'package:flutter/material.dart';

import '../game/turret_defense_game.dart';
import '../l10n/app_strings.dart';
import '../models/achievements.dart';
import '../theme/app_fonts.dart';

/// Shown when the player kills a boss (see TurretDefenseGame.onBossKilled).
/// The engine stays paused and the wave doesn't advance until "Continuar"
/// is tapped — closing/backgrounding the app while this is up just leaves
/// the run paused right here, nothing is lost.
class BossDefeatedOverlay extends StatelessWidget {
  const BossDefeatedOverlay({super.key, required this.game});

  final TurretDefenseGame game;

  static const _gold = Color(0xFFFFC94D);

  void _continue() {
    game.continueAfterBossDefeat();
  }

  @override
  Widget build(BuildContext context) {
    final economy = game.economy;
    final s = Strings(economy.language);
    final achievement = game.pendingAchievement ?? kAchievements.first;

    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF3A2A1C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.bossDefeatedTitle,
              style: AppFonts.title(color: const Color(0xFF3E9B4F), fontSize: 24, letterSpacing: 1.1),
            ),
            const SizedBox(height: 18),
            // Tight padding between the border and the figure itself —
            // explicitly not the airy gold-border look used elsewhere.
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF241a11),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x55FFC94D), blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Image.asset(achievement.imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Text(
              game.pendingAchievementIsRepeat ? s.achievementRepeatLabel : s.achievementUnlockedLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              s.achievementName(achievement.id),
              style: AppFonts.title(color: _gold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _continue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E9B4F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.bossContinueLabel,
                  style: AppFonts.title(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
