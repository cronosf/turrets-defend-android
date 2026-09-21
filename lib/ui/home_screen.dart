import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import 'game_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';
import 'settings_overlay.dart';
import 'shop_screen.dart';

/// The app's landing screen, reached only after [LoginScreen]: game banner +
/// tap-to-play, and a footer nav with the profile/ranking/shop/settings
/// stubs. Receives the single shared [Economy] instance that [LoginScreen]
/// created (and already ran [GameAudio.init]/`loadPersisted` on) rather than
/// creating its own.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Economy get _economy => widget.economy;

  void _play() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(economy: _economy)),
    );
  }

  Future<void> _openSettings() => showSettingsDialog(context, _economy);

  void _openRanking() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RankingScreen(economy: _economy)),
    );
  }

  void _openProfileOrLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApiClient.hasToken
            ? ProfileScreen(economy: _economy)
            : LoginScreen(economy: _economy),
      ),
    );
  }

  void _openShop() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShopScreen(economy: _economy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      body: AnimatedBuilder(
        animation: _economy,
        builder: (context, _) {
          final s = Strings(_economy.language);
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _play,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final maxW = constraints.maxWidth.isFinite
                                    ? constraints.maxWidth
                                    : 340.0;
                                return Image.asset(
                                  'assets/images/ui/MenuBanner.png',
                                  width: maxW,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.6, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) =>
                                  Opacity(opacity: value, child: child),
                              child: Text(
                                s.tapToPlay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (_economy.bestWave > 0) ...[
                              const SizedBox(height: 16),
                              Text(
                                s.bestWave(_economy.bestWave),
                                style: const TextStyle(color: Colors.white70, fontSize: 15),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _FooterNav(
                  strings: s,
                  onProfile: _openProfileOrLogin,
                  onRanking: _openRanking,
                  onShop: _openShop,
                  onSettings: _openSettings,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FooterNav extends StatelessWidget {
  const _FooterNav({
    required this.strings,
    required this.onProfile,
    required this.onRanking,
    required this.onShop,
    required this.onSettings,
  });

  final Strings strings;
  final VoidCallback onProfile;
  final VoidCallback onRanking;
  final VoidCallback onShop;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E170F),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: Icons.person_rounded, label: strings.navProfile, onTap: onProfile),
          _NavItem(icon: Icons.emoji_events_rounded, label: strings.navRanking, onTap: onRanking),
          _NavItem(icon: Icons.storefront_rounded, label: strings.navShop, onTap: onShop),
          _NavItem(icon: Icons.settings_rounded, label: strings.navSettings, onTap: onSettings),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFCB7B2A), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
