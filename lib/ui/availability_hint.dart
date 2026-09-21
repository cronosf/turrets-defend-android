import 'package:flutter/material.dart';

/// Small inline status line under a username/email field: "Checking…",
/// "Available" (green) or "Already taken" (red), or a neutral fallback hint
/// when nothing has been checked yet. Shared by the register form and the
/// Google sign-up username modal, which both do the same debounced
/// `GET /auth/availability` check.
class AvailabilityHint extends StatelessWidget {
  const AvailabilityHint({
    super.key,
    required this.checking,
    required this.available,
    required this.checkingLabel,
    required this.availableLabel,
    required this.takenLabel,
    this.idleLabel,
  });

  final bool checking;
  final bool? available;
  final String checkingLabel;
  final String availableLabel;
  final String takenLabel;
  final String? idleLabel;

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return Text(checkingLabel, style: const TextStyle(color: Colors.white38, fontSize: 12));
    }
    if (available == true) {
      return Text(availableLabel, style: const TextStyle(color: Color(0xFF3E9B4F), fontSize: 12));
    }
    if (available == false) {
      return Text(takenLabel, style: const TextStyle(color: Colors.redAccent, fontSize: 12));
    }
    if (idleLabel == null) return const SizedBox.shrink();
    return Text(idleLabel!, style: const TextStyle(color: Colors.white38, fontSize: 12));
  }
}
