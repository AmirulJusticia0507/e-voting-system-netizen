import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/comment.dart';

class CommentsPage extends StatefulWidget {
  final int topicId;
  final String topicTitle;

  const CommentsPage({super.key, required this.topicId, required this.topicTitle});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final api = ApiService();
  List<Comment> comments = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  void fetchComments() async {
    final res = await api.get("comments/?topic=${widget.topicId}");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      setState(() {
        comments = data.map((e) => Comment.fromJson(e)).toList();
      });
    }
  }

  void postComment() async {
    if (_controller.text.isEmpty) return;

    final res = await api.post("comments/", {
      "user": 1, // 🔹 sementara hardcoded
      "topic": widget.topicId,
      "text": _controller.text,
    });

    if (res.statusCode == 201) {
      _controller.clear();
      fetchComments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal komentar: ${res.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Komentar: ${widget.topicTitle}")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, i) {
                final c = comments[i];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(c.text),
                  subtitle: Text("👍 ${c.likes} | 👎 ${c.dislikes}"),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Tulis komentar...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: postComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
