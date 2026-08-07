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
import 'pages/admin_manage_pages.dart';
import 'pages/roles_manage_pages.dart';
import 'pages/election_manage_pages.dart';
import 'pages/live_results_page.dart';
import 'pages/recap_page.dart';
import 'pages/audit_page.dart';
import 'pages/public_results_page.dart';
import 'pages/qr_scan_page.dart';
import 'pages/region_battle_page.dart';
import 'pages/gamification_page.dart';
import 'pages/public_hub_page.dart';
import 'pages/public_recap_page.dart';

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
      home: const RootGate(),
      routes: {
        '/login': (context) => LoginPage(
              onSignupTap: () => Navigator.pushNamed(context, '/signup'),
            ),
        '/signup': (context) => const NetizenSignupPage(),
        '/home': (context) => const HomePage(),
        '/dashboard': (context) => const NetizenMenuPage(),
        '/voting': (context) => VotingPage(),
        '/results': (context) => const ResultsPage(),
        '/live_results': (context) => const LiveResultsPage(),
        '/recap': (context) => const RecapPage(),
        '/audit': (context) => const AuditPage(),
        '/qr_scan': (context) => const QRScanPage(),
        '/region_battle': (context) => const RegionBattlePage(),
        '/gamification': (context) => const GamificationPage(),
        '/public_hub': (context) => const PublicHubPage(),
        '/public_recap': (context) => const PublicRecapPage(),
        '/public_results': (context) => const _PublicResultsRedirect(),
        '/topics': (context) => const TopicsPage(),
        '/profile': (context) => const ProfilePage(),
        '/manage_users': (context) => const ManageUsersPage(),
        '/manage_topics': (context) => const ManageTopicsPage(),
        '/manage_candidates': (context) => const ManageCandidatesPage(),
        '/manage_votes': (context) => const ManageVotesPage(),
        '/manage_comments': (context) => const ManageCommentsPage(),
        '/manage_roles': (context) => const ManageRolesPage(),
        '/manage_elections': (context) => const ManageElectionsPage(),
        '/manage_regions': (context) => const ManageRegionsPage(),
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

/// Gerbang masuk: jika URL punya `?v=<topic_id>` (dibuka dari link share/QR),
/// langsung tampilkan hasil publik tanpa login. Selain itu jalankan AuthGate biasa.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final q = Uri.base.queryParameters;
      if (q.containsKey('hub')) return const PublicHubPage();
      if (q.containsKey('recap')) return const PublicRecapPage();
      final v = q['v'];
      if (v != null) {
        final id = int.tryParse(v);
        if (id != null) return PublicResultsPage(topicId: id);
      }
    }
    return const AuthGate();
  }
}

/// Untuk rute '/public_results' (fallback, dipakai saat tombol back dari QR).
class _PublicResultsRedirect extends StatelessWidget {
  const _PublicResultsRedirect();

  @override
  Widget build(BuildContext context) {
    final v = Uri.base.queryParameters['v'];
    final id = int.tryParse(v ?? "");
    if (id != null) return PublicResultsPage(topicId: id);
    return const Scaffold(body: Center(child: Text("Topik tidak ditemukan.")));
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
