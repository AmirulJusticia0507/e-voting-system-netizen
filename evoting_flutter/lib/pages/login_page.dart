import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_page.dart';
import 'netizen_signup_page.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

class LoginPage extends StatefulWidget {
  final VoidCallback? onSignupTap; // ✅ optional

  const LoginPage({Key? key, this.onSignupTap}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final api = ApiService();
  final storage = const FlutterSecureStorage();
  final auth = LocalAuthentication();

  bool isLoading = false;
  bool obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  /// 🔹 Login via API
  void loginAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final identifier = phoneController.text.trim();
    final password = passwordController.text.trim();

    final bool isPhone = RegExp(r'^[0-9]+$').hasMatch(identifier);

    final endpoint = isPhone ? "token/" : "auth/admin-login/";
    final payload = isPhone
        ? {
            "phone_number": identifier,
            "password": password,
          }
        : {
            "username": identifier,
            "password": password,
          };

    final res = await api.post(endpoint, payload);

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final access = data["access"];
      await api.saveToken(access);
      await storage.write(key: "access_token", value: access);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      String errorMsg =
          "Login gagal, periksa kembali nomor/username dan password.";
      try {
        final data = jsonDecode(res.body);
        if (data["detail"] != null) errorMsg = data["detail"];
      } catch (_) {}
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  /// 🔹 Fingerprint login (Android/iOS only)
  void loginWithFingerprint() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Fingerprint tidak tersedia di Web")));
      return;
    }

    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Perangkat tidak mendukung biometrik")));
        return;
      }

      final didAuth = await auth.authenticate(
        localizedReason: "Gunakan sidik jari untuk masuk",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuth) {
        final token = await storage.read(key: "access_token");
        if (token != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text("Belum pernah login sebelumnya. Gunakan login biasa.")));
        }
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D5DF6), Color(0xFF4A47A3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  "E-Voting",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 40),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: phoneController,
                            label: "Nomor HP / Username",
                            prefixIcon: Icons.person,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Nomor HP / Username tidak boleh kosong";
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
                            text: "Login",
                            isLoading: isLoading,
                            onPressed: loginAdmin,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: widget.onSignupTap ??
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const NetizenSignupPage()),
                                  );
                                },
                            child: const Text(
                              "Signup Netizen",
                              style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          IconButton(
                            icon: const Icon(Icons.fingerprint,
                                size: 40, color: Colors.deepPurple),
                            onPressed: loginWithFingerprint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
