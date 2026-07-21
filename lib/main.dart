import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/onboarding_flow.dart';
import 'player/player_shell.dart';
import 'theme/natsuyume_theme.dart';
import 'core/natsuyume_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  try {
    NatsuyumeCore.instance.init();
    print('NatsuyumeCore init OK');
    await NatsuyumeCore.instance.initCore();
    print('NatsuyumeCore initCore OK');
  } catch (e) {
    print('NatsuyumeCore init FAILED: $e');
  }

  runApp(NatsuyumeApp(onboardingComplete: onboardingComplete));
}

class NatsuyumeApp extends StatelessWidget {
  final bool onboardingComplete;

  const NatsuyumeApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return NatsuyumeThemeProvider(
      child: MaterialApp(
        title: 'Natsuyume',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        home: onboardingComplete ? const PlayerShell() : const OnboardingFlow(),
      ),
    );
  }
}
