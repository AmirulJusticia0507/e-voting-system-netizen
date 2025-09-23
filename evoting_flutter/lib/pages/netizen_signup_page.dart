import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_page.dart';
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

  void signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final res = await api.post("netizens/signup/", {
      "phone_number": phoneController.text.trim(),
      "password": passwordController.text.trim(),
    });

    setState(() => isLoading = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup berhasil! Silakan login.")));
      Navigator.pop(context);
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
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
                        icon: Icon(obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
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
