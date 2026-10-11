import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ویجت اختصاصی آیکون نئونی و کره مرکزی ۳ بعدی دقیقاً مشابه طرح مرجع
class NeonOrbButton extends StatefulWidget {
  const NeonOrbButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
    this.size,
  });

  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;
  final double? size;

  @override
  State<NeonOrbButton> createState() => _NeonOrbButtonState();
}

class _NeonOrbButtonState extends State<NeonOrbButton>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double orbSize = widget.size ?? 235.w;
    final double outerRingSize = orbSize + 36.w;

    return Center(
      child: GestureDetector(
        onTap: widget.isConnecting ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: outerRingSize,
          height: outerRingSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── مدار گردان خارجی با نقاط ماهواره‌ای ─────────────────
              AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _orbitController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: Size(outerRingSize, outerRingSize),
                      painter: _OrbitRingPainter(
                        isConnected: widget.isConnected,
                        pulse: _pulseController.value,
                      ),
                    ),
                  );
                },
              ),

              // ── کره اصلی ۳ بعدی با قاب متالیک و لوگوی نئونی ─────────
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowIntensity = widget.isConnected
                      ? 0.75 + 0.25 * _pulseController.value
                      : (widget.isConnecting ? 0.6 + 0.3 * _pulseController.value : 0.35);

                  return Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // هاله نورانی خارجی اطراف کره
                        BoxShadow(
                          color: widget.isConnected
                              ? const Color(0xFF0D9488).withValues(alpha: 0.35 * glowIntensity)
                              : const Color(0xFF0E8A98).withValues(alpha: 0.20 * glowIntensity),
                          blurRadius: 40.r,
                          spreadRadius: 4.r,
                          offset: const Offset(0, 10),
                        ),
                        // سایه تاریک طبیعی زیر دکمه
                        BoxShadow(
                          color: const Color(0xFF042028).withValues(alpha: 0.25),
                          blurRadius: 24.r,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // لایه ۱: تصویر اصلی ۳ بعدی کره از APK با بالاترین کیفیت
                        Image.asset(
                          'assets/images/orb_logo.png',
                          width: orbSize,
                          height: orbSize,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: Size(orbSize, orbSize),
                                  painter: _OrbSpherePainter(
                                    isConnected: widget.isConnected,
                                  ),
                                ),
                                CustomPaint(
                                  size: Size(orbSize * 0.72, orbSize * 0.72),
                                  painter: _NeonAlphaPainter(
                                    glowIntensity: glowIntensity,
                                    isConnected: widget.isConnected,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        // هاله نورانی درون کره هنگام اتصال
                        if (widget.isConnected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF22D3EE).withValues(alpha: 0.15 * glowIntensity),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.65, 1.0],
                                ),
                              ),
                            ),
                          ),

                        // لایه ۳: نشانگر وضعیت در حال اتصال
                        if (widget.isConnecting)
                          SizedBox(
                            width: orbSize * 0.88,
                            height: orbSize * 0.88,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.w,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF22D3EE),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── مدار و نقاط ماهواره‌ای چرخان ──────────────────────────────────────────────
class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.isConnected,
    required this.pulse,
  });

  final bool isConnected;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // خط مدار باریک
    final ringPaint = Paint()
      ..color = (isConnected ? const Color(0xFF14B8A6) : const Color(0xFF0E8A98))
          .withValues(alpha: 0.22 + 0.08 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, ringPaint);

    // نقطه ماهواره‌ای اول (بالا-راست)
    _drawSatelliteDot(canvas, center, radius, math.pi * 0.25, isConnected);
    // نقطه ماهواره‌ای دوم (پایین-چپ)
    _drawSatelliteDot(canvas, center, radius, math.pi * 1.20, isConnected);
  }

  void _drawSatelliteDot(
      Canvas canvas, Offset center, double radius, double angle, bool connected) {
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);
    final dotPos = Offset(dotX, dotY);

    // هاله نقطه
    final haloPaint = Paint()
      ..color = (connected ? const Color(0xFF2DD4BF) : const Color(0xFF38BDF8))
          .withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(dotPos, 6, haloPaint);

    // دایره سفید و هسته
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotPos, 3.2, dotPaint);

    final dotCorePaint = Paint()
      ..color = connected ? const Color(0xFF0D9488) : const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(dotPos, 3.2, dotCorePaint);
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) =>
      old.isConnected != isConnected || old.pulse != pulse;
}

// ─── نقاش کره ۳ بعدی با قاب طلایی/برنز و هایلایت هلالی ──────────────────────
class _OrbSpherePainter extends CustomPainter {
  _OrbSpherePainter({required this.isConnected});
  final bool isConnected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ۱. قاب متالیک طلایی/برنزی باریک دور کره
    final bezelPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFD4AF37), // طلایی
          Color(0xFF785934), // برنزی تیره
          Color(0xFFF7E2A9), // نور متالیک
          Color(0xFF8A643B), // برنزی
          Color(0xFFD4AF37), // طلایی
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawCircle(center, radius - 1.2, bezelPaint);

    // ۲. پر کردن عمق تاریک اقیانوسی/سبز-تیره داخل کره
    final innerRadius = radius - 2.4;
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 0.95,
        colors: isConnected
            ? const [
                Color(0xFF156E7B), // مرکز مایل به فیروزه‌ای
                Color(0xFF08414B), // میانه تاریک
                Color(0xFF022329), // لبه تاریک
                Color(0xFF011417), // عمق مشکی-کبالت
              ]
            : const [
                Color(0xFF135B66),
                Color(0xFF073841),
                Color(0xFF021E23),
                Color(0xFF011013),
              ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawCircle(center, innerRadius, spherePaint);

    // ۳. هایلایت هلالی شیشه‌ای در لبه بالایی (انعکاس شیشه ۳ بعدی)
    final glassPath = Path();
    glassPath.addArc(
      Rect.fromCircle(center: center, radius: innerRadius - 1),
      math.pi * 1.1,
      math.pi * 0.8,
    );
    final glassPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawPath(glassPath, glassPaint);
  }

  @override
  bool shouldRepaint(_OrbSpherePainter old) =>
      old.isConnected != isConnected;
}

// ─── لوگوی نئونی متقاطع Alpha و V ──────────────────────────────────────────────
class _NeonAlphaPainter extends CustomPainter {
  _NeonAlphaPainter({
    required this.glowIntensity,
    required this.isConnected,
  });

  final double glowIntensity;
  final bool isConnected;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // مسیر کمان آبی-فیروزه‌ای A (شکل هشتی با گوشه‌های نرم)
    final bluePath = Path()
      ..moveTo(cx - w * 0.40, h * 0.74)
      ..cubicTo(
        cx - w * 0.28, h * 0.45,
        cx - w * 0.12, h * 0.08,
        cx, h * 0.08,
      )
      ..cubicTo(
        cx + w * 0.12, h * 0.08,
        cx + w * 0.28, h * 0.45,
        cx + w * 0.40, h * 0.74,
      );

    // مسیر کمان نارنجی-آتشی V (شکل هفت متقاطع در جلو)
    final orangePath = Path()
      ..moveTo(cx - w * 0.36, h * 0.26)
      ..cubicTo(
        cx - w * 0.20, h * 0.55,
        cx - w * 0.08, h * 0.90,
        cx, h * 0.90,
      )
      ..cubicTo(
        cx + w * 0.08, h * 0.90,
        cx + w * 0.20, h * 0.55,
        cx + w * 0.36, h * 0.26,
      );

    final strokeW = w * 0.105;

    // ۱. هاله بیرونی نرم آبی (Deep Cyan Bloom)
    final blueBloom = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.30 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * glowIntensity);
    canvas.drawPath(bluePath, blueBloom);

    // ۲. هاله میانی آبی نئونی
    final blueMid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.65 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * glowIntensity);
    canvas.drawPath(bluePath, blueMid);

    // ۳. هسته آبی اصلی
    final blueCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF06B6D4);
    canvas.drawPath(bluePath, blueCore);

    // ۴. هاله بیرونی نرم نارنجی (Fiery Orange Bloom)
    final orangeBloom = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.35 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * glowIntensity);
    canvas.drawPath(orangePath, orangeBloom);

    // ۵. هاله میانی نارنجی نئونی
    final orangeMid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFB923C).withValues(alpha: 0.75 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * glowIntensity);
    canvas.drawPath(orangePath, orangeMid);

    // ۶. هسته نارنجی اصلی
    final orangeCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFF7A00);
    canvas.drawPath(orangePath, orangeCore);

    // ۷. هایلایت براق سفید روی کمان‌های نئونی (Specular Reflection Highlight)
    final specPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.32
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85);

    // برش کوتاه هایلایت روی کمان آبی در قله
    final blueApexHighlight = Path()
      ..moveTo(cx - w * 0.12, h * 0.17)
      ..cubicTo(cx - w * 0.05, h * 0.08, cx + w * 0.05, h * 0.08, cx + w * 0.12, h * 0.17);
    canvas.drawPath(blueApexHighlight, specPaint);

    // برش کوتاه هایلایت روی بازوی راست نارنجی
    final orangeRightHighlight = Path()
      ..moveTo(cx + w * 0.14, h * 0.65)
      ..lineTo(cx + w * 0.30, h * 0.34);
    canvas.drawPath(orangeRightHighlight, specPaint);

    // بازتاب درخشان مرکز تقاطع (Flare)
    final flarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx, h * 0.48), strokeW * 0.35, flarePaint);
  }

  @override
  bool shouldRepaint(_NeonAlphaPainter old) =>
      old.glowIntensity != glowIntensity || old.isConnected != isConnected;
}
