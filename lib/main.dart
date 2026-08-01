import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/onboarding_flow.dart';
import 'player/player_shell.dart';
import 'theme/natsuyume_theme.dart';
import 'theme/theme_registry.dart';
import 'core/natsuyume_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  await ThemeRegistry.instance.loadFromPrefs(prefs);

  try {
    NatsuyumeCore.instance.init();
    await NatsuyumeCore.instance.initCore();
    // Restore last session after core is ready
    // Small delay to let mpv fully initialize
    await Future.delayed(const Duration(milliseconds: 800));
    NatsuyumeCore.instance.restoreLastSession();
  } catch (e) {
    debugPrint('NatsuyumeCore init FAILED: $e');
  }

  runApp(NatsuyumeApp(onboardingComplete: onboardingComplete));
}

class NatsuyumeApp extends StatefulWidget {
  final bool onboardingComplete;

  const NatsuyumeApp({super.key, required this.onboardingComplete});

  @override
  State<NatsuyumeApp> createState() => _NatsuyumeAppState();
}

class _NatsuyumeAppState extends State<NatsuyumeApp>
    with WidgetsBindingObserver {
  late NatsuyumeColorScheme _scheme;

  @override
  void initState() {
    super.initState();
    _scheme = ThemeRegistry.instance.currentScheme;
    ThemeRegistry.instance.addListener(_onThemeChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeRegistry.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      NatsuyumeCore.instance.saveAndShutdown();
    }
  }

  void _onThemeChanged() {
    setState(() => _scheme = ThemeRegistry.instance.currentScheme);
  }

  @override
  Widget build(BuildContext context) {
    return NatsuyumeThemeProvider(
      initialScheme: _scheme,
      child: MaterialApp(
        title: 'Natsuyume',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF12131A),
        ),
        home: widget.onboardingComplete
            ? const PlayerShell()
            : const OnboardingFlow(),
      ),
    );
  }
}
