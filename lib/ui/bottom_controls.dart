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
                        // A tightly-cropped copy of the t1 turret frame, not
                        // the original — that source file is ~30% blank
                        // padding on every side (it's sized to match the
                        // rest of the turret animation frames), which at
                        // this icon's size left a lot of empty box pushing
                        // the label oddly far right. See
                        // assets/images/ui/FreeTurretIcon.png's own crop.
                        iconAsset: 'assets/images/ui/FreeTurretIcon.png',
                        // "GRATIS" runs noticeably wider than "FREE" — a
                        // smaller icon leaves it enough room to never need
                        // the ellipsis fallback.
                        iconSize: economy.language == AppLanguage.es ? 30 : 38,
                        leftAlign: true,
                        enabled: adReady,
                        onTap: onFree,
                        color: adReady ? const Color(0xFF3E9B4F) : const Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ControlButton(
                        label: s.buyMenu,
                        iconAsset: 'assets/images/ui/MoneyIcon.png',
                        iconSize: 16.5,
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
    this.iconSize = 33,
    this.leftAlign = false,
  });

  final String label;
  final String? iconAsset;
  final IconData? iconData;
  final double iconSize;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  /// Left-aligns the icon+label pair (with a little leading padding)
  /// instead of centering them — for a non-square icon like the FREE
  /// button's turret, centering the icon+text *pair* as a block still
  /// reads as off-balance because the icon's own bounding box is taller
  /// than it is wide; shifting the whole group left tightens that up.
  final bool leftAlign;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black26, width: 2),
        ),
        child: Padding(
          padding: leftAlign ? const EdgeInsets.only(left: 10) : EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: leftAlign
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (iconData != null)
                Icon(iconData, color: Colors.white, size: 20)
              else if (iconAsset != null)
                // Only height is given (not width) so a non-square source
                // (like the FREE button's turret crop) scales at its own
                // aspect ratio instead of being squashed into a square box.
                Image.asset(iconAsset!, height: iconSize),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.title(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
