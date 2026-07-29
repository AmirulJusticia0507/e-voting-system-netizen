import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/candidate.dart';
import '../models/topic.dart';
import '../services/api_service.dart';

class VotingPage extends StatefulWidget {
  final int? topicId;
  final String? topicTitle;

  const VotingPage({super.key, this.topicId, this.topicTitle});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  final api = ApiService();
  List<Topic> topics = [];
  List<Candidate> candidates = [];
  int? selectedTopicId;
  String? selectedTopicTitle;
  bool isLoading = true;
  bool actionLoading = false;
  int? votedCandidateId;
  bool hasVotedTopic = false;

  @override
  void initState() {
    super.initState();
    selectedTopicId = widget.topicId;
    selectedTopicTitle = widget.topicTitle;
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final resTopics = await api.get("topics/");
    if (resTopics.statusCode == 200) {
      final List data = jsonDecode(resTopics.body);
      topics = data.map((t) => Topic.fromJson(t)).toList();
      if (selectedTopicId == null && topics.isNotEmpty) {
        selectedTopicId = topics.first.id;
        selectedTopicTitle = topics.first.title;
      }
    }

    if (selectedTopicId != null) {
      await fetchCandidatesForTopic(selectedTopicId!);
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchCandidatesForTopic(int topicId) async {
    setState(() => isLoading = true);
    try {
      final res = await api.get("candidates/?topic=$topicId");
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        candidates = data.map((c) => Candidate.fromJson(c)).toList();
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
            (v) => (v['topic'] is int ? v['topic'] : v['topic']?['id']) == topicId,
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
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> voteCandidate(Candidate candidate) async {
    if (selectedTopicId == null || hasVotedTopic) return;
    setState(() => actionLoading = true);
    try {
      final res = await api.post("votes/", {
        "candidate": candidate.id,
        "topic": selectedTopicId,
      });

      if (res.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil vote untuk ${candidate.name}! 🎉 Bukti voting dikirim ke WhatsApp Anda.")),
        );
        fetchCandidatesForTopic(selectedTopicId!);

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
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTopicTitle ?? "Voting Topik"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (topics.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.deepPurple.shade50,
              child: Row(
                children: [
                  const Text("Pilih Topik: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedTopicId,
                      items: topics.map((t) {
                        return DropdownMenuItem<int>(
                          value: t.id,
                          child: Text(t.title, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final top = topics.firstWhere((t) => t.id == val);
                          setState(() {
                            selectedTopicId = val;
                            selectedTopicTitle = top.title;
                          });
                          fetchCandidatesForTopic(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : candidates.isEmpty
                    ? const Center(child: Text("Tidak ada kandidat untuk topik ini."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
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
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: photoUrl.isNotEmpty
                                            ? Image.network(
                                                photoUrl,
                                                width: 65,
                                                height: 65,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 65,
                                                  height: 65,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.person, size: 35),
                                                ),
                                              )
                                            : Container(
                                                width: 65,
                                                height: 65,
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.person, size: 35),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              c.bio.isNotEmpty ? c.bio : "Kandidat E-Voting",
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isMyVotedCandidate
                                              ? Colors.green
                                              : (hasVotedTopic ? Colors.grey : Colors.deepPurple),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: (actionLoading || hasVotedTopic)
                                            ? null
                                            : () => voteCandidate(c),
                                        child: Text(
                                          isMyVotedCandidate
                                              ? "Pilihan Anda"
                                              : (hasVotedTopic ? "Sudah Vote" : "Vote"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // 📊 Progress Bar Survei Suara
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Keunggulan Suara:",
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


