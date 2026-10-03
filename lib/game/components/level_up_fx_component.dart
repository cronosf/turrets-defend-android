import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, Curves, FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;

/// Merge celebration drawn over the board cell where a turret just levelled
/// up: a golden aura (glow + expanding rings + rising sparks) filling the
/// *cell* — not the turret itself, so the warrior's art stays readable —
/// and a "LVL UP!" speech bubble that floats up off the cell and fades.
/// Self-removes when finished. All procedural except the bubble art, so it
/// costs one small PNG and no per-frame allocations worth worrying about.
class LevelUpFxComponent extends PositionComponent {
  LevelUpFxComponent({
    required Vector2 cellCenter,
    required double cellSize,
    required this.bubble,
    required this.text,
    this.aura = true,
    this.duration = _defaultDuration,
  })  : _cell = cellSize,
        super(position: cellCenter, anchor: Anchor.center, priority: 30, size: Vector2.all(cellSize));

  final Sprite bubble;
  final String text;

  /// false = speech bubble only (no golden aura/rings/sparks).
  final bool aura;
  final double _cell;

  static const double _defaultDuration = 1.3;
  final double duration;
  double _t = 0;

  static const _gold = Color(0xFFFFD34D);
  static const _sparks = 7;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    final center = Offset(_cell / 2, _cell / 2);

    if (aura) {
      // --- Aura over the cell (clipped to it so it reads as "this square").
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: _cell + 6, height: _cell + 6),
        const Radius.circular(10),
      );
      final fade = p < 0.2 ? p / 0.2 : (1 - (p - 0.2) / 0.8);
      canvas.save();
      canvas.clipRRect(rect);
      final glow = Paint()
        ..shader = Gradient.radial(
          center,
          _cell * 0.75,
          [_gold.withValues(alpha: 0.75 * fade), _gold.withValues(alpha: 0.0)],
        );
      canvas.drawRect(rect.outerRect, glow);
      // Two rings expanding outward, staggered.
      for (var i = 0; i < 2; i++) {
        final rp = ((p - i * 0.22) / 0.6).clamp(0.0, 1.0);
        if (rp <= 0 || rp >= 1) continue;
        canvas.drawCircle(
          center,
          _cell * (0.15 + 0.6 * rp),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - rp) + 0.6
            ..color = Colors.white.withValues(alpha: 0.85 * (1 - rp)),
        );
      }
      canvas.restore();
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _gold.withValues(alpha: 0.9 * fade),
      );

      // --- Sparks rising from the cell.
      final sparkPaint = Paint();
      for (var i = 0; i < _sparks; i++) {
        final phase = (p * 1.4 - i * 0.07).clamp(0.0, 1.0);
        if (phase <= 0 || phase >= 1) continue;
        final dx = (i - (_sparks - 1) / 2) * (_cell / _sparks) * 1.1;
        final dy = _cell * 0.4 - phase * _cell * 1.1;
        sparkPaint.color = _gold.withValues(alpha: 1 - phase);
        _drawStar(canvas, Offset(center.dx + dx + math.sin(phase * 6 + i) * 3, center.dy + dy), 3.2 * (1 - phase * 0.4), sparkPaint);
      }
    }

    // --- "LVL UP!" bubble floating up above the cell.
    final rise = Curves.easeOut.transform(p.clamp(0.0, 0.5) / 0.5);
    final bubbleAlpha = p < 0.12 ? p / 0.12 : (p > 0.75 ? (1 - p) / 0.25 : 1.0);
    final bw = _cell * 1.45;
    final bh = bw * 211 / 300;
    final tail = Offset(center.dx + _cell * 0.12, -_cell * 0.05 - 10 * rise);
    final bubbleRect = Rect.fromLTWH(tail.dx - bw * 0.83, tail.dy - bh, bw, bh);
    final opacity = Paint()..color = Color.fromRGBO(255, 255, 255, bubbleAlpha.clamp(0.0, 1.0));
    bubble.render(
      canvas,
      position: Vector2(bubbleRect.left, bubbleRect.top),
      size: Vector2(bw, bh),
      overridePaint: opacity,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF3A1F0A).withValues(alpha: bubbleAlpha.clamp(0.0, 1.0)),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(bubbleRect.center.dx - textPainter.width / 2, bubbleRect.top + bh * 0.36 - textPainter.height / 2),
    );
  }

  static void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * 0.4;
      final a = i * math.pi / 4 - math.pi / 2;
      final pt = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
