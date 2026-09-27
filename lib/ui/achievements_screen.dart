import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/achievements.dart';
import '../models/boss_types.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import '../theme/app_fonts.dart';
import 'shop_item_card.dart';

/// "Logros": a sticker-album look at the 40 collectible achievement
/// figures earned by defeating bosses (see models/achievements.dart and
/// TurretDefenseGame.onBossKilled). Shown as a two-page spread — 9 figures
/// per page, 18 per spread — with pagination below for the remaining
/// figures (40 total -> 3 spreads: 18/18/4).
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _perPage = 18;
  static const _perHalf = 9;

  int _page = 1;

  late Future<String?> _claimedSkuFuture;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _claimedSkuFuture = _fetchClaimedSku();
  }

  /// Which (if any) of [kBossRewardSkus] this account already owns — null
  /// means none claimed yet. Only ever one can be owned (the server
  /// enforces that — see RewardsController::claimBossSkin), so the first
  /// match found is the answer.
  Future<String?> _fetchClaimedSku() async {
    if (!ApiClient.hasToken) return null;
    try {
      final data = await ApiClient.get('/profile') as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final item in items) {
        final sku = item['sku']?.toString();
        if (sku != null && kBossRewardSkus.containsKey(sku)) return sku;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _claim(String sku, Strings s) async {
    final confirmed = await _showClaimConfirmDialog(context, s);
    if (confirmed != true || !mounted) return;
    setState(() => _claiming = true);
    try {
      await ApiClient.post('/rewards/claim-boss-skin', body: {'sku': sku});
      if (!mounted) return;
      setState(() => _claimedSkuFuture = _fetchClaimedSku());
      await _claimedSkuFuture;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.rewardClaimError)));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    final totalPages = (kAchievementCount / _perPage).ceil();
    final start = (_page - 1) * _perPage;
    final spread = kAchievements.skip(start).take(_perPage).toList();
    // Padded to a full 9 with nulls on the last (partial) spread, so that
    // page reads as empty slots rather than a short, lopsided grid.
    final left = List<Achievement?>.generate(
        _perHalf, (i) => i < spread.length ? spread[i] : null);
    final right = List<Achievement?>.generate(
        _perHalf, (i) => _perHalf + i < spread.length ? spread[_perHalf + i] : null);
    final albumComplete =
        widget.economy.unlockedAchievements.length >= kAchievementCount;

    return AnimatedBuilder(
      animation: widget.economy,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF2A2018),
          appBar: AppBar(
            backgroundColor: const Color(0xFF3A2A1C),
            foregroundColor: Colors.white,
            title: Text(s.achievementsTitle),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      s.achievementsHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFF54402C), width: 2)),
                            ),
                            child: _AlbumPage(entries: left, economy: widget.economy),
                          ),
                        ),
                        Expanded(child: _AlbumPage(entries: right, economy: widget.economy)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Text(
                          s.achievementsPageLabel(_page, totalPages),
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _page > 1 ? () => setState(() => _page--) : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                              color: const Color(0xFFCB7B2A),
                              disabledColor: Colors.white24,
                            ),
                            IconButton(
                              onPressed: _page < totalPages ? () => setState(() => _page++) : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                              color: const Color(0xFFCB7B2A),
                              disabledColor: Colors.white24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.rewardsTitle,
                          style: AppFonts.title(color: Colors.white, fontSize: 17),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.rewardsHint,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<String?>(
                          future: _claimedSkuFuture,
                          builder: (context, snapshot) {
                            final claimedSku = snapshot.data;
                            final loading =
                                snapshot.connectionState != ConnectionState.done;
                            return Row(
                              children: [
                                for (final entry in kBossRewardSkus.entries) ...[
                                  Expanded(
                                    child: _RewardCard(
                                      s: s,
                                      imagePath:
                                          'assets/images/shop/${entry.value}.png',
                                      name: s.rewardSkuName(entry.key),
                                      albumComplete: albumComplete,
                                      claimed: claimedSku == entry.key,
                                      anyClaimed: claimedSku != null,
                                      busy: loading || _claiming,
                                      onClaim: () => _claim(entry.key, s),
                                    ),
                                  ),
                                  if (entry.key != kBossRewardSkus.keys.last)
                                    const SizedBox(width: 10),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<bool?> _showClaimConfirmDialog(BuildContext context, Strings s) {
  const gold = Color(0xFFFFC94D);
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: s.claimConfirmTitle,
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
            border: Border.all(color: const Color(0xFF3A2A1C), width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: gold, size: 40),
              const SizedBox(height: 16),
              Text(
                s.claimConfirmTitle,
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
                        backgroundColor: const Color(0xFFCB7B2A),
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
}

/// One claimable reward slot: the boss-skin icon (gold-bordered like the
/// shop, greyscale + padlocked while unclaimable) plus a Claim/Claimed
/// button below, matching CustomizeScreen's _OwnedItemCard button states.
class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.s,
    required this.imagePath,
    required this.name,
    required this.albumComplete,
    required this.claimed,
    required this.anyClaimed,
    required this.busy,
    required this.onClaim,
  });

  final Strings s;
  final String imagePath;
  final String name;
  final bool albumComplete;
  final bool claimed;
  final bool anyClaimed;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    // Visible in full color once the album is complete (so the player can
    // see what they're choosing between) — except once someone else of the
    // three has already been claimed, only the actually-claimed one stays
    // revealed; the other two go back to looking locked, since they can
    // never be obtained now.
    final revealed = claimed || (albumComplete && !anyClaimed);
    final canTap = albumComplete && !anyClaimed && !busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (revealed)
              ShopItemImageTile(imagePath: imagePath, highlighted: claimed)
            else
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 0.55, 0,
                ]),
                child: ShopItemImageTile(imagePath: imagePath),
              ),
            if (!revealed)
              const Icon(
                Icons.lock_rounded,
                color: Colors.white70,
                size: 28,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppFonts.title(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: anyClaimed
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    s.claimedLabel,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                )
              : OutlinedButton(
                  onPressed: canTap ? onClaim : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCB7B2A),
                    disabledForegroundColor: Colors.white24,
                    side: BorderSide(
                      color: canTap
                          ? const Color(0xFFCB7B2A)
                          : Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    s.claimAction,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AlbumPage extends StatelessWidget {
  const _AlbumPage({required this.entries, required this.economy});

  // A null entry is a blank slot — used to pad the last, partial page back
  // up to a full 9-per-side so it keeps the same height/density as every
  // other page instead of looking sparse.
  final List<Achievement?> entries;
  final Economy economy;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final achievement in entries)
          _AchievementSlot(
            achievement: achievement,
            unlocked: achievement != null && economy.unlockedAchievements.contains(achievement.id),
          ),
      ],
    );
  }
}

class _AchievementSlot extends StatelessWidget {
  const _AchievementSlot({required this.achievement, required this.unlocked});

  final Achievement? achievement;
  final bool unlocked;

  static const _gold = Color(0xFFFFC94D);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF241a11),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: unlocked ? _gold : const Color(0xFF54402C), width: 2),
        ),
        child: achievement == null
            ? null
            : unlocked
                ? Image.asset(achievement!.imagePath, fit: BoxFit.contain)
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.35, 0,
                    ]),
                    child: Image.asset(achievement!.imagePath, fit: BoxFit.contain),
                  ),
      ),
    );
  }
}
