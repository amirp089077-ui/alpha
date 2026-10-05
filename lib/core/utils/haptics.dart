import 'package:flutter/services.dart';

class AppHaptics {
  /// Light tap – button presses
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Medium – connect/disconnect toggle
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Heavy – important actions
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Selection – list item selection
  static Future<void> selection() => HapticFeedback.selectionClick();
}
