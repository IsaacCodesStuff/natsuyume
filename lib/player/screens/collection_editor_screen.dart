import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';

enum ThemeColorMode { manual, automatic, none }

class CollectionEditorScreen extends StatefulWidget {
  final String title;
  final String nameLabel;
  final String themeColorLabel;
  final String initialName;
  final String initialDescription;
  final ImageProvider? initialImage;

  const CollectionEditorScreen({
    super.key,
    required this.title,
    required this.nameLabel,
    required this.themeColorLabel,
    this.initialName = '',
    this.initialDescription = '',
    this.initialImage,
  });

  @override
  State<CollectionEditorScreen> createState() => _CollectionEditorScreenState();
}

class _CollectionEditorScreenState extends State<CollectionEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  ThemeColorMode _themeColorMode = ThemeColorMode.automatic;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    // Wired to core in 0.8.x
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(colors),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildImageHero(colors),
                  const SizedBox(height: 24),
                  _buildFields(colors),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close, color: colors.onSurface, size: 24),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _save,
            child: Icon(Icons.check, color: colors.accent, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHero(NatsuyumeColorScheme colors) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          widget.initialImage != null
              ? Image(image: widget.initialImage!, fit: BoxFit.cover)
              : Container(color: colors.surfaceVariant),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  colors.background.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          // Edit + delete buttons
          Positioned(
            left: 24,
            bottom: 24,
            child: Row(
              children: [
                _ImageButton(
                  icon: Icons.edit_outlined,
                  colors: colors,
                  onTap: () {
                    // Image picker wired in 0.8.x
                  },
                ),
                const SizedBox(width: 16),
                _ImageButton(
                  icon: Icons.delete_outline,
                  colors: colors,
                  onTap: () {
                    // Remove image wired in 0.8.x
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          _FieldLabel(label: widget.nameLabel, colors: colors),
          const SizedBox(height: 4),
          _UnderlineField(controller: _nameController, colors: colors),
          const SizedBox(height: 24),
          // Theme color mode
          _FieldLabel(label: widget.themeColorLabel, colors: colors),
          const SizedBox(height: 12),
          _ThemeColorPicker(
            selected: _themeColorMode,
            colors: colors,
            onChanged: (mode) => setState(() => _themeColorMode = mode),
          ),
          const SizedBox(height: 24),
          // Description field
          _FieldLabel(label: 'Description', colors: colors),
          const SizedBox(height: 4),
          _UnderlineField(controller: _descriptionController, colors: colors),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final NatsuyumeColorScheme colors;

  const _FieldLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final NatsuyumeColorScheme colors;
  final String? hint;

  const _UnderlineField({
    required this.controller,
    required this.colors,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 16, color: colors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.divider, width: 1),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }
}

class _ThemeColorPicker extends StatelessWidget {
  final ThemeColorMode selected;
  final NatsuyumeColorScheme colors;
  final ValueChanged<ThemeColorMode> onChanged;

  const _ThemeColorPicker({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ThemeColorMode.values.map((mode) {
        final isSelected = mode == selected;
        final label = switch (mode) {
          ThemeColorMode.manual => 'Manual',
          ThemeColorMode.automatic => 'Automatic',
          ThemeColorMode.none => 'None',
        };

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode != ThemeColorMode.none ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accent : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? colors.background
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImageButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ImageButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
