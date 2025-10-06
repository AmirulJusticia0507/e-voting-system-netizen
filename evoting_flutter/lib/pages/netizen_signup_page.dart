import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class NetizenSignupPage extends StatefulWidget {
  const NetizenSignupPage({super.key});

  @override
  State<NetizenSignupPage> createState() => _NetizenSignupPageState();
}

class _NetizenSignupPageState extends State<NetizenSignupPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool obscurePassword = true;

  /// tambahan: opsi keamanan
  bool enableBiometric = false;
  bool enablePin = false;

  /// tambahan: foto profil
  File? _selectedImage;
  Uint8List? _webImageBytes; // kalau running di Web
  String? _webFilename;

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _webFilename = picked.name;
        });
      } else {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    }
  }

  void signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final res = await api.postMultipart(
      "netizens/signup/",
      fields: {
        "phone_number": phoneController.text.trim(),
        "password": passwordController.text.trim(),
        "enable_biometric": enableBiometric.toString(),
        "enable_pin": enablePin.toString(),
      },
      file: _selectedImage,
      fileField: "photo", // sesuai serializer Django
      webFileBytes: _webImageBytes,
      webFilename: _webFilename,
    );

    setState(() => isLoading = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup berhasil! Silakan login.")),
      );
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      String errorMsg = "Signup gagal, periksa kembali data Anda.";
      try {
        final data = jsonDecode(res.body);
        if (data["detail"] != null) errorMsg = data["detail"];
      } catch (_) {}
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup Netizen")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// Upload Foto
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : _webImageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_webImageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_selectedImage == null && _webImageBytes == null)
                            ? const Icon(Icons.camera_alt,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: phoneController,
                      label: "Nomor HP",
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Nomor HP tidak boleh kosong";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: passwordController,
                      label: "Password",
                      prefixIcon: Icons.lock,
                      obscureText: obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password tidak boleh kosong";
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // opsi biometrik
                    SwitchListTile(
                      title: const Text("Aktifkan Biometrik"),
                      value: enableBiometric,
                      onChanged: (val) {
                        setState(() {
                          enableBiometric = val;
                          if (val) enablePin = false;
                        });
                      },
                    ),

                    // opsi PIN
                    SwitchListTile(
                      title: const Text("Aktifkan PIN"),
                      value: enablePin,
                      onChanged: (val) {
                        setState(() {
                          enablePin = val;
                          if (val) enableBiometric = false;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    CustomButton(
                      text: "Signup",
                      isLoading: isLoading,
                      onPressed: signup,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
