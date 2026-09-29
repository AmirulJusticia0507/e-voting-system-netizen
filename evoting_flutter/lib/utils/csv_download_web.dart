import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Implementasi web: memicu download via anchor blob + URL.createObjectURL.
Future<String?> download(String filename, String content) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
  return null;
}
