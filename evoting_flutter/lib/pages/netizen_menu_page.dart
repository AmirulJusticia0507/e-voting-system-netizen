import 'package:flutter/material.dart';

class NetizenMenuPage extends StatelessWidget {
  const NetizenMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {"title": "Dashboard", "icon": Icons.dashboard, "color": Colors.blue, "route": "/dashboard"},
      {"title": "Voting", "icon": Icons.how_to_vote, "color": Colors.purple, "route": "/voting"},
      {"title": "Komentar", "icon": Icons.comment, "color": Colors.teal, "route": "/comments"},
      {"title": "Profil", "icon": Icons.person, "color": Colors.orange, "route": "/profile"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Netizen"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
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
                      (item["color"] as Color).withOpacity(0.8),
                      (item["color"] as Color).withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item["icon"] as IconData, size: 50, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        item["title"] as String,
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
          },
        ),
      ),
    );
  }
}
