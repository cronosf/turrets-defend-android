import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../game/turret_defense_game.dart';
import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'base_health_bar.dart';
import 'boss_banner.dart';
import 'boss_defeated_overlay.dart';
import 'bottom_controls.dart';
import 'buy_level_dialog.dart';
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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final TurretDefenseGame _game;
  bool _wasGameOver = false;

  // PopScope's canPop has to actually be true for a follow-up
  // Navigator.pop() (after the player confirms leaving) to go through —
  // left false, that same pop attempt would just re-trigger
  // onPopInvokedWithResult again instead of leaving. Flipped to true only
  // in the instant before that follow-up pop.
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _game = TurretDefenseGame(economy: widget.economy);
    widget.economy.addListener(_onEconomyChanged);
    WidgetsBinding.instance.addObserver(this);
    // Enemies keep coming even if the player isn't tapping anything — if
    // the screen locks mid-run (no touches for a while), the base takes
    // damage the whole time it's off and the run is lost with nobody
    // watching. Keep the screen awake for as long as this screen is open,
    // and let it sleep normally everywhere else in the app.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    widget.economy.removeListener(_onEconomyChanged);
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  /// Android can (and, on a memory-heavy Flame game, sometimes does) kill
  /// the whole app process while it's backgrounded — the user switches to
  /// a call/WhatsApp/Facebook and, on return, the run is just gone,
  /// dumped back on Home with no warning. There's no cheap way to survive
  /// that and resume the exact board (turret placement, live enemies, boss
  /// state, ...) — that would need a full save/restore system this pass
  /// doesn't build. What this can and does do: the instant the app is
  /// backgrounded (the last safe moment before a possible kill),
  /// checkpoint this run's progress exactly like reaching game over would
  /// — so even in the worst case, the wave/score already reached still
  /// counts for bestWave/bestScore and the leaderboard instead of
  /// vanishing along with the board.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (!widget.economy.gameOver) {
        widget.economy.checkpointProgress();
        _syncRunStats();
      }
    }
  }

  /// Syncs the run's current wave/score to the server (best_wave/best_score
  /// feed the global ranking). Only meaningful when logged in; silently
  /// skipped/ignored otherwise since this is a background sync, not
  /// something the player needs to see fail.
  void _syncRunStats() {
    if (!ApiClient.hasToken) return;
    ApiClient.post('/stats/run', body: {
      'wave': widget.economy.wave,
      'score': widget.economy.score,
    }).catchError((_) {});
  }

  /// Fires the same sync the moment the base goes down (see
  /// [_syncRunStats]), and rebuilds so PopScope's `canPop` (see build())
  /// picks up gameOver having just turned true — once the run is over
  /// there's nothing left to warn about losing, and LoseOverlay's own
  /// "back to home" button needs a plain, unintercepted Navigator.pop() to
  /// keep working.
  void _onEconomyChanged() {
    final isOver = widget.economy.gameOver;
    if (isOver && !_wasGameOver) {
      _syncRunStats();
      setState(() {});
    }
    _wasGameOver = isOver;
  }

  Future<void> _openSettings() async {
    _game.pauseEngine();
    await showSettingsDialog(context, widget.economy);
    _game.resumeEngine();
  }

  Future<void> _openBuyMenu() async {
    _game.pauseEngine();
    await showBuyLevelDialog(context, _game);
    _game.resumeEngine();
  }

  /// Backing out mid-run (system back gesture/button) would otherwise
  /// silently discard the run with no confirmation — this run's wave/score
  /// hasn't been saved to bestWave/bestScore yet (that only happens once
  /// the run actually ends, see Economy._finalizeRun), so leaving now loses
  /// it for good. Pauses the engine while the dialog is up for the same
  /// reason _openSettings/_openBuyMenu do: nothing should keep happening
  /// to the base while the player can't see or react to it.
  Future<void> _confirmLeave() async {
    _game.pauseEngine();
    final s = Strings(widget.economy.language);
    final leave = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: s.leaveGameWarning,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF3A2A1C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE05A3A), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE05A3A),
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  s.leaveGameWarning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(s.cancelAction),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE05A3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(s.acceptAction),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      setState(() => _allowPop = true);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _game.resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // No confirmation needed once the run is already over (its stats are
      // already saved — see _finalizeRun) — canPop true there lets
      // LoseOverlay's own "back to home" button (a plain Navigator.pop())
      // through unintercepted, same as the system back gesture.
      canPop: _allowPop || widget.economy.gameOver,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2A2018),
        body: Column(
          children: [
            // TopHud is transparent and overlaid on the game canvas (Stack)
            // rather than a separate opaque row above it, so the field
            // background shows through behind the money/score/level bar.
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameWidget<TurretDefenseGame>(
                      game: _game,
                      overlayBuilderMap: {
                        'lose': (context, game) => LoseOverlay(game: game),
                        'bossFight': (context, game) => BossBanner(game: game),
                        'bossDefeated': (context, game) =>
                            BossDefeatedOverlay(game: game),
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: TopHud(
                      economy: widget.economy,
                      onSettingsTap: _openSettings,
                    ),
                  ),
                ],
              ),
            ),
            BaseHealthBar(economy: widget.economy),
            BottomControls(
              economy: widget.economy,
              onBuy: _openBuyMenu,
              onFree: _game.claimFreeTurret,
              onToggleSell: widget.economy.toggleSellMode,
            ),
          ],
        ),
      ),
    );
  }
}
