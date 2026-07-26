import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../core/natsuyume_core.dart';
import 'package:file_picker/file_picker.dart';

class FolderScreen extends StatefulWidget {
  final VoidCallback onNext;
  const FolderScreen({super.key, required this.onNext});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final List<String> _folders = [];

  Future<void> _addFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    if (_folders.contains(result)) return;
    setState(() => _folders.add(result));
    NatsuyumeCore.instance.addScanFolder(result);
  }

  void _removeFolder(String path) {
    setState(() => _folders.remove(path));
    NatsuyumeCore.instance.removeScanFolder(path);
  }

  void _startScan() {
    if (_folders.isEmpty) {
      widget.onNext();
      return;
    }
    NatsuyumeCore.instance.rescanAllFolders();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Add your music',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select folders where your music lives. '
                'Natsuyume will scan them and build your library.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Add folder button
              GestureDetector(
                onTap: _addFolder,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: colors.accent, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Add a folder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Folder list
              Expanded(
                child: _folders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 48,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No folders added yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          final path = _folders[index];
                          final name = path.split('/').last;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_rounded,
                                  color: colors.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: colors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        path,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeFolder(path),
                                  child: Icon(
                                    Icons.close,
                                    color: colors.onSurfaceVariant,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              // Scan progress
              ListenableBuilder(
                listenable: NatsuyumeCore.instance.scanState,
                builder: (context, _) {
                  final scan = NatsuyumeCore.instance.scanState;
                  if (!scan.isScanning) return const SizedBox.shrink();
                  final progress = scan.total > 0
                      ? scan.progress / scan.total
                      : 0.0;
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: colors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(colors.accent),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scanning ${scan.progress} / ${scan.total}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
              _PrimaryButton(
                label: _folders.isEmpty ? 'Skip for now' : 'Scan library',
                onTap: _startScan,
                colors: colors,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final NatsuyumeColorScheme colors;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.background,
            ),
          ),
        ),
      ),
    );
  }
}
