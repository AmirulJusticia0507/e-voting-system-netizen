import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  List<dynamic> topics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final resCand = await api.get("candidates/");
    final resTop = await api.get("topics/");

    if (mounted) {
      setState(() {
        if (resCand.statusCode == 200) candidates = jsonDecode(resCand.body);
        if (resTop.statusCode == 200) topics = jsonDecode(resTop.body);
        isLoading = false;
      });
    }
  }

  void _showCandidateDialog([Map<String, dynamic>? candidate]) {
    final isEdit = candidate != null;
    final nameCtrl = TextEditingController(text: isEdit ? candidate['name'] : '');
    final bioCtrl = TextEditingController(text: isEdit ? candidate['bio'] : '');
    int? selectedTopicId = isEdit
        ? (candidate['topic'] is int ? candidate['topic'] : candidate['topic']?['id'])
        : (topics.isNotEmpty ? topics.first['id'] : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Edit Kandidat" : "Tambah Kandidat Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (topics.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Pilih Topik:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: selectedTopicId,
                    items: topics.map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem<int>(
                        value: t['id'],
                        child: Text(t['title'] ?? '', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedTopicId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nama Kandidat", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Visi / Misi / Bio", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || selectedTopicId == null) return;
                final body = {
                  "topic": selectedTopicId,
                  "name": nameCtrl.text,
                  "bio": bioCtrl.text,
                };

                if (isEdit) {
                  final res = await api.patchJson("candidates/${candidate['id']}/", body);
                  if (res.statusCode == 200 && mounted) {
                    Navigator.pop(ctx);
                    fetchData();
                  }
                } else {
                  final res = await api.post("candidates/", body);
                  if (res.statusCode == 201 && mounted) {
                    Navigator.pop(ctx);
                    fetchData();
                  }
                }
              },
              child: Text(isEdit ? "Perbarui" : "Simpan"),
            )
          ],
        ),
      ),
    );
  }

  void _deleteCandidate(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Kandidat"),
        content: Text("Apakah Anda yakin ingin menghapus kandidat '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final token = await api.getToken();
              final uri = Uri.parse("${api.baseUrl}candidates/$id/");
              final delRes = await http.delete(uri, headers: {
                if (token != null) "Authorization": "Bearer $token",
              });

              if ((delRes.statusCode == 204 || delRes.statusCode == 200) && mounted) {
                Navigator.pop(ctx);
                fetchData();
              } else if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal menghapus kandidat. Status: ${delRes.statusCode}")),
                );
              }
            },
            child: const Text("Hapus"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Kandidat"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCandidateDialog(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Kandidat", style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : candidates.isEmpty
              ? const Center(child: Text("Belum ada kandidat."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: candidates.length,
                  itemBuilder: (context, i) {
                    final c = candidates[i];
                    final photoUrl = api.getImageUrl(c['photo']);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(
                          c['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['bio'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              "Suara: ${c['vote_count'] ?? 0} (${c['vote_percentage'] ?? 0}%)",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showCandidateDialog(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCandidate(c['id'], c['name'] ?? ''),
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
