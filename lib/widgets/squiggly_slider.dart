import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class M3ESquigglySlider extends StatefulWidget {
  final double value; // From 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final bool isPlaying;

  const M3ESquigglySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.isPlaying = true,
  });

  @override
  State<M3ESquigglySlider> createState() => _M3ESquigglySliderState();
}

class _M3ESquigglySliderState extends State<M3ESquigglySlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isPlaying) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant M3ESquigglySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!widget.isPlaying && _animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final percent = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    widget.onChanged(percent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final activeColor = colors.onSurface;
    final inactiveColor = colors.surfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() => _isDragging = true);
            widget.onChangeStart?.call(widget.value);
          },
          onHorizontalDragUpdate: (details) =>
              _handleDragUpdate(details, constraints),
          onHorizontalDragEnd: (details) {
            setState(() => _isDragging = false);
            widget.onChangeEnd?.call(widget.value);
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(
                  constraints.maxWidth,
                  48,
                ), // Large 48dp M3 touch target
                painter: _SquigglySliderPainter(
                  progress: widget.value,
                  phase: _animationController.value * 2 * math.pi,
                  isDragging: _isDragging,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SquigglySliderPainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool isDragging;
  final Color activeColor;
  final Color inactiveColor;

  _SquigglySliderPainter({
    required this.progress,
    required this.phase,
    required this.isDragging,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final yCenter = size.height / 2;
    final totalWidth = size.width;
    final activeWidth = totalWidth * progress;

    final paintActive = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final paintInactive = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final paintThumb = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    // 1. Draw Inactive Track (The remaining unplayed flat line)
    if (activeWidth < totalWidth) {
      canvas.drawLine(
        Offset(activeWidth, yCenter),
        Offset(totalWidth, yCenter),
        paintInactive,
      );
    }

    // 2. Draw Active Track (The squiggly line)
    final activePath = Path();

    if (isDragging || activeWidth == 0) {
      // Flatten the line if the user is scrubbing (M3 Design Rule)
      activePath.moveTo(0, yCenter);
      activePath.lineTo(activeWidth, yCenter);
    } else {
      // Draw sine wave path
      activePath.moveTo(0, yCenter);

      const waveLength = 40.0; // Horizontal width of a full single wave loop
      const amplitude = 6.0; // Height of the ripple waves

      for (double x = 0; x <= activeWidth; x++) {
        // Calculate the sine coordinate relative to the animated phase
        final double y =
            yCenter +
            math.sin((x / waveLength) * 2 * math.pi - phase) * amplitude;
        activePath.lineTo(x, y);
      }
    }
    canvas.drawPath(activePath, paintActive);

    // 3. Draw The Handle (Material 3 vertical "Pill" scrubber)
    const thumbWidth = 4.0;
    const thumbHeight = 20.0;
    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(activeWidth, yCenter),
        width: thumbWidth,
        height: thumbHeight,
      ),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(thumbRect, paintThumb);
  }

  @override
  bool shouldRepaint(covariant _SquigglySliderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
