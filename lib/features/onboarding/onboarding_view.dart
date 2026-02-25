import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Judul per slide
  final List<String> _slideTitles = [
    'Selamat Datang',
    'Bagaimana Kabarmu?',
    'Silahkan Masuk',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Halaman terakhir → pindah ke LoginView
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  // Widget indikator titik (dot indicator)
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final bool isActive = index == _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 12 : 10,
          height: isActive ? 12 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.purple : Colors.grey, // Ubah warna purple
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Ubah tema hitam
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _slideTitles[_currentPage],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple, // Ubah warna purple
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 3,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.asset(
                    "assets/images/onboarding${index + 1}.png",
                    width: 250,
                    height: 250,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Page Indicator (3 bulatan)
            _buildPageIndicator(),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple, // Ubah warna purple
                foregroundColor: Colors.white, // Ubah warna purple
              ),
              onPressed: _nextStep,
              child: const Text("Lanjut"),
            ),
          ],
        ),
      ),
    );
  }
}
