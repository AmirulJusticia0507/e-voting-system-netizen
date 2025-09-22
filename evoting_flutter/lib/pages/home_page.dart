import 'package:flutter/material.dart';
import 'voting_page.dart';
import 'results_page.dart';
import '../widgets/custom_button.dart';

class HomePage extends StatelessWidget {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(
              text: "Mulai Voting",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VotingPage()),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Lihat Hasil",
              color: Colors.green,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ResultsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
