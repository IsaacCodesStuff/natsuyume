import 'package:flutter/material.dart';
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

  void _next() {
    setState(() => _currentPage++);
  }

  void _back() {
    setState(() => _currentPage--);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      WelcomeScreen(onNext: _next),
      FolderScreen(onNext: _next, onBack: _back),
      ThemeScreen(onNext: _next, onBack: _back),
      AllSetScreen(),
    ];

    return pages[_currentPage];
  }
}
