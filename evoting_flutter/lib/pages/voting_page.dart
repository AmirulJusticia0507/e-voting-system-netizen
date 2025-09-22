import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/candidate.dart';
import '../services/api_service.dart';

class VotingPage extends StatefulWidget {
  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  final api = ApiService();
  List<Candidate> candidates = [];

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  void fetchCandidates() async {
    final res = await api.get("candidates/");
    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      setState(() {
        candidates = data.map((c) => Candidate.fromJson(c)).toList();
      });
    }
  }

  void voteCandidate(int id) async {
    final res = await api.post("votes/", {
      "candidate": id,
      "topic": 1,
      "user": 1,
    });
    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vote berhasil!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal vote")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voting Page"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: candidates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: candidates.length,
              itemBuilder: (context, i) {
                final c = candidates[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            "http://10.0.2.2:8000${c.photo}",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(c.bio,
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => voteCandidate(c.id),
                          child: const Text("Vote"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
