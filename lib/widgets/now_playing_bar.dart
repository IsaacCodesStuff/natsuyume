import 'package:flutter/material.dart';

class NowPlayingBars extends StatefulWidget {
  final Color color;
  final bool isPlaying;
  final double barWidth;
  final double maxHeight;

  const NowPlayingBars({
    super.key,
    required this.color,
    required this.isPlaying,
    this.barWidth = 3,
    this.maxHeight = 16,
  });

  @override
  State<NowPlayingBars> createState() => _NowPlayingBarsState();
}

class _NowPlayingBarsState extends State<NowPlayingBars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  // Different speeds per bar for a natural feel
  static const List<Duration> _durations = [
    Duration(milliseconds: 400),
    Duration(milliseconds: 300),
    Duration(milliseconds: 500),
    Duration(milliseconds: 350),
    Duration(milliseconds: 450),
  ];

  // Different min heights per bar
  static const List<double> _minHeights = [0.3, 0.5, 0.2, 0.6, 0.3];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (i) {
      return AnimationController(vsync: this, duration: _durations[i]);
    });

    _animations = List.generate(5, (i) {
      return Tween<double>(begin: _minHeights[i], end: 1.0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    if (widget.isPlaying) _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 60), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (final controller in _controllers) {
      controller.stop();
    }
  }

  @override
  void didUpdateWidget(NowPlayingBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? 2 : 0),
          child: AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                width: widget.barWidth,
                height: widget.maxHeight * _animations[i].value,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
