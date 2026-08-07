import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'public_results_page.dart';
import 'public_recap_page.dart';

/// V7-C: Papan publik — daftar periode & topik tanpa login.
/// Dibuka via link `?hub=1` (web) atau menu publik.
class PublicHubPage extends StatefulWidget {
  const PublicHubPage({super.key});

  @override
  State<PublicHubPage> createState() => _PublicHubPageState();
}

class _PublicHubPageState extends State<PublicHubPage> {
  final api = ApiService();
  List<dynamic> periods = [];
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
      final res = await api.getPublic("votes/public/hub/");
      if (res.statusCode == 200) {
        setState(() {
          periods = jsonDecode(res.body)['periods'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Gagal memuat data publik.";
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
        title: const Text("Hasil Publik & Arsip 🏛️"),
        backgroundColor: Colors.indigo,
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
                    Card(
                      color: Colors.indigo.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.verified, color: Colors.indigo),
                        title: const Text("Rekap & Verifikasi (tanpa login)"),
                        subtitle: const Text("Lihat rekap resmi & cek tanda tangan"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PublicRecapPage()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...periods.map<Widget>((p) => _periodCard(p)),
                    if (periods.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text("Belum ada periode pemilihan.")),
                      ),
                  ],
                ),
    );
  }

  Widget _periodCard(Map<String, dynamic> p) {
    final status = p['status']?.toString() ?? "";
    final topics = (p['topics'] as List<dynamic>? ?? []) as List<dynamic>;
    final Color statusColor = status == 'ongoing'
        ? Colors.green
        : (status == 'upcoming' ? Colors.orange : Colors.grey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(status == 'ongoing' ? Icons.how_to_vote : Icons.event_note,
            color: statusColor),
        title: Text(p['name'] ?? "Periode",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${_statusLabel(status)} · DPT: ${p['dpt'] ?? 0} · Suara: ${p['total_votes'] ?? 0}",
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
        children: [
          ...topics.map<Widget>((t) => ListTile(
                dense: true,
                leading: const Icon(Icons.topic, size: 18),
                title: Text(t['title'] ?? "Topik"),
                subtitle: Text("${t['total_votes'] ?? 0} suara"),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicResultsPage(topicId: t['topic_id'] as int),
                  ),
                ),
              )),
          if (topics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Belum ada topik pada periode ini."),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'ongoing':
        return "Berlangsung";
      case 'upcoming':
        return "Akan datang";
      default:
        return "Selesai";
    }
  }
}