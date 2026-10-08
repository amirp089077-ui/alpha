import 'package:flutter/material.dart';

class AppTypography {
  // همه فونت‌ها از IranSans Bold استفاده می‌کنن
  static const _font = 'IranSans';

  // ─── Scale ────────────────────────────────────────────────

  static const display = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 0,
  );

  static const timer = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const title1 = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const status = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const title2 = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const title3 = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const body = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontFamily: _font,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const micro = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Latin logotype ───────────────────────────────────────

  static const logoLatin = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 1.5,
  );

  static const logoLatinSmall = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
}
