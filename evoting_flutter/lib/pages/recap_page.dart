import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
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
    final res = await api.get("votes/recap/");
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
      "votes/recap/verify/",
      {
        "signature": data!['signature'],
        "public_key": data!['public_key'],
        "data": data!['data'],
      },
    );
    if (mounted) {
      setState(() {
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          verifyResult = body['valid'] == true;
        } else {
          verifyResult = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Resmi (Sirekap/Ci.Cii)"),
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
                    const Divider(height: 30),
                    ..._calls(),
                  ],
                ),
    );
  }

  Widget _verifyCard() {
    final v = verifyResult;
    return Card(
      color: v == null ? Colors.grey.shade100 : (v! ? Colors.green.shade50 : Colors.red.shade50),
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
        subtitle: Text("Tap ikon ✓ / tombol untuk verifikasi."),
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
            const Text("Algoritma: Ed25519", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Manifest: ${_short(data?['manifest_hash'] ?? '')}"),
            Text("Sign: ${_short(data?['signature'] ?? '')}"),
          ],
        ),
      ),
    );
  }

  List<Widget> _calls() {
    final elections = data?['data']?['elections'] as List<dynamic>? ?? [];
    return elections.map<Widget>((e) {
      final totals = e['totals'] as Map<String, dynamic>? ?? {};
      final totalVotes = totals['total_votes'] ?? 0;
      final registered = totals['total_registered'];
      final part = totals['participation_percent'];
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          leading: const Icon(Icons.how_to_vote, color: Colors.indigo),
          title: Text(e['election_name'] ?? 'Periode'),
          subtitle: Text(
            "Suara: $totalVotes${registered != null ? ' / DPT: $registered' : ''}"
            "${part != null ? ' | Partisipasi: ${part.toStringAsFixed(1)}%' : ''}",
          ),
          children: [
            ..._candidates(totals['candidates'] as List<dynamic>? ?? []),
            if ((e['regions'] as List<dynamic>? ?? []).isNotEmpty) ...[
              const Divider(),
              ...(e['regions'] as List<dynamic>!).map<Widget>((r) {
                return ListTile(
                  dense: true,
                  title: Text("${r['region_name']} — ${r['total_votes']} suara"),
                  subtitle: Text(
                    "${r['total_registered'] ?? 0} DPT | Partisipasi: "
                    "${r['participation_percent']?.toStringAsFixed(1) ?? '-'}%",
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _candidates(List<dynamic> candidates) {
    return candidates
        .map<Widget>((c) => ListTile(
              dense: true,
              leading: const Icon(Icons.person, size: 18),
              title: Text(c['candidate_name'] ?? 'Kandidat'),
              trailing: Text("${c['votes'] ?? 0}"),
            ))
        .toList();
  }

  String _short(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.length > 24 ? '${s.substring(0, 24)}...' : s;
  }
}