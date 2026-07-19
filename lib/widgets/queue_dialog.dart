import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class QueueItem {
  String name;
  bool isPlaying;

  QueueItem({required this.name, this.isPlaying = false});
}

class QueueDialog extends StatefulWidget {
  final List<QueueItem> queues;
  final void Function(int index) onQueueSelected;
  final void Function(int index) onQueueRenamed;
  final void Function(int index) onQueueDeleted;
  final void Function(List<QueueItem> reordered) onReordered;

  const QueueDialog({
    super.key,
    required this.queues,
    required this.onQueueSelected,
    required this.onQueueRenamed,
    required this.onQueueDeleted,
    required this.onReordered,
  });

  static Future<void> show(
    BuildContext context, {
    required List<QueueItem> queues,
    required void Function(int index) onQueueSelected,
    required void Function(int index) onQueueRenamed,
    required void Function(int index) onQueueDeleted,
    required void Function(List<QueueItem> reordered) onReordered,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QueueDialog(
        queues: queues,
        onQueueSelected: onQueueSelected,
        onQueueRenamed: onQueueRenamed,
        onQueueDeleted: onQueueDeleted,
        onReordered: onReordered,
      ),
    );
  }

  @override
  State<QueueDialog> createState() => _QueueDialogState();
}

class _QueueDialogState extends State<QueueDialog> {
  late List<QueueItem> _queues;

  @override
  void initState() {
    super.initState();
    _queues = List.from(widget.queues);
  }

  void _showRenameDialog(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    final controller = TextEditingController(text: _queues[index].name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename queue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Queue name...',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _queues[index].name = newName);
                widget.onQueueRenamed(index);
              }
              Navigator.pop(context);
            },
            child: Text('Rename', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete queue?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${_queues[index].name}"? '
          'This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _queues.removeAt(index));
              widget.onQueueDeleted(index);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  'Queues',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Divider(height: 1, color: colors.divider),
              // Queue list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: _queues.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _queues.removeAt(oldIndex);
                      _queues.insert(newIndex, item);
                    });
                    widget.onReordered(_queues);
                  },
                  itemBuilder: (context, index) {
                    final queue = _queues[index];
                    return _QueueRow(
                      key: ValueKey(queue.name + index.toString()),
                      index: index,
                      queue: queue,
                      colors: colors,
                      onTap: () {
                        widget.onQueueSelected(index);
                        Navigator.of(context).pop();
                      },
                      onRename: () => _showRenameDialog(context, index, colors),
                      onDelete: () =>
                          _showDeleteConfirm(context, index, colors),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final int index;
  final QueueItem queue;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _QueueRow({
    super.key,
    required this.index,
    required this.queue,
    required this.colors,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Drag handle
            Icon(Icons.drag_handle, color: colors.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            // Index
            SizedBox(
              width: 20,
              child: Text(
                '${index + 1}',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // Playing indicator
            if (queue.isPlaying)
              Icon(Icons.play_arrow, size: 16, color: colors.accent)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 6),
            // Queue name
            Expanded(
              child: Text(
                queue.name,
                style: TextStyle(
                  fontSize: 15,
                  color: queue.isPlaying ? colors.accent : colors.onSurface,
                  fontWeight: queue.isPlaying
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Rename
            GestureDetector(
              onTap: onRename,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
