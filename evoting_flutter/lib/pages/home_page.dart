import 'package:flutter/material.dart';
import 'voting_page.dart';
import 'results_page.dart';
import 'topics_page.dart';
import 'profile_page.dart';
import '../widgets/custom_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Voting Home"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                text: "Mulai Voting",
                onPressed: () => Navigator.pushNamed(context, '/voting'),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Lihat Hasil",
                color: Colors.green,
                onPressed: () => Navigator.pushNamed(context, '/results'),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Lihat Topik",
                color: Colors.blue,
                onPressed: () => Navigator.pushNamed(context, '/topics'),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Profil Saya",
                color: Colors.orange,
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
