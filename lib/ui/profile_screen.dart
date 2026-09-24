import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import '../services/nav_guard.dart';
import '../theme/app_fonts.dart';
import 'achievements_screen.dart';
import 'avatar_initials.dart';
import 'customize_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'my_purchases_screen.dart';
import 'national_ranking_screen.dart';

/// "Mi Perfil": greeting + avatar + username/email, an "Editar perfil"
/// shortcut, and the account menu (purchases, customization, national
/// ranking, notifications toggle, log out). Fetches a fresh `GET /profile`
/// on open rather than trusting the cached [ApiClient.currentUser], since
/// the user may have just edited their profile or equipped an item.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final data = await ApiClient.get('/profile') as Map<String, dynamic>;
    return data['user'] as Map<String, dynamic>;
  }

  Future<void> _reload() async {
    setState(() => _profile = _fetchProfile());
    await _profile;
  }

  Future<void> _openEditProfile(Map<String, dynamic> user) async {
    if (!NavGuard.allow()) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(economy: widget.economy, user: user),
      ),
    );
    if (changed == true) _reload();
  }

  Future<void> _logOut() async {
    await ApiClient.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(economy: widget.economy)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.economy.language);
    return Scaffold(
      backgroundColor: const Color(0xFF2A2018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A2A1C),
        foregroundColor: Colors.white,
        title: Text(s.profileTitle),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFCB7B2A)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.profileLoadError,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _reload, child: Text(s.retry)),
                ],
              ),
            );
          }

          final user = snapshot.data!;
          final username = user['username']?.toString() ?? '';
          final fullName = user['full_name']?.toString();
          final email = user['email']?.toString() ?? '';

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  color: const Color(0xFFCB7B2A),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    children: [
                      Text(
                        '${s.greetingHello},',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: AvatarInitials(
                          username: username,
                          fullName: fullName,
                          radius: 44,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          (fullName != null && fullName.isNotEmpty)
                              ? fullName
                              : username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          '@$username',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => _openEditProfile(user),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: Text(s.editProfile),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFCB7B2A)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _MenuTile(
                        icon: Icons.brush_rounded,
                        label: s.menuCustomize,
                        onTap: () {
                          if (!NavGuard.allow()) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomizeScreen(economy: widget.economy),
                            ),
                          );
                        },
                      ),
                      _MenuTile(
                        icon: Icons.emoji_events_rounded,
                        label: s.menuAchievements,
                        onTap: () {
                          if (!NavGuard.allow()) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AchievementsScreen(economy: widget.economy),
                            ),
                          );
                        },
                      ),
                      _MenuTile(
                        icon: Icons.flag_rounded,
                        label: s.menuNationalRanking,
                        onTap: () {
                          if (!NavGuard.allow()) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NationalRankingScreen(
                                economy: widget.economy,
                                countryCode: user['country_code']?.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                      _MenuTile(
                        icon: Icons.receipt_long_rounded,
                        label: s.menuMyPurchases,
                        onTap: () {
                          if (!NavGuard.allow()) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MyPurchasesScreen(economy: widget.economy),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: widget.economy,
                        builder: (context, _) {
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: const Color(0xFFCB7B2A),
                            value: widget.economy.notificationsOn,
                            onChanged: widget.economy.setNotificationsOn,
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.notifications_rounded,
                                  color: Color(0xFFCB7B2A),
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  s.menuNotifications,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(left: 38),
                              child: Text(
                                s.notificationsHint,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Pinned outside the scrollable list — with Achievements now in
              // the menu too, this row could end up below the fold on
              // shorter screens; keeping it always visible here means it's
              // never lost behind a scroll.
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white24)),
                ),
                child: _MenuTile(
                  icon: Icons.logout_rounded,
                  label: s.logOut,
                  color: Colors.redAccent,
                  onTap: _logOut,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFCB7B2A),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: AppFonts.title(
          color: color == Colors.redAccent ? Colors.redAccent : Colors.white,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: onTap,
    );
  }
}
