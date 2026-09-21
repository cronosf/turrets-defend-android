import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import 'guide_screen.dart';
import 'help_screen.dart';

Future<void> showSettingsDialog(BuildContext context, Economy economy) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => AnimatedBuilder(
      animation: economy,
      builder: (context, _) {
        final s = Strings(economy.language);
        return Dialog(
          backgroundColor: const Color(0xFF3A2A1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFCB7B2A), width: 3),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.settingsTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _LanguageRow(
                            label: s.language,
                            value: economy.language,
                            onChanged: economy.setLanguage,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Divider(color: Colors.white24, height: 1),
                          ),
                          _SettingRow(
                            label: s.music,
                            value: economy.musicOn,
                            onChanged: economy.setMusicOn,
                          ),
                          _VolumeSlider(
                            enabled: economy.musicOn,
                            value: economy.musicVolume,
                            onChanged: economy.setMusicVolume,
                          ),
                          _SettingRow(
                            label: s.sound,
                            value: economy.soundOn,
                            onChanged: economy.setSoundOn,
                          ),
                          _VolumeSlider(
                            enabled: economy.soundOn,
                            value: economy.soundVolume,
                            onChanged: economy.setSoundVolume,
                          ),
                          _SettingRow(
                            label: s.vibration,
                            value: economy.vibrationOn,
                            onChanged: economy.setVibrationOn,
                          ),
                          _SettingRow(
                            label: s.tips,
                            value: economy.tipsOn,
                            onChanged: economy.setTipsOn,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.white24, height: 1),
                          ),
                          _NavRow(
                            label: s.guide,
                            icon: Icons.menu_book_rounded,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GuideScreen(language: economy.language),
                                ),
                              );
                            },
                          ),
                          _NavRow(
                            label: s.help,
                            icon: Icons.help_outline_rounded,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => HelpScreen(language: economy.language),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCB7B2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s.close,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF3E9B4F),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          _LangChip(
            label: 'ES',
            selected: value == AppLanguage.es,
            onTap: () => onChanged(AppLanguage.es),
          ),
          const SizedBox(width: 8),
          _LangChip(
            label: 'EN',
            selected: value == AppLanguage.en,
            onTap: () => onChanged(AppLanguage.en),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3E9B4F) : const Color(0xFF555555),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({required this.enabled, required this.value, required this.onChanged});

  final bool enabled;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Row(
        children: [
          const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 18),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF3E9B4F),
                inactiveTrackColor: Colors.white24,
                thumbColor: const Color(0xFFCB7B2A),
                overlayColor: const Color(0x333E9B4F),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 10,
                divisions: 10,
                label: value.round().toString(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              value.round().toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFCB7B2A), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
