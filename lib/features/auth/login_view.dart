import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
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

    Map<String, dynamic> result = _controller.login(user, pass);

    if (result["success"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(
            currentUser: result["user"], // ← kirim Map user (username, uid, role, teamId)
          ),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Login Gatekeeper",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Username",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
              ),
            ),

            TextField(
              controller: _passController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
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

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.purple.withOpacity(0.3),
                disabledForegroundColor: Colors.white54,
              ),
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
