import 'dart:math' as math;

import 'package:flutter/material.dart';

class HolographicOrb extends StatefulWidget {
  const HolographicOrb({super.key, this.size = 220});
  final double size;

  @override
  State<HolographicOrb> createState() => _HolographicOrbState();
}

class _HolographicOrbState extends State<HolographicOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pulse = 0.92 + 0.08 * math.sin(_ctrl.value * 2 * math.pi);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // outer glow
              Container(
                width: widget.size * 1.35 * pulse,
                height: widget.size * 1.35 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                      scheme.tertiary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // rings
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(_ctrl.value, scheme, isDark),
              ),
              // core
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: widget.size * 0.42,
                  height: widget.size * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.9 : 0.95),
                        scheme.primary,
                        scheme.tertiary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.6),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: isDark ? Colors.white : scheme.onPrimary,
                    size: widget.size * 0.18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.scheme, this.isDark);
  final double t;
  final ColorScheme scheme;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Guard against invalid or zero dimensions during layout transitions
    // (e.g., AnimatedSwitcher removing the widget). Painting with a zero
    // radius creates a degenerate rect that triggers a dart:ui assertion.
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    if (!t.isFinite) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 3; i++) {
      final r = (maxR * (0.55 + i * 0.15)).clamp(0.01, double.infinity);

      // Validate every shader input before creating the shader. A non-finite or
      // degenerate centre/radius (e.g. NaN or Infinity surviving a layout
      // transition such as AnimatedSwitcher) makes Rect.fromCircle /
      // createShader hit the dart:ui painting assertion and crash the
      // renderer. Skip this ring rather than painting invalid geometry.
      if (!center.dx.isFinite || !center.dy.isFinite) {
        continue;
      }
      if (!r.isFinite || r <= 0) {
        continue;
      }
      final shaderRect = Rect.fromCircle(center: center, radius: r);
      if (!shaderRect.left.isFinite ||
          !shaderRect.top.isFinite ||
          !shaderRect.right.isFinite ||
          !shaderRect.bottom.isFinite ||
          shaderRect.width <= 0 ||
          shaderRect.height <= 0) {
        continue;
      }

      // The engine's Gradient.sweep asserts startAngle < endAngle
      // (endAngle defaults to 2π). Because sweep angles wrap every 2π,
      // normalize startAngle into [0, 2π) so the assertion always holds
      // while keeping the gradient (and the drawn arc) angularly identical.
      final startAngle = (t * 2 * math.pi + i) % (2 * math.pi);
      final sweep = math.pi * (1.2 + 0.4 * math.sin(startAngle));
      paint.shader = SweepGradient(
        startAngle: startAngle,
        colors: [
          scheme.primary.withValues(alpha: 0.0),
          scheme.primary.withValues(alpha: isDark ? 0.7 : 0.5),
          scheme.tertiary.withValues(alpha: 0.0),
        ],
      ).createShader(shaderRect);
      canvas.drawArc(shaderRect, startAngle, sweep, false, paint);
    }
    // dotted orbit
    final dotPaint = Paint()..color = scheme.primary.withValues(alpha: 0.6);
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * math.pi + t * 2 * math.pi;
      final r = (maxR * 0.88).clamp(0.01, double.infinity);
      canvas.drawCircle(
        Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a)),
        2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t;
}
