// Persian digit conversion utilities

extension PersianStringExt on String {
  /// Convert all ASCII digits and decimal point to Persian equivalents
  String toFa() {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    var s = this;
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(en[i], fa[i]);
    }
    return s.replaceAll('.', '٫');
  }

  /// Convert Latin digits only (keep punctuation as-is)
  String digitsToFa() {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    var s = this;
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(en[i], fa[i]);
    }
    return s;
  }
}

extension PersianNumExt on num {
  /// Convert number to Persian string with optional decimal digits
  String toFa({int? decimals}) {
    final s = decimals != null
        ? toStringAsFixed(decimals)
        : toString();
    return s.toFa();
  }

  /// Format with Persian decimal separator (٫) and given decimal places
  String toFaDecimal({int digits = 1}) {
    return toStringAsFixed(digits).toFa();
  }
}

extension PersianIntExt on int {
  String toFa() => toString().toFa();

  /// Format as zero-padded two-digit Persian string
  String toFaPadded() => toString().padLeft(2, '0').toFa();
}

/// Format seconds into HH:MM:SS with Persian digits
String formatDurationFa(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  final str =
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  return str.digitsToFa();
}

/// Format ping value: number in Persian + 'ms' in Latin
String formatPingFa(int ms) => '${ms.toFa()}ms';

/// Format data size: e.g. 34.1 گیگ or 150 مگ
String formatDataFa(double gb) {
  if (gb < 1) {
    final mb = (gb * 1024).round();
    return '${mb.toFa()} مگ';
  }
  return '${gb.toFaDecimal(digits: 1)} گیگ';
}

/// Format days remaining
String formatDaysFa(int days) => '${days.toFa()} روز';
