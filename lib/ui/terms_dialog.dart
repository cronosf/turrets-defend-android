import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

Future<void> showTermsDialog(BuildContext context, AppLanguage language) {
  final s = Strings(language);
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF3A2A1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFCB7B2A), width: 3),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.termsTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    s.termsBody,
                    style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.45),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
    ),
  );
}
