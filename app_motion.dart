import 'package:flutter/animation.dart';

/// مدد ومنحنيات موحدة. كل الحركات بين 100 و400 مللي ثانية (عدا مدة شاشة البداية).
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 280);
  static const entrance = Duration(milliseconds: 350);
  static const splash = Duration(milliseconds: 2400);
  static const splashReduced = Duration(milliseconds: 400);
  static const standard = Curves.easeOutCubic;
}
