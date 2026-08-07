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
      "topic": widget.topicId,
      "text": _controller.text,
    });

    if (res.statusCode == 201) {
      _controller.clear();
      fetchComments();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal melempar komentar: ${res.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Komentar: ${widget.topicTitle}"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: comments.isEmpty
                ? const Center(child: Text("Belum ada komentar pada topik ini."))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: comments.length,
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            c.username ?? "Netizen",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(c.text, style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                "👍 ${c.likes}  |  👎 ${c.dislikes}",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Tulis komentar netizen...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
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
