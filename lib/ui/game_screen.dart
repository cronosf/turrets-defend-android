import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/turret_defense_game.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'base_health_bar.dart';
import 'bottom_controls.dart';
import 'lose_overlay.dart';
import 'settings_overlay.dart';
import 'top_hud.dart';

/// The actual gameplay screen. Entered only from [HomeScreen]'s tap-to-play,
/// so the run starts immediately once the Flame game finishes loading —
/// there's no in-canvas menu overlay any more, Home is that screen now.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TurretDefenseGame _game;
  bool _wasGameOver = false;

  @override
  void initState() {
    super.initState();
    _game = TurretDefenseGame(economy: widget.economy);
    widget.economy.addListener(_onEconomyChanged);
  }

  @override
  void dispose() {
    widget.economy.removeListener(_onEconomyChanged);
    super.dispose();
  }

  /// Syncs the run's result to the server (best_wave feeds the global
  /// ranking) the moment the base goes down. Only meaningful when logged
  /// in; silently skipped/ignored otherwise since this is a background
  /// sync, not something the player needs to see fail.
  void _onEconomyChanged() {
    final isOver = widget.economy.gameOver;
    if (isOver && !_wasGameOver && ApiClient.hasToken) {
      ApiClient.post('/stats/run', body: {'wave': widget.economy.wave}).catchError((_) {});
    }
    _wasGameOver = isOver;
  }

  Future<void> _openSettings() async {
    _game.pauseEngine();
    await showSettingsDialog(context, widget.economy);
    _game.resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      body: Column(
        children: [
          TopHud(economy: widget.economy, onSettingsTap: _openSettings),
          Expanded(
            child: GameWidget<TurretDefenseGame>(
              game: _game,
              overlayBuilderMap: {
                'lose': (context, game) => LoseOverlay(game: game),
              },
            ),
          ),
          BaseHealthBar(economy: widget.economy),
          BottomControls(
            economy: widget.economy,
            onBuy: _game.buyTurret,
            onFree: _game.claimFreeTurret,
            onToggleSell: widget.economy.toggleSellMode,
          ),
        ],
      ),
    );
  }
}
