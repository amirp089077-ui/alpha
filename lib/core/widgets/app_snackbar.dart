import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';

enum SnackBarType { success, error, info }

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Color bg;
    Color icon;
    IconData iconData;

    switch (type) {
      case SnackBarType.success:
        bg = colors.isLight
            ? const Color(0xFF1A4A35)
            : const Color(0xFF12352A);
        icon = colors.mint;
        iconData = Icons.check_rounded;
        break;
      case SnackBarType.error:
        bg = colors.isLight
            ? const Color(0xFF4A1A1A)
            : const Color(0xFF351212);
        icon = colors.red;
        iconData = Icons.error_outline_rounded;
        break;
      case SnackBarType.info:
        bg = colors.isLight
            ? const Color(0xFF1A3A4A)
            : const Color(0xFF122535);
        icon = colors.blue;
        iconData = Icons.info_outline_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(milliseconds: 2500),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(iconData, color: icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
