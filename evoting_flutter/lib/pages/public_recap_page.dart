import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// V7-C: Rekap publik + verifikasi tanda tangan (tanpa login).
/// Pakai endpoint /api/votes/public/recap/ & /recap/verify/.
class PublicRecapPage extends StatefulWidget {
  const PublicRecapPage({super.key});

  @override
  State<PublicRecapPage> createState() => _PublicRecapPageState();
}

class _PublicRecapPageState extends State<PublicRecapPage> {
  final api = ApiService();
  Map<String, dynamic>? data;
  bool isLoading = true;
  bool? verifyResult;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);
    final res = await api.getPublic("votes/public/recap/");
    if (mounted) {
      setState(() {
        if (res.statusCode == 200) data = jsonDecode(res.body);
        isLoading = false;
      });
    }
  }

  Future<void> verify() async {
    if (data == null) return;
    final res = await api.post(
      "votes/public/recap/verify/",
      {
        "data": data!['data'],
        "signature": data!['signature'],
        "public_key": data!['public_key'],
      },
    );
    if (mounted) {
      setState(() {
        verifyResult = (res.statusCode == 200 &&
            jsonDecode(res.body)['valid'] == true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Publik & Verifikasi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.verified), onPressed: verify),
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetch),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text("Gagal mengambil rekap."))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _verifyCard(),
                    const SizedBox(height: 12),
                    _signatureCard(),
                    const Divider(height: 24),
                    ..._elections(),
                  ],
                ),
    );
  }

  Widget _verifyCard() {
    final v = verifyResult;
    return Card(
      color: v == null
          ? Colors.grey.shade100
          : (v! ? Colors.green.shade50 : Colors.red.shade50),
      child: ListTile(
        leading: Icon(
          v == null ? Icons.verified_user : (v! ? Icons.check_circle : Icons.cancel),
          color: v == null ? Colors.grey : (v! ? Colors.green : Colors.red),
        ),
        title: Text(
          v == null
              ? "Tanda tangan belum diverifikasi"
              : (v! ? "Tanda tangan VALID ✓" : "Tanda tangan TIDAK VALID ✗"),
        ),
        subtitle: const Text("Tap ikon ✓ di pojok untuk verifikasi tanpa login."),
      ),
    );
  }

  Widget _signatureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Algoritma: Ed25519",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Manifest: ${_short(data?['manifest_hash'])}"),
            Text("Sign: ${_short(data?['signature'])}"),
            Text("PubKey: ${_short(data?['public_key'])}"),
          ],
        ),
      ),
    );
  }

  List<Widget> _elections() {
    final elections = data?['data']?['elections'] as List<dynamic>? ?? [];
    return elections.map<Widget>((e) {
      final totals = e['totals'] as Map<String, dynamic>? ?? {};
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          leading: const Icon(Icons.how_to_vote, color: Colors.indigo),
          title: Text(e['election_name'] ?? "Periode"),
          subtitle: Text("Suara: ${totals['total_votes'] ?? 0}"),
          children: [
            ...(totals['candidates'] as List<dynamic>? ?? []).map<Widget>((c) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.person, size: 18),
                title: Text(c['candidate_name'] ?? "Kandidat"),
                trailing: Text("${c['votes'] ?? 0}"),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  String _short(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.length > 30 ? '${s.substring(0, 30)}...' : s;
  }
}