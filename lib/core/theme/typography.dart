import 'package:flutter/material.dart';

class AppTypography {
  static const _fontFamily = 'Vazirmatn';
  static const _fontFamilyLatin = 'Poppins';

  // ─── Scale ───────────────────────────────────────────────────────────────
  static const display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0,
  );

  static const timer = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const title1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const status = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const title2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const title3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const micro = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Latin logotype ───────────────────────────────────────────────────────
  static const logoLatin = TextStyle(
    fontFamily: _fontFamilyLatin,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: 1.5,
  );

  static const logoLatinSmall = TextStyle(
    fontFamily: _fontFamilyLatin,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}
