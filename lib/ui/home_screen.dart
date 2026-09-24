import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/boss_types.dart';
import '../models/economy.dart';
import '../models/enemy_types.dart';
import '../services/api_client.dart';
import '../services/nav_guard.dart';
import '../services/update_checker.dart';
import '../theme/app_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateChecker.check();
    if (update == null || !mounted) return;

    final s = Strings(_economy.language);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A2A1C),
        title: Text(s.updateAvailableTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          update.notes.isNotEmpty
              ? '${s.updateAvailableBody(update.version)}\n\n${update.notes}'
              : s.updateAvailableBody(update.version),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.updateLater, style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              launchUrl(Uri.parse(update.downloadUrl), mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCB7B2A)),
            child: Text(s.updateDownload, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _play() {
    if (!NavGuard.allow()) return;
    // Fire-and-forget: TurretComponent/ProjectileComponent react live to
    // economy.equippedTurretHue/equippedBulletHue changing, so the tint
    // just catches up moments after the run starts rather than blocking
    // navigation on it.
    _syncEquippedSkins();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(economy: _economy)),
    );
  }

  /// Looks up the player's currently-equipped `turret_skin`,
  /// `bullet_effect` and `mob_skin` items (if any) and resolves each one's
  /// `tint_hue`/`asset_key` from the owned-items list, so every turret
  /// tier, every shot fired, and every ground mob in the run gets
  /// reskinned — not just tier 1, and not just a static shop preview.
  Future<void> _syncEquippedSkins() async {
    if (!ApiClient.hasToken) {
      _economy.setEquippedTurretHue(null);
      _economy.setEquippedBulletHue(null);
      _economy.setEquippedBulletAssetKey(null);
      for (final kind in EnemyKind.values.map((k) => k.name)) {
        _economy.setEquippedMobSkinForKind(kind, null);
      }
      for (final slot in kBossTypes.map((b) => b.slotId)) {
        _economy.setEquippedBossSkinForSlot(slot, null);
      }
      return;
    }
    try {
      final data = await ApiClient.get('/profile') as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final equipped = (data['equipped'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      num? equippedTurretSkinId;
      num? equippedBulletSkinId;
      // 'mob_skin:<kind>' / 'boss_skin:<slot>' — each an independent equip
      // slot server-side (see the same convention documented on
      // Economy.equippedMobSkinByKind), so a ground skin and a hybrid
      // skin (or a golem skin and a future goblin skin) can be equipped
      // at the same time instead of fighting over one shared category row.
      final mobSkinItemIdByKind = <String, num?>{};
      final bossSkinItemIdBySlot = <String, num?>{};
      for (final e in equipped) {
        final category = e['category']?.toString() ?? '';
        if (category == 'turret_skin') {
          equippedTurretSkinId = e['shop_item_id'] as num?;
        } else if (category == 'bullet_effect') {
          equippedBulletSkinId = e['shop_item_id'] as num?;
        } else if (category.startsWith('mob_skin:')) {
          mobSkinItemIdByKind[category.substring('mob_skin:'.length)] = e['shop_item_id'] as num?;
        } else if (category.startsWith('boss_skin:')) {
          bossSkinItemIdBySlot[category.substring('boss_skin:'.length)] = e['shop_item_id'] as num?;
        }
      }

      _economy.setEquippedTurretHue(_metaFor(items, equippedTurretSkinId).hue);
      final bulletMeta = _metaFor(items, equippedBulletSkinId);
      _economy.setEquippedBulletHue(bulletMeta.hue);
      _economy.setEquippedBulletAssetKey(bulletMeta.assetKey);
      for (final kind in EnemyKind.values.map((k) => k.name)) {
        _economy.setEquippedMobSkinForKind(kind, _metaFor(items, mobSkinItemIdByKind[kind]).assetKey);
      }
      for (final slot in kBossTypes.map((b) => b.slotId)) {
        _economy.setEquippedBossSkinForSlot(slot, _metaFor(items, bossSkinItemIdBySlot[slot]).assetKey);
      }
    } catch (_) {
      // Best-effort — worst case the run just uses the default art.
    }
  }

  ({double? hue, String? assetKey}) _metaFor(List<Map<String, dynamic>> items, num? shopItemId) {
    if (shopItemId == null) return (hue: null, assetKey: null);
    for (final item in items) {
      if ((item['id'] as num?) != shopItemId) continue;
      final rawMetadata = item['metadata'];
      if (rawMetadata is String && rawMetadata.isNotEmpty) {
        final metadata = jsonDecode(rawMetadata) as Map<String, dynamic>;
        return (
          hue: (metadata['tint_hue'] as num?)?.toDouble(),
          assetKey: metadata['asset_key'] as String?,
        );
      }
    }
    return (hue: null, assetKey: null);
  }

  Future<void> _openSettings() => showSettingsDialog(context, _economy);

  void _openRanking() {
    if (!NavGuard.allow()) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RankingScreen(economy: _economy)),
    );
  }

  void _openProfileOrLogin() {
    if (!NavGuard.allow()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApiClient.hasToken
            ? ProfileScreen(economy: _economy)
            : LoginScreen(economy: _economy),
      ),
    );
  }

  void _openShop() {
    if (!NavGuard.allow()) return;
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
                                style: AppFonts.title(
                                  color: Colors.white,
                                  fontSize: 22,
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
              style: AppFonts.title(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
