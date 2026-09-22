import 'package:flutter/material.dart';

import '../game/turret_defense_game.dart';
import '../l10n/app_strings.dart';
import '../models/turret_stats.dart';
import '../theme/app_fonts.dart';

/// "Buy" no longer always buys a flat tier-1 turret at an escalating price —
/// it opens this picker instead, listing every directly-purchasable level
/// (1..[maxDirectBuyLevel]) with its own price (see [levelBuyCost]: level 1
/// costs 20, +100 per level after that). Tapping an affordable level buys it
/// straight into the next empty grid slot and closes the dialog.
Future<void> showBuyLevelDialog(BuildContext context, TurretDefenseGame game) {
  final economy = game.economy;
  final s = Strings(economy.language);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF3A2A1C),
        title: Text(s.buyLevelDialogTitle, style: AppFonts.title(color: Colors.white, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: AnimatedBuilder(
            animation: economy,
            builder: (context, _) {
              return ListView.separated(
                shrinkWrap: true,
                itemCount: maxDirectBuyLevel,
                separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final cost = levelBuyCost(level);
                  final canAfford = economy.money >= cost;
                  return ListTile(
                    leading: Image.asset(
                      'assets/images/turrets/t$level/T$level-Shoot_00.png',
                      width: 40,
                      height: 40,
                    ),
                    title: Text(
                      s.buyLevelOption(level, cost),
                      style: AppFonts.title(color: canAfford ? Colors.white : Colors.white38, fontSize: 14),
                    ),
                    onTap: () {
                      if (!game.hasEmptySlot) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(s.gridFullMessage)));
                        return;
                      }
                      if (!canAfford) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(s.notEnoughMoneyMessage)));
                        return;
                      }
                      game.buyTurretAtLevel(level);
                      Navigator.of(dialogContext).pop();
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.close, style: const TextStyle(color: Colors.white54)),
          ),
        ],
      );
    },
  );
}
