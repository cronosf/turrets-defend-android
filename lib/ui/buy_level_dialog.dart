import 'package:flutter/material.dart';

import '../game/turret_defense_game.dart';
import '../l10n/app_strings.dart';
import '../models/turret_stats.dart';
import '../theme/app_fonts.dart';

/// "Buy" no longer always buys a flat tier-1 turret at an escalating price —
/// it opens this picker instead, listing every directly-purchasable level
/// (1..[maxDirectBuyLevel]) with its own price (see [levelBuyCost]: level 1
/// costs 20, +100 per level after that). A bottom sheet rather than a
/// centered dialog: anchored to the bottom of the screen, right above the
/// turret board/BottomControls, so the battlefield above stays visible
/// instead of getting covered. Levels are laid out as a 2-row x 5-column
/// grid (all 10 levels fit with no scrolling). Tapping an affordable level
/// buys it straight into the next empty grid slot and closes the sheet.
Future<void> showBuyLevelDialog(BuildContext context, TurretDefenseGame game) {
  final economy = game.economy;
  final s = Strings(economy.language);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF3A2A1C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.buyLevelDialogTitle,
                      style: AppFonts.title(color: Colors.white, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: economy,
                builder: (context, _) {
                  return GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                    children: [
                      for (var level = 1; level <= maxDirectBuyLevel; level++)
                        _LevelTile(
                          level: level,
                          cost: levelBuyCost(level),
                          canAfford: economy.money >= levelBuyCost(level),
                          onTap: () {
                            if (!game.hasEmptySlot) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(s.gridFullMessage)));
                              return;
                            }
                            if (economy.money < levelBuyCost(level)) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(s.notEnoughMoneyMessage)));
                              return;
                            }
                            game.buyTurretAtLevel(level);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.cost,
    required this.canAfford,
    required this.onTap,
  });

  final int level;
  final int cost;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: canAfford ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2018),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF54402C)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  'assets/images/turrets/t$level/T$level-Shoot_00.png',
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                'Lvl $level',
                style: AppFonts.title(color: Colors.white, fontSize: 11),
              ),
              Text(
                '\$$cost',
                style: const TextStyle(color: Color(0xFFCB7B2A), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
