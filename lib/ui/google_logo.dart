import 'package:flutter/material.dart';

/// Lightweight stand-in for the Google "G" mark: a gradient across Google's
/// brand colors rather than a pixel-exact reproduction of the trademarked
/// logo. Once real `google_sign_in` is wired up, swap this for Google's
/// official button asset per their brand guidelines.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853)],
      ).createShader(bounds),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
