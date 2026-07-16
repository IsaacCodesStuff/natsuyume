import 'package:flutter/material.dart';

enum AppTheme { light, dark, dynamic, locked }

class ThemeScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ThemeScreen({super.key, required this.onNext, required this.onBack});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  AppTheme _selected = AppTheme.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Select a theme',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFD0C4E8),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _ThemeCard(
                      label: 'Light',
                      icon: Icons.wb_sunny_outlined,
                      theme: AppTheme.light,
                      selected: _selected == AppTheme.light,
                      locked: false,
                      onTap: () => setState(() => _selected = AppTheme.light),
                    ),
                    _ThemeCard(
                      label: 'Dark',
                      icon: Icons.nightlight_outlined,
                      theme: AppTheme.dark,
                      selected: _selected == AppTheme.dark,
                      locked: false,
                      onTap: () => setState(() => _selected = AppTheme.dark),
                    ),
                    _ThemeCard(
                      label: 'Dynamic',
                      icon: Icons.language_outlined,
                      theme: AppTheme.dynamic,
                      selected: _selected == AppTheme.dynamic,
                      locked: false,
                      onTap: () => setState(() => _selected = AppTheme.dynamic),
                    ),
                    _ThemeCard(
                      label: '???',
                      icon: Icons.lock_outlined,
                      theme: AppTheme.locked,
                      selected: false,
                      locked: true,
                      onTap: null,
                    ),
                  ],
                ),
              ),
              const Text(
                'Note: You can change this later in Settings.',
                style: TextStyle(fontSize: 13, color: Color(0xFF9A8FB0)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(icon: Icons.arrow_back, onPressed: widget.onBack),
                  _NavButton(
                    icon: Icons.arrow_forward,
                    onPressed: widget.onNext,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppTheme theme;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.theme,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3850),
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: const Color(0xFFB08ED0), width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: locked ? const Color(0xFF5A5470) : const Color(0xFFB0A4C8),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: locked
                    ? const Color(0xFF5A5470)
                    : const Color(0xFFD0C4E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3A3850),
        foregroundColor: const Color(0xFFB0A4C8),
        minimumSize: const Size(56, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Icon(icon),
    );
  }
}
