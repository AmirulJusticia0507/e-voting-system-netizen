import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'public_results_page.dart';

/// Scanner QR untuk membuka halaman hasil publik dari pelayar link yang di-share.
/// Cocok identik: link share berbentuk `{public_base_url}/?v=<topic_id>`.
class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController _controller = MobileScannerController();

  int? _extractTopicId(String? raw) {
    if (raw == null) return null;
    if (raw.contains('v=')) {
      final q = raw.split('v=')[1].split('&').first;
      return int.tryParse(q);
    }
    // fallback: coba parse trailing number untuk /vote/<id>/
    final m = RegExp(r'(\d+)').firstMatch(raw);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final id = _extractTopicId(raw);
    if (id != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PublicResultsPage(topicId: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Bukti & Share"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (context, error) => Center(
          child: Text("Error: $error",
              style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}