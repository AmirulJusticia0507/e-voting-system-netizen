import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// V7-B: Region Battle — leaderboard wilayah paling rame (partisipasi).
class RegionBattlePage extends StatefulWidget {
  const RegionBattlePage({super.key});

  @override
  State<RegionBattlePage> createState() => _RegionBattlePageState();
}

class _RegionBattlePageState extends State<RegionBattlePage> {
  final api = ApiService();
  List<dynamic> regions = [];
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
      final res = await api.get("votes/regions/");
      if (res.statusCode == 200) {
        setState(() {
          regions = jsonDecode(res.body)['regions'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Gagal memuat data wilayah.";
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
        title: const Text("Region Battle ⚔️"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetch),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : regions.isEmpty
                  ? const Center(child: Text("Belum ada data wilayah."))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          color: Colors.deepOrange.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Wilayah dengan partisipasi tertinggi — ayo ajak "
                              "tetangga satu wilayah agar jadi juara! 🏆",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...regions.asMap().entries.map((e) =>
                            _regionCard(e.key, e.value)),
                      ],
                    ),
    );
  }

  Widget _regionCard(int rank, Map<String, dynamic> r) {
    final dpt = r['dpt'] ?? 0;
    final votes = r['votes'] ?? 0;
    final part = (r['participation_percent'] as num?)?.toDouble() ?? 0;
    final isTop = rank == 0 && votes > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isTop ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTop ? Colors.amber : Colors.grey.shade200,
          child: Text("${rank + 1}",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isTop ? Colors.black87 : Colors.deepOrange)),
        ),
        title: Text(r['region_name'] ?? "Wilayah",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("DPT: $dpt | Suara masuk: $votes"),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: part / 100,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isTop ? Colors.amber : Colors.deepOrange),
            ),
          ],
        ),
        trailing: Text("${part.toStringAsFixed(1)}%",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}