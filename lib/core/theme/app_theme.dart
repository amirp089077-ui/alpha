import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'theme_extension.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'IranSans',
      scaffoldBackgroundColor: AppColorsDark.bgBase,
      colorScheme: const ColorScheme.dark(
        primary:   AppColorsDark.blue,
        secondary: AppColorsDark.orange,
        surface:   AppColorsDark.card,
        error:     AppColorsDark.red,
      ),
      extensions: const [AppColors.dark],
      textTheme: _buildTextTheme(AppColorsDark.textPrimary, AppColorsDark.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:                   Colors.transparent,
          statusBarIconBrightness:          Brightness.light,
          systemNavigationBarColor:         AppColorsDark.bgBase,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor:  Colors.transparent,
        ),
      ),
      splashColor: Colors.white.withValues(alpha: 0.04),
      highlightColor: Colors.white.withValues(alpha: 0.02),
      dividerColor: AppColorsDark.divider,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColorsDark.bgBase
                : AppColorsDark.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColorsDark.mint
                : AppColorsDark.trackGauge),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'IranSans',
      scaffoldBackgroundColor: AppColorsLight.bgBase,
      colorScheme: const ColorScheme.light(
        primary:   AppColorsLight.teal,
        secondary: AppColorsLight.orange,
        surface:   AppColorsLight.card,
        error:     AppColorsShared.red,
      ),
      extensions: const [AppColors.light],
      textTheme: _buildTextTheme(AppColorsLight.textPrimary, AppColorsLight.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:                   Colors.transparent,
          statusBarIconBrightness:          Brightness.dark,
          systemNavigationBarColor:         AppColorsLight.bgBase,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor:  Colors.transparent,
        ),
      ),
      splashColor: AppColorsLight.teal.withValues(alpha: 0.06),
      highlightColor: AppColorsLight.teal.withValues(alpha: 0.03),
      dividerColor: AppColorsLight.cardBorder,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppColorsLight.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColorsLight.teal
                : AppColorsLight.cardBorder),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge:   AppTypography.display.copyWith(color: primary),
      headlineLarge:  AppTypography.title1.copyWith(color: primary),
      headlineMedium: AppTypography.title2.copyWith(color: primary),
      headlineSmall:  AppTypography.title3.copyWith(color: primary),
      bodyLarge:      AppTypography.body.copyWith(color: primary),
      bodyMedium:     AppTypography.caption.copyWith(color: secondary),
      bodySmall:      AppTypography.micro.copyWith(color: secondary),
      labelLarge:     AppTypography.title3.copyWith(color: primary),
    );
  }
}
