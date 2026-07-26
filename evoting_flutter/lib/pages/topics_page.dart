import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/topic.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  final api = ApiService();
  List<Topic> topics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    setState(() => isLoading = true);
    final res = await api.get("topics/");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      setState(() {
        topics = data.map((e) => Topic.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Topik E-Voting Active"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : topics.isEmpty
              ? const Center(child: Text("Belum ada topik voting tersedia."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: topics.length,
                  itemBuilder: (context, i) {
                    final t = topics[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: const Icon(Icons.how_to_vote, color: Colors.deepPurple),
                        ),
                        title: Text(
                          t.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.deepPurple),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/candidates',
                            arguments: {'topicId': t.id, 'topicTitle': t.title},
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

