import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      title: 'TuerretCro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
