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
    final res = await api.get("users/1/"); // sementara hardcode id=1

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal load votes: ${res.body}")),
        );
      }
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
      "users/${user!['id']}/",
      files: _image != null ? {"photo": _image!} : null,
    );

    if (res.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated")),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: updateProfile,
          )
        ],
      ),
      body: user == null
          ? const Center(child: Text("User tidak ditemukan"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (user!['photo'] != null
                              ? NetworkImage(user!['photo'])
                              : const AssetImage("assets/avatar.png"))
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user!['username'] ?? "No username",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(user!['email'] ?? "No email"),
                  const Divider(height: 32),
                  const Text("My Votes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...userVotes.map((vote) => ListTile(
                        title: Text("Candidate: ${vote['candidate_name']}"),
                        subtitle: Text("Date: ${vote['created_at']}"),
                      )),
                ],
              ),
            ),
    );
  }
}
