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
  int? votedCandidateId;
  bool hasVotedTopic = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final resCand = await api.get("candidates/?topic=${widget.topicId}");
      if (resCand.statusCode == 200) {
        final data = jsonDecode(resCand.body) as List;
        candidates = data.map((e) => Candidate.fromJson(e)).toList();
      }

      // Check current user votes
      final resUser = await api.get("users/me/");
      if (resUser.statusCode == 200) {
        final userData = jsonDecode(resUser.body);
        final userId = userData['id'];
        final resVotes = await api.get("votes/?user=$userId");
        if (resVotes.statusCode == 200) {
          final List votes = jsonDecode(resVotes.body);
          final userTopicVote = votes.firstWhere(
            (v) => (v['topic'] is int ? v['topic'] : v['topic']?['id']) == widget.topicId,
            orElse: () => null,
          );
          if (userTopicVote != null) {
            hasVotedTopic = true;
            votedCandidateId = userTopicVote['candidate'] is int
                ? userTopicVote['candidate']
                : userTopicVote['candidate']?['id'];
          } else {
            hasVotedTopic = false;
            votedCandidateId = null;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> voteCandidate(int candidateId) async {
    if (hasVotedTopic) return;
    setState(() => actionLoading = true);
    try {
      final res = await api.post("votes/", {
        "topic": widget.topicId,
        "candidate": candidateId,
      });

      if (res.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vote berhasil! 🎉 Bukti voting telah dikirim ke WhatsApp Anda.")),
        );

        fetchData();
      } else {
        String errMsg = "Gagal vote";
        try {
          final data = jsonDecode(res.body);
          if (data is List && data.isNotEmpty) errMsg = data[0].toString();
          if (data is Map && data["detail"] != null) errMsg = data["detail"];
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error vote: $e")),
      );
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> likeCandidate(int candidateId) async {
    setState(() => actionLoading = true);
    try {
      final res = await api.post("candidates/$candidateId/like/", {});
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Liked 👍")),
        );
        fetchData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error like: $e")),
      );
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> dislikeCandidate(int candidateId) async {
    setState(() => actionLoading = true);
    try {
      final res = await api.post("candidates/$candidateId/dislike/", {});
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Disliked 👎")),
        );
        fetchData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error dislike: $e")),
      );
    } finally {
      if (mounted) setState(() => actionLoading = false);
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
                    final isMyVotedCandidate = (c.id == votedCandidateId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isMyVotedCandidate
                            ? const BorderSide(color: Colors.green, width: 2)
                            : BorderSide.none,
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (isMyVotedCandidate)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                "Voted ✓",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
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
                            const SizedBox(height: 12),
                            // 📊 Survey Keunggulan Persentase
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Survei Keunggulan:",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                ),
                                Text(
                                  "${c.votePercentage}% (${c.voteCount} Suara)",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (c.votePercentage / 100).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isMyVotedCandidate ? Colors.green : Colors.deepPurple,
                                ),
                              ),
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
                                    backgroundColor: isMyVotedCandidate
                                        ? Colors.green
                                        : (hasVotedTopic ? Colors.grey : Colors.deepPurple),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(
                                    isMyVotedCandidate ? Icons.check_circle : Icons.how_to_vote,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isMyVotedCandidate
                                        ? "Pilihan Anda"
                                        : (hasVotedTopic ? "Sudah Vote" : "Vote"),
                                  ),
                                  onPressed: (actionLoading || hasVotedTopic) ? null : () => voteCandidate(c.id),
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


