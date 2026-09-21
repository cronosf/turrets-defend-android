import 'package:flutter/material.dart';

/// The two display fonts used throughout the app, matching the game's own
/// logo (assets/logo/logo_turret.png): the chunky "DEFENSE TURRETS"
/// wordmark is Russo One, the "ENDLESS MODE" banner is Oswald Bold.
///
/// [ThemeData] in main.dart sets Oswald as the app-wide default (covers
/// body copy — guide text, shop descriptions, etc. — for free, since most
/// widgets style their `Text` without an explicit fontFamily and inherit
/// the ambient default) and points its title/label text-theme roles at
/// Russo One, which is what `AppBar` titles and button labels use by
/// default. [title] below is for the standalone "title-ish" text that
/// bypasses those theme roles entirely (custom-styled headings, HUD
/// labels, footer nav items) and needs Russo One applied explicitly.
class AppFonts {
  AppFonts._();

  static const String display = 'RussoOne';
  static const String body = 'Oswald';

  /// A title-style [TextStyle]: Russo One, uppercase-friendly (the font
  /// itself is caps-only in spirit — pair with `.toUpperCase()` on the
  /// string for menu/button labels).
  static TextStyle title({
    required Color color,
    double fontSize = 16,
    double? letterSpacing,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: display,
      color: color,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
    );
  }
}
