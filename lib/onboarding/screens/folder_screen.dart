import 'package:flutter/material.dart';

class FolderScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FolderScreen({super.key, required this.onNext, required this.onBack});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final List<String> _folders = [];

  void _addFolder() {
    // Placeholder — real folder picker will be wired in 0.8.x
    setState(() {
      _folders.add('/storage/emulated/0/Music');
    });
  }

  void _removeFolder(int index) {
    setState(() {
      _folders.removeAt(index);
    });
  }

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
                'Add a folder',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFD0C4E8),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Scanned folders',
                style: TextStyle(fontSize: 14, color: Color(0xFF9A8FB0)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _folders.isEmpty
                    ? const Center(
                        child: Text(
                          'No folders added yet.',
                          style: TextStyle(
                            color: Color(0xFF6A6080),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _folders.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: Color(0xFF3A3850), height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            title: Text(
                              _folders[index],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFC0B4D8),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color(0xFF9A8FB0),
                              ),
                              onPressed: () => _removeFolder(index),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addFolder,
                  icon: const Icon(Icons.add, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Add more...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A3850),
                    foregroundColor: const Color(0xFFB0A4C8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                ),
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
