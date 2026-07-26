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
        "topic": widget.topicId,
        "candidate": candidateId,
      });

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vote berhasil! 🎉")),
        );
        fetchCandidates();
      } else {
        String errMsg = "Gagal vote";
        try {
          final data = jsonDecode(res.body);
          if (data is List && data.isNotEmpty) errMsg = data[0].toString();
          if (data is Map && data["detail"] != null) errMsg = data["detail"];
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
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
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : candidates.isEmpty
              ? const Center(child: Text("Belum ada kandidat pada topik ini."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: candidates.length,
                  itemBuilder: (context, i) {
                    final c = candidates[i];
                    final photoUrl = api.getImageUrl(c.photo);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.deepPurple.shade100,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(Icons.person, size: 35, color: Colors.deepPurple)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.bio.isNotEmpty ? c.bio : "Kandidat E-Voting Netizen",
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.green[700]),
                                          const SizedBox(width: 4),
                                          Text("${c.likes}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 16),
                                          Icon(Icons.thumb_down_alt_outlined, size: 16, color: Colors.red[700]),
                                          const SizedBox(width: 4),
                                          Text("${c.dislikes}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.thumb_up),
                                      color: Colors.green,
                                      tooltip: "Like",
                                      onPressed: actionLoading ? null : () => likeCandidate(c.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.thumb_down),
                                      color: Colors.red,
                                      tooltip: "Dislike",
                                      onPressed: actionLoading ? null : () => dislikeCandidate(c.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.comment),
                                      color: Colors.blue,
                                      tooltip: "Komentar",
                                      onPressed: () => openComments(c.id, c.name),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.how_to_vote, size: 18),
                                  label: const Text("Vote"),
                                  onPressed: actionLoading ? null : () => voteCandidate(c.id),
                                ),
                              ],
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

