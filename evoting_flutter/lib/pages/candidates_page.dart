import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/topic.dart';
import '../models/candidate.dart';

class CandidatesPage extends StatefulWidget {
  final Topic topic;
  const CandidatesPage({super.key, required this.topic});

  @override
  State<CandidatesPage> createState() => _CandidatesPageState();
}

class _CandidatesPageState extends State<CandidatesPage> {
  final api = ApiService();
  List<Candidate> candidates = [];

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  void fetchCandidates() async {
    final res = await api.get("candidates/?topic=${widget.topic.id}");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      setState(() {
        candidates = data.map((e) => Candidate.fromJson(e)).toList();
      });
    }
  }

  void voteCandidate(int candidateId) async {
    final res = await api.post("votes/", {
      "user": 1, // 🔹 sementara hardcoded, nanti ambil dari storage JWT
      "topic": widget.topic.id,
      "candidate": candidateId,
    });

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vote berhasil!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal vote: ${res.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kandidat: ${widget.topic.title}")),
      body: candidates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, i) {
                final c = candidates[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(c.photo),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.bio),
                    trailing: ElevatedButton(
                      onPressed: () => voteCandidate(c.id),
                      child: const Text("Vote"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
