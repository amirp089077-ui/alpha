import 'package:flutter/material.dart';

class AppTypography {
  static const _fontFa     = 'IranSans';   // برای عناوین bold
  static const _fontBody   = 'Vazirmatn';  // برای متن عادی
  static const _fontLatin  = 'Poppins';    // برای متن لاتین

  // ─── Scale (کوچک‌تر شده) ─────────────────────────────────

  static const display = TextStyle(
    fontFamily: _fontFa,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 0,
  );

  static const timer = TextStyle(
    fontFamily: _fontFa,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const title1 = TextStyle(
    fontFamily: _fontFa,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const status = TextStyle(
    fontFamily: _fontFa,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const title2 = TextStyle(
    fontFamily: _fontFa,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const title3 = TextStyle(
    fontFamily: _fontFa,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const body = TextStyle(
    fontFamily: _fontBody,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontFamily: _fontBody,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const micro = TextStyle(
    fontFamily: _fontBody,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Latin logotype ───────────────────────────────────────

  static const logoLatin = TextStyle(
    fontFamily: _fontLatin,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: 1.5,
  );

  static const logoLatinSmall = TextStyle(
    fontFamily: _fontLatin,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}
