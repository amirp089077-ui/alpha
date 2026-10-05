import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';

enum GlowMode { neutral, connected, warning }

class GradientBackground extends StatefulWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.glowMode = GlowMode.neutral,
  });

  final Widget child;
  final GlowMode glowMode;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Fixed star positions (seed = 42)
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buildStars();
  }

  void _buildStars() {
    final rng = math.Random(42);
    _stars = List.generate(35, (_) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.0 + rng.nextDouble(),
        opacity: 0.10 + rng.nextDouble() * 0.25,
      );
    });
  }

  @override
  void didUpdateWidget(GradientBackground old) {
    super.didUpdateWidget(old);
    if (old.glowMode != widget.glowMode) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final disableAnims = MediaQuery.of(context).disableAnimations;

    Color topGlow;
    switch (widget.glowMode) {
      case GlowMode.connected:
        topGlow = colors.glowConnected;
        break;
      case GlowMode.warning:
        topGlow = colors.orange.withOpacity(0.30);
        break;
      case GlowMode.neutral:
        topGlow = colors.glowBlue;
        break;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Base gradient ─────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.bgTop, colors.bgBase, colors.bgBottom],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),

        // ── Top-left blue/green glow ──────────────────────────────────────
        Positioned(
          top: -80,
          left: -80,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: topGlow.withOpacity(disableAnims ? topGlow.opacity : 0.35)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, color, __) => Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color ?? topGlow, Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        // ── Warm glow (center-right / bottom) ────────────────────────────
        if (!colors.isLight)
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.glowWarm.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // ── Stars (dark theme only) ───────────────────────────────────────
        if (!colors.isLight)
          CustomPaint(painter: _StarsPainter(_stars)),

        // ── Content ───────────────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

class _Star {
  final double x, y, size, opacity;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  _StarsPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(s.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}
