import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinLoginPage extends StatefulWidget {
  final VoidCallback onSuccess;
  const PinLoginPage({super.key, required this.onSuccess});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage> {
  final _controller = TextEditingController();
  final storage = const FlutterSecureStorage();
  String? _error;

  Future<void> _verifyPin() async {
    final savedPin = await storage.read(key: "user_pin");

    if (savedPin == null) {
      setState(() {
        _error = "PIN belum diset, login manual dulu.";
      });
      return;
    }

    if (_controller.text == savedPin) {
      widget.onSuccess();
    } else {
      setState(() {
        _error = "PIN salah!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login dengan PIN")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Masukkan PIN untuk verifikasi"),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "PIN",
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyPin,
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
