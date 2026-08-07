import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// V7-B3: Gamification — poin, streak, badge, papan peringkat.
class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  final api = ApiService();
  Map<String, dynamic>? me;
  List<dynamic> board = [];
  Map<String, dynamic> badgesMeta = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);
    try {
      final res = await api.get("users/gamification/");
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          me = body['me'];
          board = (body['leaderboard'] as List<dynamic>? ?? []) as List<dynamic>;
          badgesMeta =
              (body['badges_meta'] as Map<String, dynamic>? ?? {}) as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Gagal memuat gamification.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gamification 🎮"),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetch),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _meCard(),
                    const SizedBox(height: 16),
                    _sectionTitle("Badge Saya 🎖️"),
                    const SizedBox(height: 4),
                    _badges(),
                    const SizedBox(height: 16),
                    _sectionTitle("Papan Peringkat 🏆"),
                    const SizedBox(height: 4),
                    ...board.asMap().entries.map((e) => _boardRow(e.key, e.value)),
                  ],
                ),
    );
  }

  Widget _meCard() {
    final streak = me?['vote_streak'] ?? 0;
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.whatshot, size: 48, color: Colors.orange.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${me?['points'] ?? 0} Poin",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("🔥 Streak: ${streak} hari | Ranking: #${me?['rank'] ?? '-'}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));

  Widget _badges() {
    final owned = (me?['badges'] as List<dynamic>? ?? []) as List<dynamic>;
    if (owned.isEmpty) {
      return const Text("Belum ada badge. Ikut voting untuk mendapatkannya! 🗳️");
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: owned.map<Widget>((code) {
        final meta = badgesMeta[code] as Map<String, dynamic>? ?? {};
        return Chip(
          avatar: Text(meta['icon']?.toString() ?? "🎖️"),
          label: Text(meta['label']?.toString() ?? code.toString()),
          backgroundColor: Colors.orange.shade50,
        );
      }).toList(),
    );
  }

  Widget _boardRow(int rank, dynamic u) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: rank == 0
              ? Colors.amber
              : (rank == 1 ? Colors.grey.shade300 : Colors.brown.shade100),
          child: Text("${rank + 1}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(u['username']?.toString() ?? "Pemilih"),
        subtitle: Text("🔥 ${u['vote_streak'] ?? 0} | ${(u['badges'] ?? []).length} badge"),
        trailing: Text("${u['points'] ?? 0} pts",
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}