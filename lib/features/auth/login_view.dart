import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Toggle show/hide password
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Daftarkan callback agar UI refresh setiap detik saat lock
    _controller.setOnTickCallback(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    String user = _userController.text.trim();
    String pass = _passController.text;

    // Panggil logic di controller
    Map<String, dynamic> result = _controller.login(user, pass);

    if (result["success"] == true) {
      // Navigasi ke CounterView — hanya kirim username
      // Counter state sepenuhnya dikelola oleh CounterView/Controller
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => CounterView(username: user),
        ),
        (route) => false,
      );
    } else {
      // Tampilkan pesan error dari controller
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TextField Username
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),

            // TextField Password + toggle visibility
            TextField(
              controller: _passController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Masuk — disabled saat locked
            ElevatedButton(
              onPressed: _controller.isLocked ? null : _handleLogin,
              child: Text(
                _controller.isLocked
                    ? "Dikunci (${_controller.remainingSeconds}s)"
                    : "Masuk",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
