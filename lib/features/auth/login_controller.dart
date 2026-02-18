import 'dart:async';
import 'package:flutter/material.dart';


class LoginController {
  // Database sederhana: Map username → password
  final Map<String, String> _users = {
    "admin": "123",
    "idham": "456",
  };

  // Sistem batas percobaan
  int _failCount = 0;
  bool _isLocked = false;
  int _remainingSeconds = 0;
  Timer? _lockTimer;

  // Getter untuk View
  bool get isLocked => _isLocked;
  int get remainingSeconds => _remainingSeconds;
  int get failCount => _failCount;

  /// Login dengan validasi lengkap.
  /// Mengembalikan Map: { "success": bool, "message": String }
  Map<String, dynamic> login(String username, String password) {
    // Cek apakah sedang dikunci
    if (_isLocked) {
      return {
        "success": false,
        "message": "Login dikunci. Coba lagi dalam $_remainingSeconds detik.",
      };
    }

    // Validasi input kosong
    if (username.isEmpty && password.isEmpty) {
      return {"success": false, "message": "Username dan Password harus diisi!"};
    }
    if (username.isEmpty) {
      return {"success": false, "message": "Username tidak boleh kosong!"};
    }
    if (password.isEmpty) {
      return {"success": false, "message": "Password tidak boleh kosong!"};
    }

    // Cek kredensial
    if (_users.containsKey(username) && _users[username] == password) {
      _failCount = 0; // Reset jika berhasil
      return {"success": true, "message": "Login berhasil!"};
    }

    // Login gagal
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

  /// Mulai timer kunci 10 detik
  void _startLockTimer() {
    _isLocked = true;
    _remainingSeconds = 10;

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      // Callback dipanggil dari View via onTick
      _onTickCallback?.call();

      if (_remainingSeconds <= 0) {
        _isLocked = false;
        _failCount = 0;
        timer.cancel();
        _onTickCallback?.call();
      }
    });
  }

  // Callback agar View bisa setState setiap detik
  VoidCallback? _onTickCallback;

  void setOnTickCallback(VoidCallback callback) {
    _onTickCallback = callback;
  }

  /// Bersihkan timer saat View di-dispose
  void dispose() {
    _lockTimer?.cancel();
  }
}
