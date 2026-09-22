import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../theme/app_fonts.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({
    super.key,
    required this.economy,
    required this.onBuy,
    required this.onFree,
    required this.onToggleSell,
  });

  final Economy economy;
  final VoidCallback onBuy;
  final VoidCallback onFree;
  final VoidCallback onToggleSell;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: economy,
      builder: (context, _) {
        final adReady = economy.adCooldown <= 0;
        final s = Strings(economy.language);

        return Container(
          color: const Color(0xFF2A2018),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (economy.sellMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      s.sellModeHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: _ControlButton(
                        label: adReady ? s.free : '${economy.adCooldown.ceil()}s',
                        iconAsset: 'assets/images/turrets/t1/T1-Shoot_00.png',
                        enabled: adReady,
                        onTap: onFree,
                        color: adReady ? const Color(0xFF3E9B4F) : const Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _ControlButton(
                        label: s.buyMenu,
                        iconAsset: 'assets/images/ui/MoneyIcon.png',
                        enabled: true,
                        onTap: onBuy,
                        color: const Color(0xFFCB7B2A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ControlButton(
                        label: s.sell,
                        iconData: Icons.delete_rounded,
                        enabled: true,
                        onTap: onToggleSell,
                        color: economy.sellMode
                            ? const Color(0xFFE05A3A)
                            : const Color(0xFF555555),
                      ),
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.color,
    this.iconAsset,
    this.iconData,
  });

  final String label;
  final String? iconAsset;
  final IconData? iconData;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black26, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null)
              Icon(iconData, color: Colors.white, size: 20)
            else if (iconAsset != null)
              Image.asset(iconAsset!, width: 22, height: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.title(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
