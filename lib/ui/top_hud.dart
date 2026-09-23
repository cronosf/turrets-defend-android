import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../theme/app_fonts.dart';

/// A generic enemy icon for the wave counter — doesn't need to match the
/// specific mob type spawning, same idea as the turret sprite used for the
/// Free button.
const _enemyIconAsset = 'assets/images/enemies/ground/redbeetle/RedBeetle-move_00.png';

class TopHud extends StatelessWidget {
  const TopHud({super.key, required this.economy, required this.onSettingsTap});

  final Economy economy;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: economy,
      builder: (context, _) {
        final s = Strings(economy.language);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/ui/MoneyIcon.png', width: 28, height: 28),
                    const SizedBox(width: 6),
                    Text(
                      economy.money.floor().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 22),
                    const SizedBox(width: 2),
                    Text(
                      economy.score.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      economy.isBossWave ? s.bossLevelLabel : s.level(economy.wave),
                      style: AppFonts.title(
                        color: economy.isBossWave ? const Color(0xFFE05A3A) : Colors.amberAccent,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onSettingsTap,
                      child: Image.asset('assets/images/ui/SettingIcon.png', width: 30, height: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Image.asset(_enemyIconAsset, width: 24, height: 24),
                    const SizedBox(width: 6),
                    Text(
                      '${economy.waveEnemiesResolved}/${economy.waveEnemiesTotal}',
                      style: AppFonts.title(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
