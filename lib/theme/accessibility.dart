import 'package:flutter/widgets.dart';

/// Helper to check the system Reduce Motion setting.
class Accessibility {
  Accessibility._();

  /// Returns true when the user has enabled Reduce Motion in system settings.
  static bool reduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
