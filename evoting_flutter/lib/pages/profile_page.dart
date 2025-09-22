import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final api = ApiService();
  User? user;
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  void fetchUser() async {
    final res = await api.get("users/1/"); // 🔹 sementara ambil user id=1
    if (res.statusCode == 200) {
      setState(() {
        user = User.fromJson(jsonDecode(res.body));
      });
    }
  }

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
      // TODO: upload image via Dio (multipart)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya")),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (user!.photo != null
                              ? NetworkImage(user!.photo!)
                              : null) as ImageProvider?,
                      child: _image == null && user!.photo == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user!.phoneNumber,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(user!.isVerified ? "✅ Verified" : "❌ Not Verified"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: implement update user (PATCH)
                    },
                    child: const Text("Update Profil"),
                  )
                ],
              ),
            ),
    );
  }
}
