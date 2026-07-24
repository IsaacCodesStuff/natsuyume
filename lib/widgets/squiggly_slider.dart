// lib/widgets/squiggly_slider.dart — full replacement
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class M3ESquigglySlider extends StatefulWidget {
  final double value;
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
  double _dragValue = 0.0; // Track drag position independently

  @override
  void initState() {
    super.initState();
    _dragValue = widget.value;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isPlaying) _animationController.repeat();
  }

  @override
  void didUpdateWidget(covariant M3ESquigglySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) _dragValue = widget.value;
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

  void _handleDragStart(DragStartDetails details, BoxConstraints constraints) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final percent = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    setState(() {
      _isDragging = true;
      _dragValue = percent;
    });
    widget.onChangeStart?.call(percent);
    widget.onChanged(percent);
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final percent = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    setState(() => _dragValue = percent);
    widget.onChanged(percent);
  }

  void _handleDragEnd(DragEndDetails details) {
    // Capture dragValue before setState clears _isDragging
    final finalValue = _dragValue;
    setState(() => _isDragging = false);
    widget.onChangeEnd?.call(finalValue); // pass actual drag position
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _handleDragStart(d, constraints),
          onHorizontalDragUpdate: (d) => _handleDragUpdate(d, constraints),
          onHorizontalDragEnd: _handleDragEnd,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final displayValue = _isDragging ? _dragValue : widget.value;
              return CustomPaint(
                size: Size(constraints.maxWidth, 48),
                painter: _SquigglySliderPainter(
                  progress: displayValue,
                  phase: _animationController.value * 2 * math.pi,
                  isDragging: _isDragging,
                  activeColor: colors.onSurface,
                  inactiveColor: colors.surfaceVariant,
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
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final paintInactive = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final paintThumb = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    // Inactive track — flat line from thumb to end
    if (activeWidth < totalWidth) {
      canvas.drawLine(
        Offset(activeWidth, yCenter),
        Offset(totalWidth, yCenter),
        paintInactive,
      );
    }

    // Active track — squiggly when playing, flat when dragging or paused
    final activePath = Path();
    activePath.moveTo(0, yCenter);

    if (isDragging || activeWidth == 0 || !isDragging && progress >= 1.0) {
      activePath.lineTo(activeWidth, yCenter);
    } else {
      const waveLength = 36.0;
      const amplitude = 5.0;
      for (double x = 0; x <= activeWidth; x += 1.0) {
        final y =
            yCenter +
            math.sin((x / waveLength) * 2 * math.pi - phase) * amplitude;
        activePath.lineTo(x, y);
      }
    }
    canvas.drawPath(activePath, paintActive);

    // Thumb — vertical pill at the boundary
    const thumbWidth = 3.5;
    const thumbHeight = 22.0;
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
