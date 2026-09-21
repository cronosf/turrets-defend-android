import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../game/turret_defense_game.dart';
import '../l10n/app_strings.dart';
import '../theme/app_fonts.dart';

class LoseOverlay extends StatelessWidget {
  const LoseOverlay({super.key, required this.game});

  final TurretDefenseGame game;

  void _retry() {
    game.overlays.remove('lose');
    game.startRun();
  }

  /// Pops GameScreen, returning to whatever pushed it — always Home (see
  /// HomeScreen._play), never Login.
  void _goHome(BuildContext context) {
    game.overlays.remove('lose');
    GameAudio.instance.playMenuMusic();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final economy = game.economy;
    final s = Strings(economy.language);
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF3A2A1C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCB7B2A), width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.baseDestroyed,
              style: AppFonts.title(color: Colors.redAccent, fontSize: 24, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),
            Text(
              s.waveReached(economy.wave),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              s.bestWave(economy.bestWave),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _retry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E9B4F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.playAgain,
                  style: AppFonts.title(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _goHome(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82C4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.backToHome,
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
