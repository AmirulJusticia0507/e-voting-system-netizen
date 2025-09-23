import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  late final String baseUrl;

  ApiService() {
    if (kIsWeb) {
      // Untuk Flutter Web
      baseUrl = "http://localhost:8000/api";
    } else if (Platform.isAndroid) {
      // Untuk Android Emulator
      baseUrl = "http://10.0.2.2:8000/api";
    } else {
      // Untuk iOS Simulator / device
      baseUrl = "http://localhost:8000/api";
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: "token");
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: "token", value: token);
  }

  Future<void> clearToken() async {
    await storage.delete(key: "token");
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final token = await getToken();
    return await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
  }

  Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    return await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
  }
}
