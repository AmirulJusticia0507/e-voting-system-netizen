import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/topic_share_sheet.dart';

/// Halaman publik (bisa dibuka TANPA login) — untuk link share / QR.
/// Endpoint: /api/votes/public/<id>/ (AllowAny).
class PublicResultsPage extends StatefulWidget {
  final int topicId;
  const PublicResultsPage({super.key, required this.topicId});

  @override
  State<PublicResultsPage> createState() => _PublicResultsPageState();
}

class _PublicResultsPageState extends State<PublicResultsPage> {
  final api = ApiService();
  Map<String, dynamic>? data;
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
      final res = await api.getPublic("votes/public/${widget.topicId}/");
      if (res.statusCode == 200) {
        setState(() {
          data = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Topik tidak ditemukan.";
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
    final topic = data?['topic'] as Map<String, dynamic>?;
    final List<dynamic> candidates =
        (data?['candidates'] as List<dynamic>? ?? []) as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasil Voting Publik"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Bagikan",
            icon: const Icon(Icons.share),
            onPressed: () =>
                showShareSheet(context, widget.topicId, topicTitle: topic?['title']?.toString()),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetch),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(topic?['title'] ?? "Topik",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      "Total suara: ${data?['total_votes'] ?? 0}"
                      "${data?['participation'] != null ? ' | Partisipasi: ${(data!['participation'] as num).toStringAsFixed(1)}%' : ''}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    ..._rankings(candidates),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.deepPurple.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.link, color: Colors.deepPurple),
                        title: const Text("Bukti integritas (root hash)",
                            style: TextStyle(fontSize: 13)),
                        subtitle: Text(
                          _short(data?['evidence_root']?.toString()),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _rankings(List<dynamic> candidates) {
    final sorted = [...candidates]
      ..sort((a, b) => (b['votes'] ?? 0).compareTo(a['votes'] ?? 0));
    final maxVotes = sorted.isNotEmpty ? (sorted.first['votes'] ?? 0) : 0;
    return sorted.asMap().entries.map<Widget>((e) {
      final i = e.key;
      final c = e.value;
      final votes = c['votes'] ?? 0;
      final isLeader = i == 0 && votes > 0;
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isLeader
              ? const BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isLeader ? Colors.amber : Colors.deepPurple.shade100,
            child: Text("${i + 1}",
                style: TextStyle(
                    color: isLeader ? Colors.black87 : Colors.deepPurple,
                    fontWeight: FontWeight.bold)),
          ),
          title: Text(c['candidate_name'] ?? "Kandidat"),
          subtitle: LinearProgressIndicator(
            value: maxVotes == 0 ? 0 : (votes / maxVotes).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
                isLeader ? Colors.amber : Colors.deepPurple),
          ),
          trailing: Text("$votes",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }).toList();
  }

  String _short(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.length > 40 ? '${s.substring(0, 40)}...' : s;
  }
}