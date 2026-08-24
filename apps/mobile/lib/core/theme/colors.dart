import 'package:flutter/material.dart';

/// Semantic color palette for KiranaOS.
/// Optimized for high contrast in Indian retail and grocery counter environments.
abstract final class KiranaColors {
  // Brand Primary (Kirana Emerald)
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF134E4A);

  // Brand Secondary (Amber / Udhaar Accent)
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryDark = Color(0xFFB45309);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryContainer = Color(0xFFFEF3C7);
  static const Color onSecondaryContainer = Color(0xFF78350F);

  // Semantic Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Neutral Backgrounds & Surfaces (Light POS Theme)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
}
