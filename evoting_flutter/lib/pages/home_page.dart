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

    final isSuperadmin = user?['is_superuser'] ?? false;

    // Menu khusus netizen
    final netizenMenu = [
      {"title": "Mulai Voting", "icon": Icons.how_to_vote, "color": Colors.deepPurple, "route": "/voting"},
      {"title": "Lihat Hasil", "icon": Icons.bar_chart, "color": Colors.green, "route": "/results"},
      {"title": "Lihat Topik", "icon": Icons.topic, "color": Colors.blue, "route": "/topics"},
      {"title": "Profil Saya", "icon": Icons.person, "color": Colors.orange, "route": "/profile"},
    ];

    // Menu khusus superadmin
    final adminMenu = [
      {"title": "Kelola User", "icon": Icons.people, "color": Colors.red, "route": "/manage_users"},
      {"title": "Kelola Topik", "icon": Icons.topic, "color": Colors.blue, "route": "/manage_topics"},
      {"title": "Kelola Kandidat", "icon": Icons.person_pin, "color": Colors.teal, "route": "/manage_candidates"},
      {"title": "Kelola Votes", "icon": Icons.how_to_vote, "color": Colors.purple, "route": "/manage_votes"},
      {"title": "Kelola Komentar", "icon": Icons.comment, "color": Colors.indigo, "route": "/manage_comments"},
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
