import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.useLoginGradient = false,
    this.height = 56.0,
    this.radius = 20.0,
    this.fontSize = 17.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final bool useLoginGradient;
  final double height;
  final double radius;
  final double fontSize;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _interactive => !widget.isLoading && !widget.isDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final gradient = widget.useLoginGradient
        ? colors.loginGradient
        : colors.brandGradient;

    final shadow = colors.isLight && !widget.isDisabled
        ? BoxShadow(
            color: const Color(0xFFD4501A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        : null;

    return GestureDetector(
      onTapDown: _interactive ? (_) => _ctrl.forward() : null,
      onTapUp: _interactive
          ? (_) {
              _ctrl.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _interactive ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Opacity(
          opacity: widget.isDisabled ? 0.5 : 1.0,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: shadow != null ? [shadow] : null,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      key: const ValueKey('label'),
                      widget.label,
                      style: AppTypography.title3.copyWith(
                        color: Colors.white,
                        fontSize: widget.fontSize,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
