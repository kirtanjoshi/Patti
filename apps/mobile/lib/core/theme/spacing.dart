import 'package:flutter/material.dart';

/// Patii Spacing, Sizing, and Radius Tokens
abstract class PatiiSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  // Touch Target Minimum
  static const double minTouchTarget = 48.0;

  // Border Radii
  static const Radius radius4 = Radius.circular(4.0);
  static const Radius radius8 = Radius.circular(8.0);
  static const Radius radius12 = Radius.circular(12.0);
  static const Radius radius16 = Radius.circular(16.0);
  static const Radius radiusFull = Radius.circular(999.0);

  static final BorderRadius rounded4 = BorderRadius.circular(4.0);
  static final BorderRadius rounded8 = BorderRadius.circular(8.0);
  static final BorderRadius rounded12 = BorderRadius.circular(12.0);
  static final BorderRadius rounded16 = BorderRadius.circular(16.0);
  static final BorderRadius roundedFull = BorderRadius.circular(999.0);
}
