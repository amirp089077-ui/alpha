import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';

enum GaugeType { volume, time }

class CircularGauge extends StatefulWidget {
  const CircularGauge({
    super.key,
    required this.progress,       // 0..1
    required this.centerValue,    // e.g. "۳۴٫۱"
    required this.centerUnit,     // e.g. "گیگ"
    this.gaugeType = GaugeType.volume,
    this.diameter = 134,
    this.strokeWidth = 12,
    this.animateOnBuild = true,
    this.isLow = false,
  });

  final double progress;
  final String centerValue;
  final String centerUnit;
  final GaugeType gaugeType;
  final double diameter;
  final double strokeWidth;
  final bool animateOnBuild;
  final bool isLow;

  @override
  State<CircularGauge> createState() => _CircularGaugeState();
}

class _CircularGaugeState extends State<CircularGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.animateOnBuild) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final disableAnims = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Gauge arc ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: disableAnims ? kAlwaysCompleteAnimation : _anim,
            builder: (_, __) => CustomPaint(
              size: Size(widget.diameter, widget.diameter),
              painter: _GaugePainter(
                progress: disableAnims ? widget.progress : widget.progress * _anim.value,
                gaugeType: widget.gaugeType,
                strokeWidth: widget.strokeWidth,
                trackColor: colors.trackGauge,
                isLow: widget.isLow,
              ),
            ),
          ),

          // ── Center text ───────────────────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedCountUp(
                target: widget.centerValue,
                style: AppTypography.display.copyWith(
                  color: colors.textPrimary,
                  fontSize: widget.diameter < 80 ? 18 : 32,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.centerUnit,
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Gauge painter ────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double progress;
  final GaugeType gaugeType;
  final double strokeWidth;
  final Color trackColor;
  final bool isLow;

  _GaugePainter({
    required this.progress,
    required this.gaugeType,
    required this.strokeWidth,
    required this.trackColor,
    required this.isLow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    // ── Volume gauge: mint gradient ───────────────────────────────────
    if (gaugeType == GaugeType.volume) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: const [Color(0xFF8AEBC8), Color(0xFF5CD6AB)],
          tileMode: TileMode.clamp,
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);
    }

    // ── Time gauge: grey→blue with orange halo ────────────────────────
    if (gaugeType == GaugeType.time) {
      // Orange halo (outline) — drawn first so it's behind
      final haloPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6B3F32).withOpacity(isLow ? 0.9 : 0.70);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, haloPaint);

      // Gradient arc on top
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: const [Color(0xFF8C8B80), Color(0xFF5BB5D8)],
          tileMode: TileMode.clamp,
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.isLow != isLow;
}

// ─── Animated count-up text ───────────────────────────────────────────────────
class _AnimatedCountUp extends StatelessWidget {
  const _AnimatedCountUp({required this.target, required this.style});
  final String target;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Text(
        target,
        key: ValueKey(target),
        style: style,
      ),
    );
  }
}

/// Smaller gauge used on the home screen
class MiniCircularGauge extends StatelessWidget {
  const MiniCircularGauge({
    super.key,
    required this.progress,
    required this.gaugeType,
  });

  final double progress;
  final GaugeType gaugeType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: progress,
          gaugeType: gaugeType,
          strokeWidth: 5,
          trackColor: Theme.of(context).extension<AppColors>()!.trackGauge,
          isLow: progress < 0.15,
        ),
      ),
    );
  }
}
