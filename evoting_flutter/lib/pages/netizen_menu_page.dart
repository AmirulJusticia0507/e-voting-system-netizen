import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NetizenMenuPage extends StatefulWidget {
  const NetizenMenuPage({super.key});

  @override
  State<NetizenMenuPage> createState() => _NetizenMenuPageState();
}

class _NetizenMenuPageState extends State<NetizenMenuPage> {
  final api = ApiService();

  final List<Map<String, dynamic>> menuItems = [
    {"title": "Topik Voting", "icon": Icons.topic, "color": Colors.blue, "route": "/topics"},
    {"title": "Mulai Voting", "icon": Icons.how_to_vote, "color": Colors.purple, "route": "/voting"},
    {"title": "Hasil Voting", "icon": Icons.bar_chart, "color": Colors.teal, "route": "/results"},
    {"title": "Profil Saya", "icon": Icons.person, "color": Colors.orange, "route": "/profile"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Netizen"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              await api.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Padding(
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
            return InkWell(
              onTap: () => Navigator.pushNamed(context, item["route"] as String),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (item["color"] as Color).withOpacity(0.85),
                      (item["color"] as Color).withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (item["color"] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item["icon"] as IconData, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        item["title"] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
