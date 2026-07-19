import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/player/player_shell.dart';

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const PlayerShell()));
    }
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
