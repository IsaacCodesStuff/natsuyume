import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';
import '../theme/theme_registry.dart';
import 'screens/welcome_screen.dart';
import 'screens/folder_screen.dart';
import 'screens/theme_screen.dart';
import 'screens/allset_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentPage = 0;
  bool _themeInitialized = false;

  void _next() => setState(() => _currentPage++);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_themeInitialized) {
      _themeInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ThemeRegistry.instance.selectMode(NatsuyumeMode.light);
        NatsuyumeTheme.of(
          context,
        ).onThemeChange(ThemeRegistry.instance.currentScheme);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPage) {
      case 0:
        return WelcomeScreen(onNext: _next);
      case 1:
        return ThemeScreen(onNext: _next);
      case 2:
        return FolderScreen(onNext: _next);
      case 3:
        return const AllSetScreen();
      default:
        return const AllSetScreen();
    }
  }
}
