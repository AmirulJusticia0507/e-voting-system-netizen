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

  @override
  void initState() {
    super.initState();
    fetchTopics();
  }

  void fetchTopics() async {
    final res = await api.get("topics/");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      setState(() {
        topics = data.map((e) => Topic.fromJson(e)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Topik Voting")),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, i) {
          final t = topics[i];
          return ListTile(
            title: Text(t.title),
            subtitle: Text(t.description),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/candidates',
                arguments: {'topicId': t.id, 'topicTitle': t.title},
              );
            },
          );
        },
      ),
    );
  }
}
