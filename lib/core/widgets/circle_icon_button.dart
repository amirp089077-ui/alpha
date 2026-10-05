import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';

class CircleIconButton extends StatefulWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 48.0,
    this.iconSize = 24.0,
    this.isLoading = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final bool isLoading;
  final String? tooltip;

  @override
  State<CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<CircleIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(CircleIconButton old) {
    super.didUpdateWidget(old);
    if (widget.isLoading && !old.isLoading) {
      _spinCtrl.repeat();
    } else if (!widget.isLoading && old.isLoading) {
      _spinCtrl.stop();
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget iconWidget = Icon(
      widget.icon,
      size: widget.iconSize,
      color: colors.isLight ? colors.textSecondary : Colors.white.withValues(alpha: 0.85),
    );

    if (widget.isLoading) {
      iconWidget = RotationTransition(
        turns: _spinCtrl,
        child: iconWidget,
      );
    }

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onTap,
        borderRadius: BorderRadius.circular(widget.size / 2),
        splashColor: colors.blue.withValues(alpha: 0.15),
        child: Ink(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.isLight
                ? Colors.white
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
