import 'dart:convert';
import 'dart:typed_data'; // buat Web upload file
import 'dart:io' show File; // hanya ambil File (biar aman di Web)
import 'package:flutter/foundation.dart'; // kIsWeb
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enum untuk role user
enum UserRole { netizen, admin }

class ApiService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final String baseUrl;

  ApiService() {
    if (kIsWeb) {
      baseUrl = "http://localhost:8000/api"; // Web/desktop
    } else {
      try {
        if (Platform.isAndroid) {
          baseUrl = "http://10.0.2.2:8000/api"; // Android Emulator
        } else if (Platform.isIOS) {
          baseUrl = "http://localhost:8000/api"; // iOS Simulator
        } else {
          baseUrl = "http://localhost:8000/api"; // fallback
        }
      } catch (_) {
        baseUrl = "http://localhost:8000/api"; // default kalau gagal deteksi
      }
    }
  }

  /// ================== TOKEN HANDLING ==================
  String _getKey(UserRole role) =>
      role == UserRole.admin ? "token_admin" : "token_netizen";

  Future<String?> getToken([UserRole role = UserRole.netizen]) async {
    final token = await storage.read(key: "access_token");
    if (token != null && token.isNotEmpty) return token;
    return await storage.read(key: _getKey(role));
  }

  Future<void> saveToken(String token, {UserRole role = UserRole.netizen, String? roleName}) async {
    await storage.write(key: "access_token", value: token);
    await storage.write(key: _getKey(role), value: token);
    if (roleName != null) {
      await storage.write(key: "user_role", value: roleName);
    } else {
      await storage.write(
        key: "user_role",
        value: role == UserRole.admin ? "admin" : "netizen",
      );
    }
  }

  Future<void> clearToken([UserRole role = UserRole.netizen]) async {
    await storage.delete(key: "access_token");
    await storage.delete(key: "user_role");
    await storage.delete(key: "token_netizen");
    await storage.delete(key: "token_admin");
  }

  Future<void> logout([UserRole role = UserRole.netizen]) async =>
      await clearToken(role);

  /// Helper untuk merubah path gambar relatif dari server menjadi URL lengkap
  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http://") || path.startsWith("https://")) {
      return path;
    }
    final hostBase = baseUrl.endsWith("/api")
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    final cleanPath = path.startsWith("/") ? path : "/$path";
    return "$hostBase$cleanPath";
  }


  /// ================== HELPER ==================
  Future<Map<String, String>> _headers(
      [UserRole role = UserRole.netizen, bool isJson = true]) async {
    final token = await getToken(role);
    return {
      if (isJson) "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Uri _uri(String endpoint) =>
      Uri.parse(endpoint.startsWith("http") ? endpoint : "$baseUrl/$endpoint");

  /// URL WebSocket untuk live hasil topik (dari baseUrl HTTP → ws).
  String wsUrl(int topicId) {
    final raw = baseUrl.endsWith("/api") ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;
    final wsBase = raw.startsWith("https")
        ? raw.replaceFirst("https", "wss")
        : raw.replaceFirst("http", "ws");
    return "$wsBase/ws/votes/$topicId/";
  }

  /// ================== HTTP METHODS ==================
  Future<http.Response> get(String endpoint,
      [UserRole role = UserRole.netizen]) async {
    try {
      return await http.get(
        _uri(endpoint),
        headers: await _headers(role),
      );
    } catch (e) {
      return http.Response(jsonEncode({"error": e.toString()}), 500);
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data,
      [UserRole role = UserRole.netizen]) async {
    try {
      return await http.post(
        _uri(endpoint),
        headers: await _headers(role),
        body: jsonEncode(data),
      );
    } catch (e) {
      return http.Response(jsonEncode({"error": e.toString()}), 500);
    }
  }

  Future<http.Response> patchJson(String endpoint, Map<String, dynamic> data,
      [UserRole role = UserRole.netizen]) async {
    try {
      return await http.patch(
        _uri(endpoint),
        headers: await _headers(role),
        body: jsonEncode(data),
      );
    } catch (e) {
      return http.Response(jsonEncode({"error": e.toString()}), 500);
    }
  }

  Future<http.Response> delete(String endpoint,
      [UserRole role = UserRole.netizen]) async {
    try {
      return await http.delete(
        _uri(endpoint),
        headers: await _headers(role),
      );
    } catch (e) {
      return http.Response(jsonEncode({"error": e.toString()}), 500);
    }
  }

  /// ================== MULTIPART (POST & PATCH) ==================
  Future<http.Response> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    File? file,
    String fileField = "file",
    Uint8List? webFileBytes,
    String? webFilename,
    UserRole role = UserRole.netizen,
  }) async {
    try {
      final request = http.MultipartRequest("POST", _uri(endpoint));

      final token = await getToken(role);
      if (token != null) {
        request.headers['Authorization'] = "Bearer $token";
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (!kIsWeb && file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      if (kIsWeb && webFileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          webFileBytes,
          filename: webFilename ?? "upload.jpg",
        ));
      }

      final streamed = await request.send();
      return await http.Response.fromStream(streamed);
    } catch (e) {
      return http.Response(jsonEncode({"error": e.toString()}), 500);
    }
  }

  Future<http.Response> patchMultipart(
    String endpoint, {
    Map<String, File>? files,
    Map<String, String>? fields,
    Uint8List? webFileBytes,
    String? webFilename,
    UserRole role = UserRole.netizen,
  }) async {
    try {
      final request = http.MultipartRequest("PATCH", _uri(endpoint));

      final token = await getToken(role);
      if (token != null) {
        request.headers['Authorization'] = "Bearer $token";
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (!kIsWeb && files != null) {
        for (var entry in files.entries) {
          request.files.add(await http.MultipartFile.fromPath(
            entry.key,
            entry.value.path,
          ));
        }
      }

      if (kIsWeb && webFileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          "file",
          webFileBytes,
          filename: webFilename ?? "upload.jpg",
        ));
      }

      final streamed = await request.send();
      return await http.Response.fromStream(streamed);
    } catch (e) {
      return http.Response(jsonEncode({"error": e.toString()}), 500);
    }
  }
}
