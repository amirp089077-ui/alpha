import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 28.0,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradientBorder = false,
    this.selected = false,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;
  final bool gradientBorder;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final borderColor = widget.selected
        ? colors.cardBorderStrong
        : (widget.borderColor ?? colors.cardBorder);

    final shadow = colors.cardShadow;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(widget.radius),
            border: widget.gradientBorder
                ? null
                : Border.all(color: borderColor, width: widget.borderWidth),
            boxShadow: shadow != null ? [shadow] : null,
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    if (widget.gradientBorder) {
      card = _GradientBorderWrapper(
        radius: widget.radius,
        borderWidth: widget.borderWidth,
        child: card,
      );
    }

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: ScaleTransition(scale: _scaleAnim, child: card),
      );
    }

    return Container(
      margin: widget.margin,
      child: card,
    );
  }
}

// ─── Gradient border wrapper ──────────────────────────────────────────────────
class _GradientBorderWrapper extends StatelessWidget {
  const _GradientBorderWrapper({
    required this.child,
    required this.radius,
    required this.borderWidth,
  });

  final Widget child;
  final double radius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return CustomPaint(
      painter: _GradientBorderPainter(
        radius: radius,
        borderWidth: borderWidth,
        gradient: colors.brandGradient,
      ),
      child: child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double borderWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..isAntiAlias = true;
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) =>
      old.radius != radius || old.borderWidth != borderWidth;
}
