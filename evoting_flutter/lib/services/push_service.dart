import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';

/// Inisialisasi FCM push & daftarkan token Firebase ke backend.
/// Di-skip bila Firebase belum dikonfigurasi pada project (google-services.json /
/// GoogleService-Info.plist absen) → app tetap berfungsi (broadcast in-app saja).
Future<void> initPushNotifications() async {
  if (kIsWeb) return; // konfigurasi FCM web terpisah; lewati sekarang.
  try {
    final FirebaseMessaging fm = FirebaseMessaging.instance;
    final token = await fm.getToken();
    if (token != null && token.isNotEmpty) {
      await ApiService().post("users/fcm/", {"token": token});
    }
  } catch (_) {
    // Firebase belum di-setup → abaikan, tanpa crash.
  }
}