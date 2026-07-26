import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final api = ApiService();
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final res = await api.get("users/");
    if (res.statusCode == 200) {
      setState(() {
        users = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola User"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(u['username'] ?? u['phone_number'] ?? 'User'),
                    subtitle: Text("Phone: ${u['phone_number']} | Staff: ${u['is_staff']}"),
                  ),
                );
              },
            ),
    );
  }
}

class ManageTopicsPage extends StatefulWidget {
  const ManageTopicsPage({super.key});

  @override
  State<ManageTopicsPage> createState() => _ManageTopicsPageState();
}

class _ManageTopicsPageState extends State<ManageTopicsPage> {
  final api = ApiService();
  List<dynamic> topics = [];
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
      setState(() {
        topics = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Topik Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Judul Topik")),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Deskripsi")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              final res = await api.post("topics/", {
                "title": titleCtrl.text,
                "description": descCtrl.text,
                "is_active": true,
              });
              if (res.statusCode == 201) {
                Navigator.pop(ctx);
                fetchTopics();
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Topik"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: topics.length,
              itemBuilder: (context, i) {
                final t = topics[i];
                return Card(
                  child: ListTile(
                    title: Text(t['title'] ?? ''),
                    subtitle: Text(t['description'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}

class ManageCandidatesPage extends StatefulWidget {
  const ManageCandidatesPage({super.key});

  @override
  State<ManageCandidatesPage> createState() => _ManageCandidatesPageState();
}

class _ManageCandidatesPageState extends State<ManageCandidatesPage> {
  final api = ApiService();
  List<dynamic> candidates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  Future<void> fetchCandidates() async {
    setState(() => isLoading = true);
    final res = await api.get("candidates/");
    if (res.statusCode == 200) {
      setState(() {
        candidates = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Kandidat"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: candidates.length,
              itemBuilder: (context, i) {
                final c = candidates[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: c['photo'] != null ? NetworkImage(api.getImageUrl(c['photo'])) : null,
                      child: c['photo'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(c['name'] ?? ''),
                    subtitle: Text(c['bio'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}

class ManageVotesPage extends StatefulWidget {
  const ManageVotesPage({super.key});

  @override
  State<ManageVotesPage> createState() => _ManageVotesPageState();
}

class _ManageVotesPageState extends State<ManageVotesPage> {
  final api = ApiService();
  List<dynamic> votes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVotes();
  }

  Future<void> fetchVotes() async {
    setState(() => isLoading = true);
    final res = await api.get("votes/");
    if (res.statusCode == 200) {
      setState(() {
        votes = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Votes"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: votes.length,
              itemBuilder: (context, i) {
                final v = votes[i];
                return Card(
                  child: ListTile(
                    title: Text("Kandidat: ${v['candidate_name'] ?? v['candidate']}"),
                    subtitle: Text("Topik: ${v['topic_title'] ?? v['topic']} | Waktu: ${v['created_at'] ?? ''}"),
                  ),
                );
              },
            ),
    );
  }
}

class ManageCommentsPage extends StatefulWidget {
  const ManageCommentsPage({super.key});

  @override
  State<ManageCommentsPage> createState() => _ManageCommentsPageState();
}

class _ManageCommentsPageState extends State<ManageCommentsPage> {
  final api = ApiService();
  List<dynamic> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    setState(() => isLoading = true);
    final res = await api.get("comments/");
    if (res.statusCode == 200) {
      setState(() {
        comments = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Komentar"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: comments.length,
              itemBuilder: (context, i) {
                final c = comments[i];
                return Card(
                  child: ListTile(
                    title: Text(c['text'] ?? ''),
                    subtitle: Text("Oleh: ${c['username'] ?? 'User'} | 👍 ${c['likes']} | 👎 ${c['dislikes']}"),
                  ),
                );
              },
            ),
    );
  }
}
