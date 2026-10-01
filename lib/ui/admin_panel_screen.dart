import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/economy.dart';
import '../services/api_client.dart';
import '../theme/app_fonts.dart';
import 'avatar_initials.dart';
import 'shop_item_card.dart';

const _bg = Color(0xFF2A2018);
const _card = Color(0xFF3A2A1C);
const _cardDark = Color(0xFF241A11);
const _border = Color(0xFF54402C);
const _accent = Color(0xFFCB7B2A);

int _id(Map<String, dynamic> m) => int.parse(m['id'].toString());
bool _flag(dynamic v) => v != null && v.toString() == '1';

String _formatDate(dynamic raw) {
  final d = DateTime.tryParse(raw?.toString() ?? '');
  if (d == null) return raw?.toString() ?? '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Admin-only screen (reachable from "Mi perfil" when users.role = 'admin'):
/// live user search (suggestions as you type), then for the chosen user —
/// grant any shop item, remove items from their inventory/customization,
/// and apply sanctions (temporary suspension, permanent ban, login block),
/// plus the history of admin actions taken on them. Everything goes
/// through /admin/* endpoints (AdminController), which re-check the role
/// server-side — hiding the menu is only a convenience.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key, required this.economy});

  final Economy economy;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _filterCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  Timer? _debounce;
  int _searchSeq = 0;

  List<Map<String, dynamic>> _suggestions = [];
  bool _searching = false;

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _actions = [];
  bool _loadingDetail = false;

  List<Map<String, dynamic>> _catalog = [];
  String _catalogCategory = 'all';
  int _suspendDays = 7;
  bool _busy = false;

  Strings get s => Strings(widget.economy.language);

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _filterCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade800 : null,
        ),
      );
  }

  Future<void> _loadCatalog() async {
    try {
      final data = await ApiClient.get('/admin/shop-items') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _catalog = (data['items'] as List).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    }
  }

  // ─── Búsqueda en vivo ────────────────────────────────────────────────────

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      _searchSeq++;
      setState(() {
        _suggestions = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_searchSeq;
    try {
      final data = await ApiClient.get('/admin/users/search', query: {'q': q})
          as Map<String, dynamic>;
      // A newer keystroke already fired another request — ignore this one.
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions = (data['users'] as List).cast<Map<String, dynamic>>();
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() => _searching = false);
      _snack(e.message, error: true);
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    _searchFocus.unfocus();
    _searchCtrl.clear();
    _reasonCtrl.clear();
    setState(() {
      _user = user;
      _suggestions = [];
      _items = [];
      _actions = [];
      _searching = false;
    });
    _tabs.index = 0;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final user = _user;
    if (user == null) return;
    setState(() => _loadingDetail = true);
    try {
      final data = await ApiClient.get('/admin/users/${_id(user)}') as Map<String, dynamic>;
      if (!mounted || _user == null || _id(_user!) != _id(user)) return;
      setState(() {
        _user = data['user'] as Map<String, dynamic>;
        _items = (data['items'] as List).cast<Map<String, dynamic>>();
        _actions = (data['actions'] as List).cast<Map<String, dynamic>>();
      });
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  // ─── Acciones ────────────────────────────────────────────────────────────

  Future<bool> _confirm(String message, {bool danger = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: danger ? Colors.red.shade700 : _accent,
            ),
            child: Text(s.adminConfirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _run(String path, Map<String, dynamic> body, String successMessage) async {
    final user = _user;
    if (user == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ApiClient.post('/admin/users/${_id(user)}/$path', body: body);
      _snack(successMessage);
      await _loadDetail();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grant(Map<String, dynamic> item) async {
    final name = s.shopItemName(item['sku'].toString(), item['name'].toString());
    if (!await _confirm(s.adminGrantConfirm(name, _user!['username'].toString()))) return;
    await _run('grant', {'shop_item_id': _id(item)}, s.adminGranted(name));
  }

  Future<void> _revoke(Map<String, dynamic> item) async {
    final name = s.shopItemName(item['sku'].toString(), item['name'].toString());
    if (!await _confirm(s.adminRemoveConfirm(name, _user!['username'].toString()), danger: true)) {
      return;
    }
    await _run('revoke', {'shop_item_id': _id(item)}, s.adminRemoved(name));
  }

  Future<void> _sanction(String action, String confirmText, {bool danger = true}) async {
    if (!await _confirm(confirmText, danger: danger)) return;
    await _run(
      'sanction',
      {
        'action': action,
        if (action == 'suspend') 'days': _suspendDays,
        'reason': _reasonCtrl.text.trim(),
      },
      s.adminSanctionApplied,
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _searchCtrl.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: Colors.white,
        title: Text(s.adminPanelTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: (v) {
                setState(() {});
                _onQueryChanged(v);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: s.adminSearchHint,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _accent),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onQueryChanged('');
                              setState(() {});
                            },
                          )
                        : null),
                filled: true,
                fillColor: _cardDark,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: showSuggestions
                ? _buildSuggestions()
                : (_user == null ? _buildEmpty() : _buildUserPanel()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 72, color: _accent.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              s.adminSearchEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          _searching ? '' : s.adminNoResults,
          style: const TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final u = _suggestions[i];
        return Material(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectUser(u),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  AvatarInitials(
                    username: u['username'].toString(),
                    fullName: u['full_name']?.toString(),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${u['username']}',
                          style: AppFonts.title(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          u['email']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ..._badges(u),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _badges(Map<String, dynamic> u) {
    return [
      if (u['role'] == 'admin') _Badge(s.adminRoleAdmin, Colors.amber.shade700),
      if (u['status'] == 'banned') _Badge(s.adminStatusBanned, Colors.red.shade700),
      if (u['status'] == 'suspended') _Badge(s.adminStatusSuspended, Colors.orange.shade800),
      if (_flag(u['login_blocked'])) _Badge(s.adminLoginBlocked, Colors.deepPurple.shade400),
    ];
  }

  Widget _buildUserPanel() {
    final u = _user!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                AvatarInitials(
                  username: u['username'].toString(),
                  fullName: u['full_name']?.toString(),
                  radius: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (u['full_name']?.toString().isNotEmpty ?? false)
                            ? u['full_name'].toString()
                            : u['username'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.title(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        '@${u['username']}  ·  ${u['email'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (u['status'] == 'active' && !_flag(u['login_blocked']))
                            _Badge(s.adminStatusActive, Colors.green.shade600),
                          ..._badges(u),
                          if (u['status'] == 'suspended' && u['suspended_until'] != null)
                            Text(
                              s.adminSuspendedUntil(_formatDate(u['suspended_until'])),
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => setState(() => _user = null),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabs,
          labelColor: _accent,
          unselectedLabelColor: Colors.white54,
          indicatorColor: _accent,
          labelStyle: AppFonts.title(color: _accent, fontSize: 12),
          tabs: [
            Tab(text: s.adminTabGrant),
            Tab(text: s.adminTabItems),
            Tab(text: s.adminTabSanctions),
            Tab(text: s.adminTabHistory),
          ],
        ),
        if (_loadingDetail || _busy)
          const LinearProgressIndicator(minHeight: 2, color: _accent, backgroundColor: Colors.transparent),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildGrantTab(),
              _buildItemsTab(),
              _buildSanctionsTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Entregar ────────────────────────────────────────────────────────────

  Widget _buildGrantTab() {
    final ownedIds = _items.map(_id).toSet();
    final text = _filterCtrl.text.trim().toLowerCase();
    final filtered = _catalog.where((item) {
      if (_catalogCategory != 'all' && item['category'] != _catalogCategory) return false;
      if (text.isEmpty) return true;
      final name = s.shopItemName(item['sku'].toString(), item['name'].toString()).toLowerCase();
      return name.contains(text) || item['sku'].toString().toLowerCase().contains(text);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            controller: _filterCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: s.adminFilterItems,
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.filter_list_rounded, color: Colors.white38, size: 20),
              filled: true,
              fillColor: _cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in ['all', ...shopCategoryOrder])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(
                      c == 'all' ? s.adminAll : s.shopCategoryShortLabel(c),
                      style: TextStyle(
                        fontSize: 12,
                        color: _catalogCategory == c ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: _catalogCategory == c,
                    selectedColor: _accent,
                    backgroundColor: _cardDark,
                    side: const BorderSide(color: _border),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _catalogCategory = c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = filtered[i];
              final owned = ownedIds.contains(_id(item));
              return _ItemRow(
                imagePath: shopItemImagePath(item),
                title: s.shopItemName(item['sku'].toString(), item['name'].toString()),
                subtitle: [
                  s.shopCategoryShortLabel(item['category'].toString()),
                  if (item['is_active'].toString() == '0') s.adminInactiveItem,
                ].join('  ·  '),
                trailing: owned
                    ? _Badge(s.adminAlreadyOwned, Colors.green.shade700)
                    : FilledButton(
                        onPressed: _busy ? null : () => _grant(item),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 34),
                        ),
                        child: Text(s.adminGrantButton, style: const TextStyle(fontSize: 12)),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Sus items ───────────────────────────────────────────────────────────

  Widget _buildItemsTab() {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          _loadingDetail ? '' : s.adminNoItems,
          style: const TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = _items[i];
        final equipped = item['equipped'].toString() != '0';
        return _ItemRow(
          imagePath: shopItemImagePath(item),
          title: s.shopItemName(item['sku'].toString(), item['name'].toString()),
          subtitle: s.shopCategoryShortLabel(item['category'].toString()),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (equipped) _Badge(s.adminEquipped, Colors.green.shade700),
              IconButton(
                tooltip: s.adminRemoveItem,
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
                onPressed: _busy ? null : () => _revoke(item),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Castigos ────────────────────────────────────────────────────────────

  Widget _buildSanctionsTab() {
    final u = _user!;
    if (u['role'] == 'admin') {
      return Center(
        child: Text(s.adminCannotSanctionAdmin, style: const TextStyle(color: Colors.white54)),
      );
    }
    final username = u['username'].toString();
    final sanctioned = u['status'] == 'suspended' || u['status'] == 'banned';
    final blocked = _flag(u['login_blocked']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        TextField(
          controller: _reasonCtrl,
          maxLength: 200,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: s.adminReasonLabel,
            labelStyle: const TextStyle(color: Colors.white54),
            counterStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _cardDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
        ),
        if (sanctioned) ...[
          const SizedBox(height: 4),
          _ActionButton(
            icon: Icons.restore_rounded,
            label: s.adminRestoreButton,
            color: Colors.green.shade600,
            onPressed: _busy ? null : () => _sanction('restore', '${s.adminRestoreButton}: @$username?', danger: false),
          ),
        ],
        const SizedBox(height: 12),
        _SanctionCard(
          icon: Icons.timer_outlined,
          color: Colors.orange.shade700,
          title: s.adminSuspendTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final d in [1, 3, 7, 15, 30])
                    ChoiceChip(
                      label: Text(
                        s.adminDays(d),
                        style: TextStyle(color: _suspendDays == d ? Colors.black : Colors.white70, fontSize: 12),
                      ),
                      selected: _suspendDays == d,
                      selectedColor: Colors.orange.shade600,
                      backgroundColor: _cardDark,
                      side: const BorderSide(color: _border),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _suspendDays = d),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.pause_circle_outline_rounded,
                label: '${s.adminSuspendButton} (${s.adminDays(_suspendDays)})',
                color: Colors.orange.shade700,
                onPressed: _busy
                    ? null
                    : () => _sanction(
                          'suspend',
                          '${s.adminSuspendButton} @$username — ${s.adminDays(_suspendDays)}?',
                        ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SanctionCard(
          icon: Icons.lock_outline_rounded,
          color: Colors.deepPurple.shade400,
          title: s.adminBlockTitle,
          hint: s.adminBlockHint,
          child: _ActionButton(
            icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
            label: blocked ? s.adminUnblockButton : s.adminBlockButton,
            color: blocked ? Colors.green.shade600 : Colors.deepPurple.shade400,
            onPressed: _busy
                ? null
                : () => blocked
                    ? _sanction('unblock_login', '${s.adminUnblockButton}: @$username?', danger: false)
                    : _sanction('block_login', '${s.adminBlockButton}: @$username?'),
          ),
        ),
        const SizedBox(height: 12),
        _SanctionCard(
          icon: Icons.gavel_rounded,
          color: Colors.red.shade700,
          title: s.adminBanTitle,
          hint: s.adminBanHint,
          child: _ActionButton(
            icon: Icons.gavel_rounded,
            label: s.adminBanButton,
            color: Colors.red.shade700,
            onPressed: _busy || u['status'] == 'banned'
                ? null
                : () => _sanction('ban', '${s.adminBanButton}: @$username?'),
          ),
        ),
      ],
    );
  }

  // ─── Historial ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_actions.isEmpty) {
      return Center(
        child: Text(
          _loadingDetail ? '' : s.adminNoHistory,
          style: const TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _actions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = _actions[i];
        final action = a['action'].toString();
        final danger = const {'suspend', 'ban', 'block_login', 'revoke_item'}.contains(action);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: danger ? Colors.red.shade400 : Colors.green.shade400, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.adminActionLabel(action),
                      style: AppFonts.title(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    _formatDate(a['created_at']),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              if ((a['details']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(a['details'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '@${a['admin_username'] ?? '?'}',
                  style: const TextStyle(color: _accent, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String? imagePath;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFC94D).withValues(alpha: 0.6)),
            ),
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_rounded, color: Colors.white38),
                  )
                : const Icon(Icons.card_giftcard_rounded, color: Colors.white38),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.title(color: Colors.white, fontSize: 13),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SanctionCard extends StatelessWidget {
  const _SanctionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
    this.hint,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppFonts.title(color: Colors.white, fontSize: 14)),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(hint!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
