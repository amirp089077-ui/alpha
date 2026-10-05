import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ThemeExtension so widgets can do:
///   Theme.of(context).extension<AppColors>()!.blue
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgBase,
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.cardBorder,
    required this.cardBorderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.blue,
    required this.blueLight,
    required this.orange,
    required this.mint,
    required this.green,
    required this.red,
    required this.chipBg,
    required this.chipText,
    required this.iconTileBlue,
    required this.iconTileGreen,
    required this.iconTileRed,
    required this.iconTileOrange,
    required this.navGlass,
    required this.navBorder,
    required this.trackGauge,
    required this.glowBlue,
    required this.glowWarm,
    required this.glowConnected,
    required this.fieldBorder,
    required this.teal,
    required this.isLight,
  });

  final Color bgBase;
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color cardBorder;
  final Color cardBorderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color blue;
  final Color blueLight;
  final Color orange;
  final Color mint;
  final Color green;
  final Color red;
  final Color chipBg;
  final Color chipText;
  final Color iconTileBlue;
  final Color iconTileGreen;
  final Color iconTileRed;
  final Color iconTileOrange;
  final Color navGlass;
  final Color navBorder;
  final Color trackGauge;
  final Color glowBlue;
  final Color glowWarm;
  final Color glowConnected;
  final Color fieldBorder;
  final Color teal;
  final bool isLight;

  // ─── Presets ────────────────────────────────────────────────────────────
  static const dark = AppColors(
    bgBase:           AppColorsDark.bgBase,
    bgTop:            AppColorsDark.bgTop,
    bgBottom:         AppColorsDark.bgBottom,
    card:             AppColorsDark.card,
    cardBorder:       AppColorsDark.cardBorder,
    cardBorderStrong: AppColorsDark.cardBorderStrong,
    textPrimary:      AppColorsDark.textPrimary,
    textSecondary:    AppColorsDark.textSecondary,
    textTertiary:     AppColorsDark.textTertiary,
    divider:          AppColorsDark.divider,
    blue:             AppColorsDark.blue,
    blueLight:        AppColorsDark.blueLight,
    orange:           AppColorsDark.orange,
    mint:             AppColorsDark.mint,
    green:            AppColorsDark.green,
    red:              AppColorsDark.red,
    chipBg:           AppColorsDark.chipBg,
    chipText:         AppColorsDark.chipText,
    iconTileBlue:     AppColorsDark.iconTileBlue,
    iconTileGreen:    AppColorsDark.iconTileGreen,
    iconTileRed:      AppColorsDark.iconTileRed,
    iconTileOrange:   AppColorsDark.iconTileOrange,
    navGlass:         AppColorsDark.navGlass,
    navBorder:        AppColorsDark.navBorder,
    trackGauge:       AppColorsDark.trackGauge,
    glowBlue:         AppColorsDark.glowBlue,
    glowWarm:         AppColorsDark.glowWarm,
    glowConnected:    AppColorsDark.glowConnected,
    fieldBorder:      AppColorsDark.cardBorder,
    teal:             AppColorsDark.blue,
    isLight:          false,
  );

  static const light = AppColors(
    bgBase:           AppColorsLight.bgBase,
    bgTop:            AppColorsLight.bgLight1,
    bgBottom:         AppColorsLight.bgBase,
    card:             AppColorsLight.card,
    cardBorder:       AppColorsLight.cardBorder,
    cardBorderStrong: AppColorsLight.teal,
    textPrimary:      AppColorsLight.textPrimary,
    textSecondary:    AppColorsLight.textSecondary,
    textTertiary:     AppColorsLight.textTertiary,
    divider:          AppColorsLight.cardBorder,
    blue:             AppColorsLight.blue,
    blueLight:        AppColorsLight.teal,
    orange:           AppColorsLight.orange,
    mint:             AppColorsShared.mint,
    green:            AppColorsShared.green,
    red:              AppColorsShared.red,
    chipBg:           AppColorsLight.chipBg,
    chipText:         AppColorsLight.teal,
    iconTileBlue:     Color(0xFFD3EBF3),
    iconTileGreen:    Color(0xFFD0F0E3),
    iconTileRed:      Color(0xFFFAE0DE),
    iconTileOrange:   Color(0xFFFAEADE),
    navGlass:         AppColorsLight.navGlass,
    navBorder:        AppColorsLight.navBorder,
    trackGauge:       AppColorsLight.trackGauge,
    glowBlue:         Color(0xFF1E6F8F),
    glowWarm:         Color(0xFF7A3B1E),
    glowConnected:    Color(0xFF1F8A66),
    fieldBorder:      AppColorsLight.fieldBorder,
    teal:             AppColorsLight.teal,
    isLight:          true,
  );

  // ─── Gradient helpers ────────────────────────────────────────────────────
  LinearGradient get brandGradient => AppColorsShared.brandGradient(lightTheme: isLight);

  LinearGradient get loginGradient => AppColorsShared.loginButtonGradient();

  BoxShadow? get cardShadow => isLight
      ? const BoxShadow(
          color: Color(0x1A1B5E7A),
          blurRadius: 30,
          offset: Offset(0, 10),
        )
      : null;

  @override
  AppColors copyWith({
    Color? bgBase, Color? bgTop, Color? bgBottom,
    Color? card, Color? cardBorder, Color? cardBorderStrong,
    Color? textPrimary, Color? textSecondary, Color? textTertiary,
    Color? divider, Color? blue, Color? blueLight, Color? orange,
    Color? mint, Color? green, Color? red,
    Color? chipBg, Color? chipText,
    Color? iconTileBlue, Color? iconTileGreen, Color? iconTileRed, Color? iconTileOrange,
    Color? navGlass, Color? navBorder, Color? trackGauge,
    Color? glowBlue, Color? glowWarm, Color? glowConnected,
    Color? fieldBorder, Color? teal, bool? isLight,
  }) {
    return AppColors(
      bgBase:           bgBase           ?? this.bgBase,
      bgTop:            bgTop            ?? this.bgTop,
      bgBottom:         bgBottom         ?? this.bgBottom,
      card:             card             ?? this.card,
      cardBorder:       cardBorder       ?? this.cardBorder,
      cardBorderStrong: cardBorderStrong ?? this.cardBorderStrong,
      textPrimary:      textPrimary      ?? this.textPrimary,
      textSecondary:    textSecondary    ?? this.textSecondary,
      textTertiary:     textTertiary     ?? this.textTertiary,
      divider:          divider          ?? this.divider,
      blue:             blue             ?? this.blue,
      blueLight:        blueLight        ?? this.blueLight,
      orange:           orange           ?? this.orange,
      mint:             mint             ?? this.mint,
      green:            green            ?? this.green,
      red:              red              ?? this.red,
      chipBg:           chipBg           ?? this.chipBg,
      chipText:         chipText         ?? this.chipText,
      iconTileBlue:     iconTileBlue     ?? this.iconTileBlue,
      iconTileGreen:    iconTileGreen    ?? this.iconTileGreen,
      iconTileRed:      iconTileRed      ?? this.iconTileRed,
      iconTileOrange:   iconTileOrange   ?? this.iconTileOrange,
      navGlass:         navGlass         ?? this.navGlass,
      navBorder:        navBorder        ?? this.navBorder,
      trackGauge:       trackGauge       ?? this.trackGauge,
      glowBlue:         glowBlue         ?? this.glowBlue,
      glowWarm:         glowWarm         ?? this.glowWarm,
      glowConnected:    glowConnected    ?? this.glowConnected,
      fieldBorder:      fieldBorder      ?? this.fieldBorder,
      teal:             teal             ?? this.teal,
      isLight:          isLight          ?? this.isLight,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgBase:           Color.lerp(bgBase,           other.bgBase,           t)!,
      bgTop:            Color.lerp(bgTop,            other.bgTop,            t)!,
      bgBottom:         Color.lerp(bgBottom,         other.bgBottom,         t)!,
      card:             Color.lerp(card,             other.card,             t)!,
      cardBorder:       Color.lerp(cardBorder,       other.cardBorder,       t)!,
      cardBorderStrong: Color.lerp(cardBorderStrong, other.cardBorderStrong, t)!,
      textPrimary:      Color.lerp(textPrimary,      other.textPrimary,      t)!,
      textSecondary:    Color.lerp(textSecondary,    other.textSecondary,    t)!,
      textTertiary:     Color.lerp(textTertiary,     other.textTertiary,     t)!,
      divider:          Color.lerp(divider,          other.divider,          t)!,
      blue:             Color.lerp(blue,             other.blue,             t)!,
      blueLight:        Color.lerp(blueLight,        other.blueLight,        t)!,
      orange:           Color.lerp(orange,           other.orange,           t)!,
      mint:             Color.lerp(mint,             other.mint,             t)!,
      green:            Color.lerp(green,            other.green,            t)!,
      red:              Color.lerp(red,              other.red,              t)!,
      chipBg:           Color.lerp(chipBg,           other.chipBg,           t)!,
      chipText:         Color.lerp(chipText,         other.chipText,         t)!,
      iconTileBlue:     Color.lerp(iconTileBlue,     other.iconTileBlue,     t)!,
      iconTileGreen:    Color.lerp(iconTileGreen,    other.iconTileGreen,    t)!,
      iconTileRed:      Color.lerp(iconTileRed,      other.iconTileRed,      t)!,
      iconTileOrange:   Color.lerp(iconTileOrange,   other.iconTileOrange,   t)!,
      navGlass:         Color.lerp(navGlass,         other.navGlass,         t)!,
      navBorder:        Color.lerp(navBorder,        other.navBorder,        t)!,
      trackGauge:       Color.lerp(trackGauge,       other.trackGauge,       t)!,
      glowBlue:         Color.lerp(glowBlue,         other.glowBlue,         t)!,
      glowWarm:         Color.lerp(glowWarm,         other.glowWarm,         t)!,
      glowConnected:    Color.lerp(glowConnected,    other.glowConnected,    t)!,
      fieldBorder:      Color.lerp(fieldBorder,      other.fieldBorder,      t)!,
      teal:             Color.lerp(teal,             other.teal,             t)!,
      isLight:          t < 0.5 ? isLight : other.isLight,
    );
  }
}
