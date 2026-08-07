import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Audit Trail & Transparansi — menampilkan rantai audit (chain) + bukti
/// hasil ringkas (aggregate root hash) dari endpoint /api/audit/ dan
/// /api/votes/evidence/.
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final api = ApiService();
  bool isLoading = true;
  bool? chainValid;
  int totalLogs = 0;
  List<dynamic> logs = [];
  List<dynamic> evidence = [];

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);
    try {
      final chainRes = await api.get("audit/chain/");
      final evRes = await api.get("votes/evidence/");
      if (mounted) {
        setState(() {
          if (chainRes.statusCode == 200) {
            final body = jsonDecode(chainRes.body);
            chainValid = body['chain_valid'] == true;
            totalLogs = (body['total'] ?? 0) as int;
            logs = (body['logs'] as List<dynamic>? ?? []);
          }
          if (evRes.statusCode == 200) {
            final body = jsonDecode(evRes.body);
            evidence = (body['evidence'] as List<dynamic>? ?? []);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audit Trail & Transparansi"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetch),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _chainCard(),
                const SizedBox(height: 12),
                if (evidence.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      "Bukti Hasil Ringkas (aggregate root)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ..._evidence.map(_evCard),
                ],
                const Divider(height: 30),
                const Text(
                  "Riwayat Log Audit (recent)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._logCards(),
              ],
            ),
    );
  }

  Widget _chainCard() {
    return Card(
      color: chainValid == null
          ? Colors.grey.shade100
          : (chainValid! ? Colors.green.shade50 : Colors.red.shade50),
      child: ListTile(
        leading: Icon(
          chainValid == null
              ? Icons.verified_user
              : (chainValid! ? Icons.lock : Icons.lock_open),
          color: chainValid == null ? Colors.grey : (chainValid! ? Colors.green : Colors.red),
        ),
        title: Text(
          chainValid == null
              ? "Rantai audit belum diverifikasi"
              : (chainValid!
                  ? "Rantai audit VALID ✓ ($totalLogs entri)"
                  : "Rantai audit TERPUTUS ✗"),
        ),
        subtitle: const Text("Setiap entri dirunut dengan hash (blockchain-like)."),
      ),
    );
  }

  Widget _evCard(dynamic e) {
    final cands = (e['candidates'] as List<dynamic>? ?? []);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.how_to_vote, color: Colors.deepPurple),
        title: Text(e['topic_title'] ?? "Topik"),
        subtitle: Text("Total suara: ${e['total_votes'] ?? 0}"),
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.link, size: 18),
            title: Text("Root: ${_short(e['evidence_root'] ?? '')}"),
          ),
          ...cands.map<Widget>((c) => ListTile(
                dense: true,
                leading: const Icon(Icons.person, size: 18),
                title: Text(c['candidate_name'] ?? "Kandidat"),
                trailing: Text("${c['votes'] ?? 0}"),
              )),
        ],
      ),
    );
  }

  List<Widget> _logCards() {
    return logs.map<Widget>((l) {
      final ok = l['link_valid'] == true;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          dense: true,
          leading: Icon(
            ok ? Icons.link : Icons.broken_image,
            color: ok ? Colors.green : Colors.red,
          ),
          title: Text("${l['action'] ?? '??'} — #${l['id']}"),
          subtitle: Text(
            "${l['timestamp'] ?? ''}\n"
            "prev: ${_short(l['previous_hash'] ?? '')}\n"
            "hash: ${_short(l['integrity_hash'] ?? '')}",
          ),
          trailing: Text("${l['actor'] ?? '-'}"),
        ),
      );
    }).toList();
  }

  String _short(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.length > 24 ? '${s.substring(0, 24)}...' : s;
  }
}