import 'package:flutter/material.dart';

/// A Google-style circular avatar showing initials on a color derived from
/// [seed] (so the same user always gets the same color). Prefers initials
/// from [fullName] (first letter of the first and last word, e.g. "Juan
/// Pérez" -> "JP"); falls back to the first letter of [username] when no
/// full name is set.
class AvatarInitials extends StatelessWidget {
  const AvatarInitials({
    super.key,
    required this.username,
    this.fullName,
    this.radius = 36,
  });

  final String username;
  final String? fullName;
  final double radius;

  static const _palette = [
    Color(0xFFE57373),
    Color(0xFFF06292),
    Color(0xFFBA68C8),
    Color(0xFF9575CD),
    Color(0xFF7986CB),
    Color(0xFF64B5F6),
    Color(0xFF4DB6AC),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFA1887F),
  ];

  String get _initials {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return (parts.first[0] + parts.last[0]).toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  Color get _color {
    final seed = (fullName?.isNotEmpty ?? false) ? fullName! : username;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
