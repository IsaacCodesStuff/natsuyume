import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class InfoRow {
  final String label;
  final String value;

  const InfoRow({required this.label, required this.value});
}

class CollectionInfoOverlay extends StatelessWidget {
  final String name;
  final ImageProvider? image;
  final String sectionLabel;
  final String? description;
  final List<InfoRow> details;
  final VoidCallback onEditInfo;
  final VoidCallback onSaveImage;

  const CollectionInfoOverlay({
    super.key,
    required this.name,
    this.image,
    required this.sectionLabel,
    this.description,
    this.details = const [],
    required this.onEditInfo,
    required this.onSaveImage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred scrim background
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: colors.background.withValues(alpha: 0.85)),
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 8),
                      // Image card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: image != null
                              ? Image(image: image!, fit: BoxFit.cover)
                              : Container(
                                  color: colors.surfaceVariant,
                                  child: Icon(
                                    Icons.image,
                                    size: 64,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Name
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: colors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Divider + section label
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: colors.divider, height: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              sectionLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: colors.divider, height: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      if (description != null) ...[
                        Text(
                          description!.isNotEmpty
                              ? description!
                              : 'No description.',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurface,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Detail rows
                      if (details.isNotEmpty)
                        ...details.map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${row.label}: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    row.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons — bottom right
          Positioned(
            right: 24,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _OverlayButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit info',
                  colors: colors,
                  onTap: onEditInfo,
                ),
                const SizedBox(height: 10),
                _OverlayButton(
                  icon: Icons.save_alt_outlined,
                  label: 'Save image',
                  colors: colors,
                  onTap: onSaveImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.background),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
