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
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCandidatesForTopic(int topicId) async {
    setState(() => isLoading = true);
    final res = await api.get("candidates/?topic=$topicId");
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      setState(() {
        candidates = data.map((c) => Candidate.fromJson(c)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> voteCandidate(Candidate candidate) async {
    if (selectedTopicId == null) return;
    setState(() => actionLoading = true);
    try {
      final res = await api.post("votes/", {
        "candidate": candidate.id,
        "topic": selectedTopicId,
      });

      if (res.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil memberikan vote untuk ${candidate.name}! 🎉")),
        );
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: photoUrl.isNotEmpty
                                        ? Image.network(
                                            photoUrl,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.person, size: 40),
                                            ),
                                          )
                                        : Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.person, size: 40),
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
                                          c.bio,
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
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: actionLoading ? null : () => voteCandidate(c),
                                    child: const Text("Vote"),
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

