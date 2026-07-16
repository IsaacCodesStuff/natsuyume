import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({super.key, required this.onNext});

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
                'W e l c o m e',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 6,
                  color: Color(0xFFB8A9D0),
                ),
              ),
              const SizedBox(height: 48),
              Image.asset(
                'assets/images/welcome_logo.png',
                width: 220,
                height: 220,
              ),
              const SizedBox(height: 32),
              const Text(
                'N a t s u y u m e',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 6,
                  color: Color(0xFFB8A9D0),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4560),
                    foregroundColor: const Color(0xFFD0C4E8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16, letterSpacing: 1),
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
