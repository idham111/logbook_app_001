import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({
    super.key,
    required this.username,
  });

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepController = TextEditingController(text: '1');
  int _stepValue = 1;

  @override
  void initState() {
    super.initState();
    _controller.setUsername(widget.username);
    _loadSavedData();
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _loadSavedData() async {
    await _controller.loadCounter();
    setState(() {}); // Refresh UI setelah data di-load
  }

  void _incrementCounter() {
    setState(() {
      _controller.increment(step: _stepValue);
    });
  }

  void _decrementCounter() {
    setState(() {
      _controller.decrement(step: _stepValue);
    });
  }

  void _resetCounter() {
    setState(() {
      _controller.reset();
    });
  }

  // Greeting langsung di Activity — tidak perlu file terpisah
  String _getGreeting(String username) {
    final int hour = DateTime.now().hour;
    String greeting;
    if (hour >= 6 && hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour >= 12 && hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }
    return '$greeting, $username';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text(
            "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingView(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header: Welcome Banner (dinamis sesuai waktu)
            Text(
              _getGreeting(widget.username),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              "Total Hitungan",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              "${_controller.value}",
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Step input — user bisa ubah nilai langkah
            TextField(
              controller: _stepController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Step',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _stepValue = int.tryParse(val) ?? 1;
                  if (_stepValue < 1) _stepValue = 1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Tombol -, +, Reset
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _decrementCounter,
                  child: const Text('-', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _incrementCounter,
                  child: const Text('+', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _resetCounter,
                  child: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Header riwayat
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Riwayat Aktivitas:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // ListView riwayat
            Expanded(
              child: _controller.history.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada aktivitas.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _controller.history.length,
                      itemBuilder: (context, index) {
                        // Tampilkan dari terbaru ke terlama
                        final item = _controller.history[
                            _controller.history.length - 1 - index];

                        // Warna berdasarkan jenis aktivitas
                        Color textColor;
                        if (item.contains('+')) {
                          textColor = Colors.green;
                        } else if (item.contains('-')) {
                          textColor = Colors.red;
                        } else if (item.toLowerCase().contains('reset')) {
                          textColor = Colors.grey;
                        } else {
                          textColor = Colors.black;
                        }

                        return ListTile(
                          leading: Icon(Icons.history, size: 20, color: textColor),
                          title: Text(item, style: TextStyle(fontSize: 13, color: textColor)),
                          dense: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}