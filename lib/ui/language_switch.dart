import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// The ES/EN language switch, shared by [showSettingsDialog] and the login
/// screen so a player can set their language before ever reaching Home, not
/// just from Settings after logging in. [onChanged] should be
/// `economy.setLanguage`, which already persists the choice — this widget
/// just renders the current [value] and forwards taps.
class LanguageSwitchRow extends StatelessWidget {
  const LanguageSwitchRow({super.key, required this.label, required this.value, required this.onChanged});

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
