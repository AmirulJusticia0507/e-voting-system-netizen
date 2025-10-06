import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

// Pages
import 'pages/login_page.dart';
import 'pages/netizen_signup_page.dart';
import 'pages/home_page.dart';
import 'pages/voting_page.dart';
import 'pages/results_page.dart';
import 'pages/topics_page.dart';
import 'pages/candidates_page.dart';
import 'pages/comments_page.dart';
import 'pages/profile_page.dart';
import 'pages/netizen_menu_page.dart'; // ✅ penting

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AuthGate(),
      routes: {
        '/login': (context) => LoginPage(
              onSignupTap: () =>
                  Navigator.pushNamed(context, '/signup'), // ✅ default
            ),
        '/signup': (context) => const NetizenSignupPage(),
        '/home': (context) => const HomePage(),
        '/voting': (context) => VotingPage(),
        '/results': (context) => const ResultsPage(),
        '/topics': (context) => const TopicsPage(),
        '/profile': (context) => const ProfilePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/candidates':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CandidatesPage(
                topicId: args['topicId'] as int,
                topicTitle: args['topicTitle'] as String,
              ),
            );
          case '/comments':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CommentsPage(
                topicId: args['topicId'] as int,
                topicTitle: args['topicTitle'] as String,
              ),
            );
          default:
            return null;
        }
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
  String? _role; // <- simpan role: "admin" / "netizen"

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await storage.read(key: "access_token");
    final role = await storage.read(key: "user_role"); // ✅ simpan role di storage

    if (token != null) {
      if (!kIsWeb) {
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
                _role = role;
                _loading = false;
              });
              return;
            }
          }
        } catch (e) {
          debugPrint("Biometric error: $e");
        }
      }

      // fallback → token valid meski biometric gagal
      setState(() {
        _isAuthenticated = true;
        _role = role;
        _loading = false;
      });
      return;
    }

    // Tidak ada token
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

    if (_isAuthenticated) {
      // ✅ bedakan halaman berdasarkan role
      if (_role == "admin") {
        return const HomePage();
      } else {
        return const NetizenMenuPage();
      }
    }

    // Fallback ke login
    return LoginPage(
      onSignupTap: () => Navigator.pushNamed(context, '/signup'),
    );
  }
}
