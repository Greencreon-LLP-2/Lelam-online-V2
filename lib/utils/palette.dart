// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Central place for all brand colors, semantic colors, and swatches.
/// Tweak the hex values below to match your brand.
class Palette {
  // === Brand / Primary set ===
  static const Color primaryblue = Color(0xFF2d5ba9); // Brand primary
  static const Color primarypink = Color(0xFFf03b6c);
  static const Color primarylightblue = Color(0xFF94aee5);

  // If you prefer a different accent, change this:
  static const Color secondary = Color(0xFF22C55E);
  static const Color secondaryDark = Color(0xFF16A34A);
  static const Color secondaryLight = Color(0xFF4ADE80);

  // === Neutral / Grays ===
  static const Color black = Color(0xFF0A0A0A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray900 = Color(0xFF111827);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray050 = Color(0xFFFAFAFA);

  // === Semantic ===
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // === Surfaces & Text ===
  static const Color surface = white;
  static const Color surfaceAlt = gray050;
  static const Color card = white;
  static const Color divider = gray200;

  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color textDisabled = gray400;
}

/// Optional: ThemeExtension to expose custom colors in Theme.of(context)
