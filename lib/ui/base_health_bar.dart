import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import 'stat_bar.dart';

/// Sits between the battlefield/turret grid and the bottom action buttons,
/// separate from the top HUD, so the base health readout lives visually
/// right below the turrets defending it.
class BaseHealthBar extends StatelessWidget {
  const BaseHealthBar({super.key, required this.economy});

  final Economy economy;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: economy,
      builder: (context, _) {
        final hpRatio = (economy.baseHp / Economy.maxBaseHp).clamp(0.0, 1.0);
        final s = Strings(economy.language);
        return Container(
          color: const Color(0xFF2A2018),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: StatBar(
            ratio: hpRatio,
            fillColor: hpRatio > 0.3 ? Colors.greenAccent : Colors.redAccent,
            label: s.baseLabel(economy.baseHp.ceil(), Economy.maxBaseHp.toInt()),
          ),
        );
      },
    );
  }
}
