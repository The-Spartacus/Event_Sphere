import 'dart:math' as math;
import 'package:flutter/material.dart';

class PlanetOrbitLoader extends StatefulWidget {
  final double size;
  final Color planetColor;
  final Color coreColor;
  final Duration duration;

  const PlanetOrbitLoader({
    super.key,
    this.size = 100,
    this.planetColor = Colors.white,
    this.coreColor = Colors.orangeAccent,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PlanetOrbitLoader> createState() => _PlanetOrbitLoaderState();
}

class _PlanetOrbitLoaderState extends State<PlanetOrbitLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PlanetPainter(
              progress: _controller.value,
              planetColor: widget.planetColor,
              coreColor: widget.coreColor,
            ),
          );
        },
      ),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  final double progress;
  final Color planetColor;
  final Color coreColor;

  _PlanetPainter({
    required this.progress,
    required this.planetColor,
    required this.coreColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final orbitRadius = radius * 0.8;

    // 1. Draw Orbit Path (Subtle)
    final orbitPaint = Paint()
      ..color = planetColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, orbitRadius, orbitPaint);

    // 2. Draw Central Core with Glow
    final corePaint = Paint()
      ..color = coreColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius * 0.25, corePaint);

    final coreSolidPaint = Paint()..color = coreColor;
    canvas.drawCircle(center, radius * 0.15, coreSolidPaint);

    // 3. Calculate Planet Position
    final angle = progress * 2 * math.pi;
    final planetX = center.dx + orbitRadius * math.cos(angle);
    final planetY = center.dy + orbitRadius * math.sin(angle);
    final planetPos = Offset(planetX, planetY);

    // 4. Draw Trail
    final trailPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0;
    for (int i = 0; i < 20; i++) {
        final trailAngle = angle - (i * 0.1);
        final tx = center.dx + orbitRadius * math.cos(trailAngle);
        final ty = center.dy + orbitRadius * math.sin(trailAngle);
        trailPaint.color = planetColor.withOpacity(1.0 - (i / 20.0));
        canvas.drawCircle(Offset(tx, ty), (4.0 - (i / 5.0)).clamp(0.5, 4.0), Paint()..color = trailPaint.color);
    }

    // 5. Draw Planet
    final planetPaint = Paint()
      ..color = planetColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(planetPos, 6.0, planetPaint);
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
