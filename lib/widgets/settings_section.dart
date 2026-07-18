import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final bool showDividers;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: colors.accent,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (showDividers && i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
