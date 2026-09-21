import 'package:flutter/material.dart';

import '../app_version.dart';
import '../l10n/app_strings.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final s = Strings(language);
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A2A1C),
        foregroundColor: Colors.white,
        title: Text(s.help),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/ui/MenuBanner.png', width: 220),
              const SizedBox(height: 20),
              const Text(
                'Merge Turrets: Endless Mode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kAppVersion,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 28),
              Text(
                s.developedBy,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'CRONOSF DEV',
                style: TextStyle(
                  color: Color(0xFFCB7B2A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '© 2026 CRONOSF DEV. ${s.allRightsReserved}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
