import 'package:flutter/material.dart';
import 'player/player_shell.dart';
import 'theme/natsuyume_theme.dart';

void main() {
  runApp(const NatsuyumeApp());
}

class NatsuyumeApp extends StatelessWidget {
  const NatsuyumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NatsuyumeThemeProvider(
      child: MaterialApp(
        title: 'Natsuyume',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        home: const PlayerShell(),
      ),
    );
  }
}
