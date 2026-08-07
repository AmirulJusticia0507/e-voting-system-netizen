import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

/// Implementasi web: memicu download via anchor blob + URL.createObjectURL.
Future<String?> download(String filename, String content) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([Uint8List.fromList(bytes)], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
  return null;
}