import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_fonts.dart';
import 'ui/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MergeTurretsApp());
}

class MergeTurretsApp extends StatelessWidget {
  const MergeTurretsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TurretCron',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        // Oswald everywhere by default (body copy — guide, shop
        // descriptions, etc. — most widgets don't set an explicit
        // fontFamily so they inherit this); Russo One specifically for the
        // text-theme roles AppBar titles and button labels pull from, to
        // match the "DEFENSE TURRETS" title font from the logo.
        fontFamily: AppFonts.body,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: AppFonts.display),
          displayMedium: TextStyle(fontFamily: AppFonts.display),
          displaySmall: TextStyle(fontFamily: AppFonts.display),
          headlineLarge: TextStyle(fontFamily: AppFonts.display),
          headlineMedium: TextStyle(fontFamily: AppFonts.display),
          headlineSmall: TextStyle(fontFamily: AppFonts.display),
          titleLarge: TextStyle(fontFamily: AppFonts.display),
          titleMedium: TextStyle(fontFamily: AppFonts.display),
          titleSmall: TextStyle(fontFamily: AppFonts.display),
          labelLarge: TextStyle(fontFamily: AppFonts.display),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
