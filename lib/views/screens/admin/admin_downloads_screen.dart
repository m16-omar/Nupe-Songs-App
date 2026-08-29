import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/api_constants.dart';

class AdminDownloadsScreen extends StatefulWidget {
  const AdminDownloadsScreen({super.key});

  @override
  State<AdminDownloadsScreen> createState() => _AdminDownloadsScreenState();
}

class _AdminDownloadsScreenState extends State<AdminDownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _userStats = [];
  List<Map<String, dynamic>> _songStats = [];

  bool _loadingUsers = true;
  bool _loadingSongs = true;
  String? _errorUsers;
  String? _errorSongs;

  // Brand colours
  static const Color nupeBlue  = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _baseUrl => ApiConstants.baseUrl;

  Future<http.Response> _get(String path, String token) async {
    if (ApiConstants.useLiveBackend) {
      return http.get(
        Uri.parse('$_baseUrl$path'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
    }
    return http.get(
      Uri.parse('http://127.0.0.1:8000/api$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 8));
  }

  Future<void> _fetchAll() async {
    final token = context.read<AuthController>().token;
    if (token == null) return;
    await Future.wait([_fetchUserStats(token), _fetchSongStats(token)]);
  }

  Future<void> _fetchUserStats(String token) async {
    setState(() { _loadingUsers = true; _errorUsers = null; });
    try {
      final res = await _get('/admin/downloads/user-stats/', token);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _userStats = data.cast<Map<String, dynamic>>();
          _loadingUsers = false;
        });
      } else {
        setState(() { _errorUsers = 'Failed to load (${res.statusCode})'; _loadingUsers = false; });
      }
    } catch (e) {
      setState(() { _errorUsers = 'Network error: $e'; _loadingUsers = false; });
    }
  }

  Future<void> _fetchSongStats(String token) async {
    setState(() { _loadingSongs = true; _errorSongs = null; });
    try {
      final res = await _get('/admin/downloads/song-stats/', token);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _songStats = data.cast<Map<String, dynamic>>();
          _loadingSongs = false;
        });
      } else {
        setState(() { _errorSongs = 'Failed to load (${res.statusCode})'; _loadingSongs = false; });
      }
    } catch (e) {
      setState(() { _errorSongs = 'Network error: $e'; _loadingSongs = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF0E0E12) : const Color(0xFFF4F6FB);
    final card   = isDark ? const Color(0xFF1A1A22) : Colors.white;
    final text   = isDark ? Colors.white : const Color(0xFF0D0D1A);
    final sub    = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0E0E12) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Download Analytics',
          style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: nupeBlue),
            onPressed: _fetchAll,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: nupeBlue,
          labelColor: nupeBlue,
          unselectedLabelColor: sub,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'By User'),
            Tab(text: 'By Song'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserTab(card, text, sub, isDark),
          _buildSongTab(card, text, sub, isDark),
        ],
      ),
    );
  }

  // ── By User Tab ────────────────────────────────────────────────────
  Widget _buildUserTab(Color card, Color text, Color sub, bool isDark) {
    if (_loadingUsers) return _loadingWidget();
    if (_errorUsers != null) return _errorWidget(_errorUsers!, () => _fetchUserStats(context.read<AuthController>().token ?? ''));

    if (_userStats.isEmpty) {
      return _emptyWidget('No downloads recorded yet.', Icons.download_outlined);
    }

    final total = _userStats.fold<int>(0, (sum, u) => sum + (u['download_count'] as int));

    return RefreshIndicator(
      color: nupeBlue,
      onRefresh: () => _fetchUserStats(context.read<AuthController>().token ?? ''),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary banner
          _summaryCard(
            card: card, text: text, sub: sub,
            icon: Icons.people_rounded,
            colour: nupeBlue,
            label: 'Total Downloads',
            value: total.toString(),
            extra: '${_userStats.length} users',
          ),
          const SizedBox(height: 16),
          Text('Users by Downloads', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ..._userStats.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final u    = entry.value;
            final count = u['download_count'] as int;
            final pct   = total > 0 ? count / total : 0.0;
            return _userCard(card: card, text: text, sub: sub, rank: rank, u: u, count: count, pct: pct, isDark: isDark);
          }),
        ],
      ),
    );
  }

  Widget _userCard({
    required Color card, required Color text, required Color sub,
    required int rank, required Map<String, dynamic> u,
    required int count, required double pct, required bool isDark,
  }) {
    final Color rankColor = rank == 1 ? const Color(0xFFFFD700)
        : rank == 2 ? const Color(0xFFC0C0C0)
        : rank == 3 ? const Color(0xFFCD7F32)
        : sub;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('#$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['full_name'] ?? '—', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(u['email'] ?? '', style: TextStyle(color: sub, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$count', style: TextStyle(color: nupeGreen, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('downloads', style: TextStyle(color: sub, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(nupeGreen),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(pct * 100).toStringAsFixed(1)}% of total', style: TextStyle(color: sub, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ── By Song Tab ────────────────────────────────────────────────────
  Widget _buildSongTab(Color card, Color text, Color sub, bool isDark) {
    if (_loadingSongs) return _loadingWidget();
    if (_errorSongs != null) return _errorWidget(_errorSongs!, () => _fetchSongStats(context.read<AuthController>().token ?? ''));

    if (_songStats.isEmpty) {
      return _emptyWidget('No downloads recorded yet.', Icons.music_note_outlined);
    }

    final total = _songStats.fold<int>(0, (sum, s) => sum + (s['download_count'] as int));

    return RefreshIndicator(
      color: nupeBlue,
      onRefresh: () => _fetchSongStats(context.read<AuthController>().token ?? ''),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(
            card: card, text: text, sub: sub,
            icon: Icons.music_note_rounded,
            colour: nupeGreen,
            label: 'Most Downloaded',
            value: _songStats.isNotEmpty ? _songStats.first['title'] ?? '—' : '—',
            extra: '${_songStats.length} songs downloaded',
          ),
          const SizedBox(height: 16),
          Text('Songs by Downloads', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ..._songStats.asMap().entries.map((entry) {
            final rank  = entry.key + 1;
            final s     = entry.value;
            final count = s['download_count'] as int;
            final pct   = total > 0 ? count / total : 0.0;
            return _songCard(card: card, text: text, sub: sub, rank: rank, s: s, count: count, pct: pct, isDark: isDark);
          }),
        ],
      ),
    );
  }

  Widget _songCard({
    required Color card, required Color text, required Color sub,
    required int rank, required Map<String, dynamic> s,
    required int count, required double pct, required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [nupeBlue.withValues(alpha: 0.8), nupeGreen.withValues(alpha: 0.8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['title'] ?? '—', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(s['artist'] ?? 'Unknown Artist', style: TextStyle(color: sub, fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(nupeBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count', style: TextStyle(color: nupeBlue, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('↓', style: TextStyle(color: sub, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────
  Widget _summaryCard({
    required Color card, required Color text, required Color sub,
    required IconData icon, required Color colour,
    required String label, required String value, required String extra,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colour.withValues(alpha: 0.85), colour.withValues(alpha: 0.5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(extra, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingWidget() => const Center(
    child: CircularProgressIndicator(color: nupeBlue),
  );

  Widget _errorWidget(String msg, VoidCallback retry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: nupeBlue, foregroundColor: Colors.white),
          ),
        ],
      ),
    ),
  );

  Widget _emptyWidget(String msg, IconData icon) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(color: Colors.grey.shade500)),
      ],
    ),
  );
}
