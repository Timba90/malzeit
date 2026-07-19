import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Startbildschirm mit App-Name, wechselt automatisch ins Hauptmenü.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFB8C00),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.brush, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Malzeit',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Malen für kleine Künstler',
              style: TextStyle(fontSize: 18, color: Color(0xFF8D6E63)),
            ),
          ],
        ),
      ),
    );
  }
}
