import 'package:flutter/material.dart';

// ─── Dark Theme Tokens ────────────────────────────────────────────────────────
class AppColorsDark {
  static const bgBase    = Color(0xFF0A1620);
  static const bgTop     = Color(0xFF0C2230);
  static const bgBottom  = Color(0xFF0B1118);

  static const glowBlue      = Color(0xFF1E6F8F);  // 35% opacity
  static const glowWarm      = Color(0xFF7A3B1E);  // 25% opacity
  static const glowConnected = Color(0xFF1F8A66);  // 30% opacity

  static const card            = Color(0xFF111E29); // white@5% on bg
  static const cardBorder      = Color(0x17FFFFFF); // white@9%
  static const cardBorderStrong= Color(0xFF2B5A74);

  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9FB3BF);
  static const textTertiary  = Color(0xFF6E8493);

  static const divider = Color(0x14FFFFFF); // white@8%

  static const blue       = Color(0xFF4FB3E0);
  static const blueLight  = Color(0xFF7FD8EE);
  static const orange     = Color(0xFFF0693A);
  static const mint       = Color(0xFF6EE0B5);
  static const green      = Color(0xFF5FD38D);
  static const red        = Color(0xFFE5534B);

  static const chipBg   = Color(0xFF17384B);
  static const chipText = Color(0xFF4FB3E0);

  static const iconTileBlue   = Color(0xFF173446);
  static const iconTileGreen  = Color(0xFF173A33);
  static const iconTileRed    = Color(0xFF3A1E2A);
  static const iconTileOrange = Color(0xFF3A2A26);

  static const navGlass  = Color(0xBF1B2C38); // 75% opacity
  static const navBorder = Color(0x1FFFFFFF); // white@12%

  static const trackGauge = Color(0xFF27383F);

  // Brand gradient stops
  static const gradientStart  = Color(0xFF4FB3E0);
  static const gradientMid    = Color(0xFFA98B78);
  static const gradientEnd    = Color(0xFFF0693A);
}

// ─── Light Theme Tokens ───────────────────────────────────────────────────────
class AppColorsLight {
  static const bgBase   = Color(0xFFF3F9FC);
  static const bgLight1 = Color(0xFFD3EBF3); // top-left glow
  static const bgLight2 = Color(0xFFFBEDE6); // center peach (50% transparent)

  static const card       = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE4ECF1);

  static const textPrimary   = Color(0xFF0E2233);
  static const textSecondary = Color(0xFF5B7284);
  static const textTertiary  = Color(0xFF8EA1AF);

  static const teal   = Color(0xFF0E87A8);
  static const blue   = Color(0xFF1A9BC4);
  static const orange = Color(0xFFD9531C);

  static const fieldBorder = Color(0xFFE3EAF0);
  static const chipBg      = Color(0xFFE3F2F8);

  static const navGlass  = Color(0xB3FFFFFF); // white@70%
  static const navBorder = Color(0xFFDCE7ED);

  static const trackGauge = Color(0xFFDCEBF2);

  // Brand gradient (same as dark but slightly richer)
  static const gradientStart = Color(0xFF1A9BC4);
  static const gradientMid   = Color(0xFFA98B78);
  static const gradientEnd   = Color(0xFFD9531C);
}

// ─── Shared colors (same in both themes) ─────────────────────────────────────
class AppColorsShared {
  static const mint   = Color(0xFF6EE0B5);
  static const green  = Color(0xFF5FD38D);
  static const red    = Color(0xFFE5534B);
  static const orange = Color(0xFFF0693A);
  static const blue   = Color(0xFF4FB3E0);

  static const badgeRed   = Color(0xFFE5483D);
  static const ipv6Green1 = Color(0xFF9BF29B);
  static const ipv6Green2 = Color(0xFF2FA84F);

  static LinearGradient brandGradient({bool lightTheme = false}) {
    return LinearGradient(
      colors: lightTheme
          ? [AppColorsLight.gradientStart, AppColorsLight.gradientMid, AppColorsLight.gradientEnd]
          : [AppColorsDark.gradientStart, AppColorsDark.gradientMid, AppColorsDark.gradientEnd],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  static LinearGradient loginButtonGradient() {
    return const LinearGradient(
      colors: [Color(0xFF0E7FA3), Color(0xFFD4501A)],
    );
  }
}
