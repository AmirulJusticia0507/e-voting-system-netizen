import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final api = ApiService();
  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    final res = await api.get("users/me/"); // pastikan endpoint ini ada
    if (res.statusCode == 200) {
      setState(() {
        user = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal load user: ${res.body}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isSuperadmin = (user?['is_staff'] == true || user?['is_superuser'] == true);

    // Daftar permission dari user (hasil /users/me/)
    final List<dynamic> perms = (user?['permission_codes'] ?? []) as List<dynamic>;
    List<String> perm = perms.map((e) => e.toString()).toList();
    bool has(String code) => isSuperadmin ? true : perm.contains(code);

    // Menu khusus netizen (voter)
    final netizenMenu = [
      {"title": "Mulai Voting", "icon": Icons.how_to_vote, "color": Colors.deepPurple, "route": "/voting"},
      {"title": "Lihat Hasil", "icon": Icons.bar_chart, "color": Colors.green, "route": "/results"},
      {"title": "Hasil Realtime", "icon": Icons.sensors, "color": Colors.cyan, "route": "/live_results"},
      {"title": "Rekap Resmi", "icon": Icons.verified, "color": Colors.indigo, "route": "/recap"},
      {"title": "Scan QR Hasil", "icon": Icons.qr_code_scanner, "color": Colors.teal, "route": "/qr_scan"},
      {"title": "Region Battle", "icon": Icons.emoji_events, "color": Colors.deepOrange, "route": "/region_battle"},
      {"title": "Game & Poin", "icon": Icons.sports_esports, "color": Colors.amber, "route": "/gamification"},
      {"title": "Papan Publik & Arsip", "icon": Icons.storefront, "color": Colors.indigo, "route": "/public_hub"},
      {"title": "Audit Trust", "icon": Icons.security, "color": Colors.lightBlue, "route": "/audit"},
      {"title": "Lihat Topik", "icon": Icons.topic, "color": Colors.blue, "route": "/topics"},
      {"title": "Profil Saya", "icon": Icons.person, "color": Colors.orange, "route": "/profile"},
    ];

    // Menu admin berbasis permission
    final adminMenu = <Map<String, dynamic>>[
      if (has("manage_users")) {"title": "Kelola User", "icon": Icons.people, "color": Colors.red, "route": "/manage_users"},
      if (has("manage_topics")) {"title": "Kelola Topik", "icon": Icons.topic, "color": Colors.blue, "route": "/manage_topics"},
      if (has("manage_candidates")) {"title": "Kelola Kandidat", "icon": Icons.person_pin, "color": Colors.teal, "route": "/manage_candidates"},
      if (has("manage_votes")) {"title": "Kelola Votes", "icon": Icons.how_to_vote, "color": Colors.purple, "route": "/manage_votes"},
      if (has("manage_comments")) {"title": "Kelola Komentar", "icon": Icons.comment, "color": Colors.indigo, "route": "/manage_comments"},
      if (has("manage_roles")) {"title": "Kelola Role & Izin", "icon": Icons.admin_panel_settings, "color": Colors.brown, "route": "/manage_roles"},
      if (has("manage_elections")) {"title": "Kelola Pemilihan", "icon": Icons.event_note, "color": Colors.deepOrange, "route": "/manage_elections"},
      if (has("manage_elections")) {"title": "Kelola Wilayah", "icon": Icons.map, "color": Colors.teal, "route": "/manage_regions"},
      {"title": "Audit Trust", "icon": Icons.security, "color": Colors.lightBlue, "route": "/audit"},
      {"title": "Profil Saya", "icon": Icons.person, "color": Colors.orange, "route": "/profile"},
    ];

    final menuItems = isSuperadmin ? adminMenu : netizenMenu;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSuperadmin ? "Admin Dashboard" : "E-Voting System"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await api.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e1e2f), Color(0xFF2a2a40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            itemCount: menuItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildMenuCard(
                context,
                item["title"] as String,
                item["icon"] as IconData,
                item["color"] as Color,
                item["route"] as String,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
