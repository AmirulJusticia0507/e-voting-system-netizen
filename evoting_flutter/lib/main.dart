import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/voting_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Voting System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const AuthGate(), // 🚀 ganti initialRoute -> pakai AuthGate
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/voting': (context) => VotingPage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final storage = const FlutterSecureStorage();
  final auth = LocalAuthentication();

  bool _loading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // cek token di secure storage
    final token = await storage.read(key: "access_token");

    if (token != null) {
      // kalau ada token, coba fingerprint
      try {
        final canCheck = await auth.canCheckBiometrics;
        final isDeviceSupported = await auth.isDeviceSupported();

        if (canCheck && isDeviceSupported) {
          final didAuth = await auth.authenticate(
            localizedReason: "Gunakan sidik jari untuk masuk",
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          );
          if (didAuth) {
            setState(() {
              _isAuthenticated = true;
              _loading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint("Biometric error: $e");
      }
    }

    // kalau gagal -> arahkan ke login
    setState(() {
      _isAuthenticated = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isAuthenticated ? HomePage() : LoginPage();
  }
}
