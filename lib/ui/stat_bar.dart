import 'package:flutter/material.dart';

/// A labeled fill-bar used for both the wave/enemy progress readout and the
/// base health readout.
class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.ratio, required this.fillColor, required this.label});

  final double ratio;
  final Color fillColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(height: 14, color: const Color(0xFF1A140F)),
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(height: 14, color: fillColor),
          ),
          SizedBox(
            height: 14,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
