import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';

/// App logo mark: outer gradient ring + inner "A" symbol drawn via CustomPainter.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 120.0,
    this.ringWidth = 3.0,
    this.showGlow = true,
  });

  final double size;
  final double ringWidth;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Glow behind ring (dark theme only) ───────────────────────
          if (showGlow && !colors.isLight)
            Container(
              width: size + 24,
              height: size + 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.blue.withOpacity(0.30),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),

          // ── Frosted circle background ────────────────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors.isLight
                    ? [
                        Colors.white.withOpacity(0.85),
                        const Color(0xFFD8EEF5).withOpacity(0.6),
                      ]
                    : [
                        const Color(0xFF1A3A50).withOpacity(0.85),
                        const Color(0xFF0D1E2C).withOpacity(0.7),
                      ],
              ),
              border: Border.all(
                color: colors.isLight
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white.withOpacity(0.12),
                width: 1.5,
              ),
            ),
          ),

          // ── Gradient ring (outer arc) ────────────────────────────────
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(ringWidth: ringWidth),
          ),

          // ── Inner "A" symbol ─────────────────────────────────────────
          CustomPaint(
            size: Size(size * 0.6, size * 0.6),
            painter: _AlphaSymbolPainter(colors: colors),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient ring painter ────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double ringWidth;
  _RingPainter({required this.ringWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - ringWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Main thin ring: blue top-left → grey → orange bottom-right
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..isAntiAlias = true
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Color(0xFF4FB3E0),
          Color(0xFF8BA5B5),
          Color(0xFFF0693A),
          Color(0xFFF0693A),
          Color(0xFF4FB3E0),
        ],
        stops: [0.0, 0.4, 0.75, 0.90, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, ringPaint);

    // Thick orange arc at bottom-right (highlight)
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth * 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = const Color(0xFFF0693A);
    canvas.drawArc(
      rect,
      math.pi * 0.55,   // start: ~bottom-right
      math.pi * 0.18,   // sweep
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ringWidth != ringWidth;
}

// ─── Alpha "A" symbol painter ─────────────────────────────────────────────────
class _AlphaSymbolPainter extends CustomPainter {
  final AppColors colors;
  _AlphaSymbolPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Blue/teal left wing of the "A" ──────────────────────────────
    final bluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF4FB3E0)
      ..isAntiAlias = true;

    final leftPath = Path()
      ..moveTo(cx, h * 0.12)
      ..quadraticBezierTo(cx - w * 0.08, h * 0.45, cx - w * 0.30, h * 0.82)
      ..quadraticBezierTo(cx - w * 0.42, h * 0.95, cx - w * 0.48, h * 0.88);
    canvas.drawPath(leftPath, bluePaint);

    final rightPath = Path()
      ..moveTo(cx, h * 0.12)
      ..quadraticBezierTo(cx + w * 0.08, h * 0.45, cx + w * 0.30, h * 0.82)
      ..quadraticBezierTo(cx + w * 0.42, h * 0.95, cx + w * 0.48, h * 0.88);
    canvas.drawPath(rightPath, bluePaint);

    // ── Orange V bottom ──────────────────────────────────────────────
    final orangePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFF0693A)
      ..isAntiAlias = true;

    final vPath = Path()
      ..moveTo(cx - w * 0.28, h * 0.52)
      ..quadraticBezierTo(cx, h * 0.78, cx + w * 0.00, h * 0.70)
      ..quadraticBezierTo(cx, h * 0.78, cx + w * 0.28, h * 0.52);
    canvas.drawPath(vPath, orangePaint);

    // ── Glow on the blue paths (light effect) ───────────────────────
    if (!colors.isLight) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.18
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF4FB3E0).withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..isAntiAlias = true;
      canvas.drawPath(leftPath, glowPaint);
      canvas.drawPath(rightPath, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_AlphaSymbolPainter old) => false;
}
