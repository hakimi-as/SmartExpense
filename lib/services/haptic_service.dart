import 'package:flutter/services.dart';

class HapticService {
  /// Light tap feedback - for selections, toggles
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium tap feedback - for button presses
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap feedback - for important actions
  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback - for picker selections
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate feedback - for errors or warnings
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Success feedback
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error feedback
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}