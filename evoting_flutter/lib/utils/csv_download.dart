import 'package:flutter/foundation.dart' show kIsWeb;
import 'csv_download_io.dart' if (dart.library.html) 'csv_download_web.dart';

/// Unduh teks sebagai file (mis. CSV) lintas platform.
/// - Web: memicu download browser.
/// - Mobile/desktop: menyimpan ke direktori dokumen/Downloads.
/// Mengembalikan path file yang tersimpan (atau null di web).
Future<String?> downloadText(String filename, String content) {
  return download(filename, content);
}

// Catatan: `kIsWeb` diimpor agar analisis tidak salah platform.
bool get isWebDownload => kIsWeb;