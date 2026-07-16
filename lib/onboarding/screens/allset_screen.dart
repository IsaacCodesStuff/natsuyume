import 'package:flutter/material.dart';

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});

  void _finish(BuildContext context) {
    // Placeholder — will navigate to main library screen in 0.8.x
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _PlaceholderHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'All set!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFD0C4E8),
                ),
              ),
              const SizedBox(height: 48),
              Image.asset(
                'assets/images/welcome_logo.png',
                width: 220,
                height: 220,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40, right: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _finish(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A3850),
                      foregroundColor: const Color(0xFFB0A4C8),
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Home Screen\n(coming in 0.8.x)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Color(0xFFB0A4C8)),
        ),
      ),
    );
  }
}
