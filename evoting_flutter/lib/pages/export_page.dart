import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/csv_download.dart' as csv;

/// Final batch: Ekspor CSV — hasil, riwayat suara, log audit (admin).
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final api = ApiService();
  bool _busy = false;

  Future<void> _export(String endpoint, String filename) async {
    setState(() => _busy = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Mengunduh $filename...")),
    );
    final res = await api.get(endpoint, UserRole.admin);
    if (res.statusCode == 200) {
      final path = await csv.downloadText(filename, res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null
                ? "Tersimpan: $path"
                : "Download $filename dimulai di browser."),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ekspor (${res.statusCode})")),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ekspor Data (CSV)"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Unduh data dalam format CSV (bisa dibuka di Excel)."),
          const SizedBox(height: 20),
          _exportCard(
            icon: Icons.bar_chart,
            title: "Hasil per Kandidat",
            subtitle: "Ringkasan jumlah suara per kandidat per topik",
            onTap: () => _export("votes/export_results/", "hasil.csv"),
          ),
          _exportCard(
            icon: Icons.how_to_vote,
            title: "Riwayat Suara",
            subtitle: "Daftar lengkap setiap pemilih & pilihannya",
            onTap: () => _export("votes/export_votes/", "riwayat_suara.csv"),
          ),
          _exportCard(
            icon: Icons.security,
            title: "Log Audit",
            subtitle: "Seluruh rantai audit aksi sistem",
            onTap: () => _export("votes/export_audit/", "audit_log.csv"),
          ),
          if (_busy) const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _exportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.download),
        onTap: onTap,
      ),
    );
  }
}