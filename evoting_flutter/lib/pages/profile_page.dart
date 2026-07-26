import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> userVotes = [];
  bool isLoading = true;
  File? _image;
  final picker = ImagePicker();

  final ApiService api = ApiService(); // ✅ tambahin instance

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    final res = await api.get("users/me/");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        user = data;
        if (data['photo'] != null && data['photo'].toString().isNotEmpty) {
          _image = null;
        }
      });
      fetchUserVotes();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal load user: ${res.body}")),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUserVotes() async {
    if (user == null || user!['id'] == null) {
      setState(() => isLoading = false);
      return;
    }

    final userId = user!['id'];
    final res = await api.get("votes/?user=$userId");

    if (res.statusCode == 200) {
      setState(() {
        userVotes = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> updateProfile() async {
    if (user == null) return;

    final res = await api.patchMultipart(
      "users/me/",
      files: _image != null ? {"photo": _image!} : null,
    );

    if (res.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile berhasil diperbarui!")),
        );
      }
      fetchUser();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update gagal: ${res.body}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final photoUrl = user != null ? api.getImageUrl(user!['photo']) : "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Simpan Profil",
            onPressed: updateProfile,
          )
        ],
      ),
      body: user == null
          ? const Center(child: Text("User tidak ditemukan"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.deepPurple.shade100,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null) as ImageProvider?,
                          child: (_image == null && photoUrl.isEmpty)
                              ? const Icon(Icons.person, size: 55, color: Colors.deepPurple)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: pickImage,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user!['username'] ?? user!['phone_number'] ?? "Pengguna",
                    style: const TextStyle(fontSize: 20, FontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "No. HP: ${user!['phone_number'] ?? '-'}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      (user!['is_staff'] == true || user!['is_superuser'] == true)
                          ? "Administrator"
                          : "Netizen Voter",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: (user!['is_staff'] == true || user!['is_superuser'] == true)
                        ? Colors.red.shade400
                        : Colors.green.shade400,
                  ),
                  const Divider(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Riwayat Voting Saya (${userVotes.length})",
                      style: const TextStyle(fontSize: 18, FontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (userVotes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Anda belum melakukan voting."),
                    )
                  else
                    ...userVotes.map((vote) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.how_to_vote, color: Colors.deepPurple),
                          title: Text(vote['candidate_name'] != null
                              ? "Kandidat: ${vote['candidate_name']}"
                              : "Candidate ID: ${vote['candidate']}"),
                          subtitle: Text(vote['topic_title'] != null
                              ? "Topik: ${vote['topic_title']}"
                              : "Waktu: ${vote['created_at'] ?? '-'}"),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

