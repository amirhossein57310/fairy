import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidLinearProgressIndicator extends StatefulWidget {
  const LiquidLinearProgressIndicator({
    super.key,
    required this.value,
    this.valueColor,
    this.valueGradient,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.borderRadius = 0.0,
    this.direction = Axis.horizontal,
    this.center,
    this.waveAmplitudeFactor = 0.06,
    this.waveLengthFactor = 1.2,
    this.speed = const Duration(milliseconds: 2000),
  });

  final double value;
  final Animation<Color?>? valueColor;
  final Gradient? valueGradient;
  final Color? backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Axis direction;
  final Widget? center;
  final double waveAmplitudeFactor;
  final double waveLengthFactor;
  final Duration speed;

  @override
  State<LiquidLinearProgressIndicator> createState() =>
      _LiquidLinearProgressIndicatorState();
}

class _LiquidLinearProgressIndicatorState
    extends State<LiquidLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.speed,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bg =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: CustomPaint(
        painter: _BorderPainter(
          color: widget.borderColor,
          width: widget.borderWidth,
          radius: widget.borderRadius,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _LiquidPainter(
                value: widget.value.clamp(0.0, 1.0),
                phase: _controller.value * 2 * math.pi,
                color: widget.valueColor?.value ??
                    Theme.of(context).colorScheme.primary,
                gradient: widget.valueGradient,
                backgroundColor: bg,
                vertical: widget.direction == Axis.vertical,
                amplitudeFactor: widget.waveAmplitudeFactor,
                wavelengthFactor: widget.waveLengthFactor,
              ),
              child: Center(child: widget.center),
            );
          },
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter(
      {required this.color, required this.width, required this.radius});
  final Color color;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.radius != radius;
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.value,
    required this.phase,
    required this.color,
    this.gradient,
    required this.backgroundColor,
    required this.vertical,
    required this.amplitudeFactor,
    required this.wavelengthFactor,
  });

  final double value;
  final double phase;
  final Color color;
  final Gradient? gradient;
  final Color backgroundColor;
  final bool vertical;
  final double amplitudeFactor;
  final double wavelengthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final rect = Offset.zero & size;
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(rect, bgPaint);

    // Wave params
    final amplitude = (vertical ? size.width : size.height) * amplitudeFactor;
    final wavelength = (vertical ? size.height : size.width) / wavelengthFactor;
    final baseline = (vertical ? size.height : size.width) * (1.0 - value);

    final path = Path();

    if (vertical) {
      // Build wave across width at baseline and fill down to bottom so liquid starts from bottom
      final double startY = baseline;
      path.moveTo(0, size.height);
      path.lineTo(0, startY);
      for (double x = 0; x <= size.width; x += 1) {
        final y =
            startY + amplitude * math.sin(2 * math.pi * x / wavelength + phase);
        final clampedY = y.clamp(0.0, size.height);
        path.lineTo(x, clampedY.toDouble());
      }
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, size.height);
      path.lineTo(baseline, size.height);
      for (double x = 0; x <= size.width; x += 1) {
        final y = amplitude * math.sin(2 * math.pi * x / wavelength + phase) +
            baseline;
        final clampedY = y.clamp(0.0, size.height);
        if (x == 0) path.moveTo(x, size.height - clampedY);
        path.lineTo(x, size.height - clampedY.toDouble());
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
    }

    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.vertical != vertical;
  }
}
