import 'package:shamsi_date/shamsi_date.dart';
import 'persian_digits.dart';

/// Convert a Gregorian DateTime to a Jalali date string in Persian
/// e.g. "۲۹ مهر ۱۴۰۵"
String formatJalaliDate(DateTime dt) {
  final j = Jalali.fromDateTime(dt);
  final monthName = _jalaliMonths[j.month - 1];
  return '${j.day.toFa()} $monthName ${j.year.toFa()}';
}

const _jalaliMonths = [
  'فروردین', 'اردیبهشت', 'خرداد',
  'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر',
  'دی', 'بهمن', 'اسفند',
];

/// Format gigabytes with one decimal
String formatGbFa(double gb) {
  if (gb >= 1) return '${gb.toFaDecimal(digits: 1)} گیگ';
  final mb = (gb * 1024).round();
  return '${mb.toFa()} مگ';
}

/// Format megabytes
String formatMbFa(double mb) {
  if (mb >= 1024) return formatGbFa(mb / 1024);
  return '${mb.round().toFa()} مگ';
}
