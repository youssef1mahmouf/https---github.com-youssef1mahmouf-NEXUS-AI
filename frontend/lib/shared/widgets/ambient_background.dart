import 'dart:math' as math;

import 'package:flutter/material.dart';

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    required this.isDark,
  });
  final Widget child;
  final bool isDark;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? const [
                      Color(0xFF070312),
                      Color(0xFF120826),
                      Color(0xFF0A0E27),
                    ]
                  : const [
                      Color(0xFFF3EEFF),
                      Color(0xFFE9E3FF),
                      Color(0xFFEAF2FF),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // ambient glows
              Positioned(
                top: -120,
                left: -80,
                child: _glow(
                  widget.isDark
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFA78BFA),
                  320,
                  0.35,
                ),
              ),
              Positioned(
                bottom: -160,
                right: -100,
                child: _glow(
                  widget.isDark
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF818CF8),
                  360,
                  0.3,
                ),
              ),
              Positioned(
                top: 200,
                right: 120,
                child: _glow(
                  widget.isDark
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF93C5FD),
                  200,
                  0.18,
                ),
              ),
              // particles
              CustomPaint(
                painter: _ParticlePainter(_ctrl.value, widget.isDark),
                size: Size.infinite,
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }

  Widget _glow(Color c, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            c.withValues(alpha: opacity),
            c.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.t, this.isDark);
  final double t;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rnd = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final speed = 0.2 + rnd.nextDouble() * 0.6;
      final x = (baseX + math.sin((t + i) * speed) * 18) % size.width;
      final y = (baseY + math.cos((t + i) * speed * 0.7) * 18) % size.height;
      final r = 0.6 + rnd.nextDouble() * 1.6;
      final alpha = isDark ? 0.35 : 0.25;
      paint.color = (isDark ? Colors.white : const Color(0xFF4F46E5))
          .withValues(alpha: alpha * (0.4 + rnd.nextDouble() * 0.6));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
