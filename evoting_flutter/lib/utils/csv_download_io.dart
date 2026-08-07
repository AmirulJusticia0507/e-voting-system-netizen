import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Implementasi non-web: simpan file CSV ke direktori dokumen.
Future<String?> download(String filename, String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
  return file.path;
}