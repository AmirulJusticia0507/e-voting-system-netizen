import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

/// Helper untuk membuka panel "Bagikan / QR" hasil sebuah topik.
/// Memakai endpoint publik /api/votes/public/share/<id>/ sehingga link & QR
/// bisa dibuka siapa pun tanpa login.
Future<void> showShareSheet(BuildContext context, int topicId,
    {String? topicTitle}) async {
  final api = ApiService();
  Map<String, dynamic>? bundle;
  String? error;

  try {
    final res = await api.getPublic("votes/public/share/$topicId/");
    if (res.statusCode == 200) {
      bundle = jsonDecode(res.body);
    } else {
      error = "Gagal memuat data share (${res.statusCode}).";
    }
  } catch (e) {
    error = "Error: $e";
  }

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ShareSheet(
      bundle: bundle,
      error: error,
      topicTitle: topicTitle,
    ),
  );
}

class _ShareSheet extends StatelessWidget {
  final Map<String, dynamic>? bundle;
  final String? error;
  final String? topicTitle;

  const _ShareSheet({this.bundle, this.error, this.topicTitle});

  @override
  Widget build(BuildContext context) {
    final url = bundle?['share_url']?.toString() ?? "";
    final text = bundle?['share_text']?.toString() ??
        "🗳️ $topicTitle — lihat hasil votingnya!";

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text("Bagikan Hasil 🗳️",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red))
          else ...[
            // QR code
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.deepPurple.shade100),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: url,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(url.isEmpty
                  ? "Tidak ada link"
                  : "Scan QR / bagikan link agar bisa dilihat tanpa login",
                  style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 16),
            // preview text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(text, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Link & teks disalin")));
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Salin"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  onPressed: () => Share.share(text),
                  icon: const Icon(Icons.share),
                  label: const Text("Bagikan"),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}