import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/natsuyume_theme.dart';
import '../../player/player_shell.dart';

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PlayerShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 44,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "You're all set.",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: colors.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Natsuyume is ready. Your library will finish\n'
                'scanning in the background.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              // Tips
              _TipRow(
                icon: Icons.queue_music,
                text: 'Tap on any song in an album to play a queue',
                colors: colors,
              ),
              const SizedBox(height: 12),
              _TipRow(
                icon: Icons.text_fields,
                text: 'Tap the lyrics icon in Now Playing for lyrics',
                colors: colors,
              ),
              const SizedBox(height: 12),
              _TipRow(
                icon: Icons.question_mark,
                text: 'Some things are meant to be forgotten',
                colors: colors,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _finish(context),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Start listening',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.background,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final NatsuyumeColorScheme colors;

  const _TipRow({required this.icon, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
