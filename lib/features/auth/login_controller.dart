import 'dart:async';
import 'package:flutter/material.dart';


class LoginController {
  final Map<String, String> _users = {
    "admin": "123",
    "idham": "456",
  };

  int _failCount = 0;
  bool _isLocked = false;
  int _remainingSeconds = 0;
  Timer? _lockTimer;

  bool get isLocked => _isLocked;
  int get remainingSeconds => _remainingSeconds;
  int get failCount => _failCount;

  Map<String, dynamic> login(String username, String password) {
    if (_isLocked) {
      return {
        "success": false,
        "message": "Login dikunci. Coba lagi dalam $_remainingSeconds detik.",
      };
    }

    if (username.isEmpty && password.isEmpty) {
      return {"success": false, "message": "Username dan Password harus diisi!"};
    }
    if (username.isEmpty) {
      return {"success": false, "message": "Username tidak boleh kosong!"};
    }
    if (password.isEmpty) {
      return {"success": false, "message": "Password tidak boleh kosong!"};
    }

    if (_users.containsKey(username) && _users[username] == password) {
      _failCount = 0;
      return {"success": true, "message": "Login berhasil!"};
    }

    _failCount++;
    int sisa = 3 - _failCount;

    if (_failCount >= 3) {
      _startLockTimer();
      return {
        "success": false,
        "message": "3x gagal! Login dikunci selama 10 detik.",
      };
    }

    return {
      "success": false,
      "message": "Username atau Password salah! ($sisa percobaan tersisa)",
    };
  }

  void _startLockTimer() {
    _isLocked = true;
    _remainingSeconds = 10;

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _onTickCallback?.call();

      if (_remainingSeconds <= 0) {
        _isLocked = false;
        _failCount = 0;
        timer.cancel();
        _onTickCallback?.call();
      }
    });
  }

  VoidCallback? _onTickCallback;

  void setOnTickCallback(VoidCallback callback) {
    _onTickCallback = callback;
  }

  void dispose() {
    _lockTimer?.cancel();
  }
}
