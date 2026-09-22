import 'package:flutter/material.dart';

import '../models/economy.dart';

/// Sits between the battlefield/turret grid and the bottom action buttons,
/// separate from the top HUD, so the base health readout lives visually
/// right below the turrets defending it.
///
/// Color shifts green -> amber -> red as HP drops (more readable at a
/// glance than a flat green/red split), and shakes + flashes red whenever
/// the base actually takes damage (an enemy reaching the base was
/// otherwise a silent, easy-to-miss event on this bar).
class BaseHealthBar extends StatefulWidget {
  const BaseHealthBar({super.key, required this.economy});

  final Economy economy;

  @override
  State<BaseHealthBar> createState() => _BaseHealthBarState();
}

class _BaseHealthBarState extends State<BaseHealthBar> with SingleTickerProviderStateMixin {
  late final AnimationController _hitController;
  late final Animation<double> _shake;
  late final Animation<double> _flash;
  double _lastHp = Economy.maxBaseHp;

  @override
  void initState() {
    super.initState();
    _hitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -9.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _hitController, curve: Curves.easeOut));
    _flash = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _hitController, curve: const Interval(0, 0.75, curve: Curves.easeOut)),
    );
    _lastHp = widget.economy.baseHp;
    widget.economy.addListener(_onEconomyChanged);
  }

  void _onEconomyChanged() {
    final hp = widget.economy.baseHp;
    if (hp < _lastHp) {
      _hitController.forward(from: 0);
    }
    _lastHp = hp;
  }

  @override
  void dispose() {
    widget.economy.removeListener(_onEconomyChanged);
    _hitController.dispose();
    super.dispose();
  }

  Color _barColor(double ratio) {
    if (ratio > 0.5) return const Color(0xFF4CD964);
    if (ratio > 0.25) return const Color(0xFFFFB74D);
    return const Color(0xFFE05A3A);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.economy, _hitController]),
      builder: (context, _) {
        final economy = widget.economy;
        final hpRatio = (economy.baseHp / Economy.maxBaseHp).clamp(0.0, 1.0);
        final barColor = _barColor(hpRatio);

        return Container(
          color: const Color(0xFF2A2018),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Transform.translate(
            offset: Offset(_shake.value, 0),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFFCB7B2A), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A140F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black45, width: 1.2),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: hpRatio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [barColor.withValues(alpha: 0.8), barColor],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                '${economy.baseHp.ceil()}/${Economy.maxBaseHp.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_flash.value > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.redAccent.withValues(alpha: _flash.value),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
