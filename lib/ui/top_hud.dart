import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../theme/app_fonts.dart';
import 'stat_bar.dart';

class TopHud extends StatelessWidget {
  const TopHud({super.key, required this.economy, required this.onSettingsTap});

  final Economy economy;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: economy,
      builder: (context, _) {
        final waveRatio = economy.waveEnemiesTotal == 0
            ? 0.0
            : (economy.waveEnemiesResolved / economy.waveEnemiesTotal).clamp(0.0, 1.0);
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
                      s.level(economy.wave),
                      style: AppFonts.title(color: Colors.amberAccent, fontSize: 16),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onSettingsTap,
                      child: Image.asset('assets/images/ui/SettingIcon.png', width: 30, height: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StatBar(
                  ratio: waveRatio,
                  fillColor: const Color(0xFFE08A2E),
                  label: s.enemiesLabel(economy.waveEnemiesResolved, economy.waveEnemiesTotal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
