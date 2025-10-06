import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/candidate.dart';
import 'comments_page.dart';

class CandidatesPage extends StatefulWidget {
  final int topicId;
  final String topicTitle;

  const CandidatesPage({super.key, required this.topicId, required this.topicTitle});

  @override
  State<CandidatesPage> createState() => _CandidatesPageState();
}

class _CandidatesPageState extends State<CandidatesPage> {
  final api = ApiService();
  List<Candidate> candidates = [];
  bool isLoading = true;
  bool actionLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  Future<void> fetchCandidates() async {
    setState(() => isLoading = true);
    try {
      final res = await api.get("candidates/?topic=${widget.topicId}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          candidates = data.map((e) => Candidate.fromJson(e)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ambil kandidat: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> voteCandidate(int candidateId) async {
    setState(() => actionLoading = true);
    try {
      final res = await api.post("votes/", {
        "user": 1, // 🔹 sementara hardcoded
        "topic": widget.topicId,
        "candidate": candidateId,
      });

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vote berhasil!")),
        );
        fetchCandidates();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal vote: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error vote: $e")),
      );
    } finally {
      setState(() => actionLoading = false);
    }
  }

  Future<void> likeCandidate(int candidateId) async {
    setState(() => actionLoading = true);
    try {
      final res = await api.post("candidates/$candidateId/like/", {});
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Liked 👍")),
        );
        fetchCandidates();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error like: $e")),
      );
    } finally {
      setState(() => actionLoading = false);
    }
  }

  Future<void> dislikeCandidate(int candidateId) async {
    setState(() => actionLoading = true);
    try {
      final res = await api.post("candidates/$candidateId/dislike/", {});
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Disliked 👎")),
        );
        fetchCandidates();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error dislike: $e")),
      );
    } finally {
      setState(() => actionLoading = false);
    }
  }

  void openComments(int candidateId, String candidateName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsPage(
          topicId: widget.topicId,
          topicTitle: "${widget.topicTitle} - $candidateName",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kandidat: ${widget.topicTitle}"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, i) {
                final c = candidates[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: c.photo != null && c.photo.isNotEmpty
                          ? NetworkImage(c.photo)
                          : null,
                      child: c.photo == null || c.photo.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(c.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.bio),
                        const SizedBox(height: 4),
                        Text("👍 ${c.likes}  |  👎 ${c.dislikes}"),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 160,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.thumb_up),
                            color: Colors.green,
                            onPressed: actionLoading ? null : () => likeCandidate(c.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.thumb_down),
                            color: Colors.red,
                            onPressed: actionLoading ? null : () => dislikeCandidate(c.id),
                          ),
                          ElevatedButton(
                            onPressed: actionLoading ? null : () => voteCandidate(c.id),
                            child: const Text("Vote"),
                          ),
                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () => openComments(c.id, c.name),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
