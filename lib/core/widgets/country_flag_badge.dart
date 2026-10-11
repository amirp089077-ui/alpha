import 'package:flutter/material.dart';

/// ویجت نمایش پرچم کشورها به صورت دایره‌ای با کیفیت بسیار بالا
class CountryFlagBadge extends StatelessWidget {
  const CountryFlagBadge({
    super.key,
    required this.countryCodeOrName,
    this.flagEmoji = '',
    this.size = 36.0,
  });

  final String countryCodeOrName;
  final String flagEmoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final lower = countryCodeOrName.toLowerCase();

    Widget flagWidget;
    if (lower.contains('انگلیس') || lower.contains('uk') || lower.contains('gb') || lower.contains('united kingdom')) {
      flagWidget = const _UkFlagPainterWidget();
    } else if (lower.contains('آلمان') || lower.contains('de') || lower.contains('ger') || lower.contains('germany')) {
      flagWidget = const _GermanyFlagPainterWidget();
    } else if (lower.contains('فرانسه') || lower.contains('fr') || lower.contains('france')) {
      flagWidget = const _FranceFlagPainterWidget();
    } else if (lower.contains('سوئد') || lower.contains('se') || lower.contains('sweden')) {
      flagWidget = const _SwedenFlagPainterWidget();
    } else if (lower.contains('هلند') || lower.contains('nl') || lower.contains('netherlands')) {
      flagWidget = const _NetherlandsFlagPainterWidget();
    } else if (lower.contains('آمریکا') || lower.contains('us') || lower.contains('usa')) {
      flagWidget = const _UsaFlagPainterWidget();
    } else {
      flagWidget = Center(
        child: Text(
          flagEmoji.isNotEmpty ? flagEmoji : '🌐',
          style: TextStyle(fontSize: size * 0.55),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: flagWidget,
        ),
      ),
    );
  }
}

// ─── پرچم انگلستان (Union Jack) ──────────────────────────────────────────────
class _UkFlagPainterWidget extends StatelessWidget {
  const _UkFlagPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _UkFlagPainter(),
    );
  }
}

class _UkFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ۱. پس‌زمینه آبی تیره
    final bluePaint = Paint()..color = const Color(0xFF012169);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bluePaint);

    // ۲. خطوط مورب سفید
    final whiteDiagonalPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.20
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), whiteDiagonalPaint);
    canvas.drawLine(Offset(0, h), Offset(w, 0), whiteDiagonalPaint);

    // ۳. خطوط مورب قرمز
    final redDiagonalPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = w * 0.08
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), redDiagonalPaint);
    canvas.drawLine(Offset(0, h), Offset(w, 0), redDiagonalPaint);

    // ۴. صلیب سفید وسط
    final whiteCrossPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(w * 0.38, 0, w * 0.24, h), whiteCrossPaint);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.38, w, h * 0.24), whiteCrossPaint);

    // ۵. صلیب قرمز سنت جورج وسط
    final redCrossPaint = Paint()..color = const Color(0xFFC8102E);
    canvas.drawRect(Rect.fromLTWH(w * 0.42, 0, w * 0.16, h), redCrossPaint);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.16), redCrossPaint);
  }

  @override
  bool shouldRepaint(_UkFlagPainter old) => false;
}

// ─── پرچم آلمان ──────────────────────────────────────────────────────────────
class _GermanyFlagPainterWidget extends StatelessWidget {
  const _GermanyFlagPainterWidget();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Container(color: const Color(0xFF000000))),
        Expanded(child: Container(color: const Color(0xFFDD0000))),
        Expanded(child: Container(color: const Color(0xFFFFCE00))),
      ],
    );
  }
}

// ─── پرچم فرانسه ─────────────────────────────────────────────────────────────
class _FranceFlagPainterWidget extends StatelessWidget {
  const _FranceFlagPainterWidget();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(color: const Color(0xFF0055A4))),
        Expanded(child: Container(color: const Color(0xFFFFFFFF))),
        Expanded(child: Container(color: const Color(0xFFEF4135))),
      ],
    );
  }
}

// ─── پرچم سوئد ───────────────────────────────────────────────────────────────
class _SwedenFlagPainterWidget extends StatelessWidget {
  const _SwedenFlagPainterWidget();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF006AA7),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 14,
            bottom: 14,
            child: Container(color: const Color(0xFFFECC00)),
          ),
          Positioned(
            left: 12,
            width: 8,
            top: 0,
            bottom: 0,
            child: Container(color: const Color(0xFFFECC00)),
          ),
        ],
      ),
    );
  }
}

// ─── پرچم هلند ───────────────────────────────────────────────────────────────
class _NetherlandsFlagPainterWidget extends StatelessWidget {
  const _NetherlandsFlagPainterWidget();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Container(color: const Color(0xFFC8102E))),
        Expanded(child: Container(color: const Color(0xFFFFFFFF))),
        Expanded(child: Container(color: const Color(0xFF003DA5))),
      ],
    );
  }
}

// ─── پرچم آمریکا ─────────────────────────────────────────────────────────────
class _UsaFlagPainterWidget extends StatelessWidget {
  const _UsaFlagPainterWidget();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: List.generate(
            7,
            (i) => Expanded(
              child: Container(
                color: i.isEven ? const Color(0xFFB22234) : Colors.white,
              ),
            ),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          color: const Color(0xFF3C3B6E),
          child: const Center(
            child: Text('★', style: TextStyle(color: Colors.white, fontSize: 8)),
          ),
        ),
      ],
    );
  }
}
