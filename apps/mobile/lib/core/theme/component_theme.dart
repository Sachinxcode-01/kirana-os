import 'package:flutter/material.dart';
import 'colors.dart';
import 'radius.dart';
import 'spacing.dart';
import 'typography.dart';

/// Centralized Material 3 Component Theme definitions for KiranaOS.
abstract final class KiranaComponentThemes {
  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: KiranaColors.primary,
      foregroundColor: KiranaColors.textOnPrimary,
      elevation: 0.5,
      minimumSize: const Size(88, 48), // Touch-friendly 48dp+
      padding: const EdgeInsets.symmetric(
        horizontal: KiranaSpacing.xl,
        vertical: KiranaSpacing.md,
      ),
      shape: const RoundedRectangleBorder(borderRadius: KiranaRadius.borderLg),
      textStyle: KiranaTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  static final OutlinedButtonThemeData outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: KiranaColors.primary,
      minimumSize: const Size(88, 48),
      padding: const EdgeInsets.symmetric(
        horizontal: KiranaSpacing.xl,
        vertical: KiranaSpacing.md,
      ),
      side: const BorderSide(color: KiranaColors.outline, width: 1.5),
      shape: const RoundedRectangleBorder(borderRadius: KiranaRadius.borderLg),
      textStyle: KiranaTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: KiranaColors.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: KiranaSpacing.lg,
      vertical: KiranaSpacing.md,
    ),
    border: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderLg,
      borderSide: BorderSide(color: KiranaColors.outline),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderLg,
      borderSide: BorderSide(color: KiranaColors.outlineVariant),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderLg,
      borderSide: BorderSide(color: KiranaColors.primary, width: 2),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderLg,
      borderSide: BorderSide(color: KiranaColors.error),
    ),
    hintStyle:
        KiranaTypography.bodyMedium.copyWith(color: KiranaColors.textMuted),
    labelStyle:
        KiranaTypography.bodyMedium.copyWith(color: KiranaColors.textSecondary),
  );

  static final CardThemeData cardTheme = CardThemeData(
    color: KiranaColors.surface,
    elevation: 0.5,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: KiranaRadius.borderLg,
      side: BorderSide(color: KiranaColors.outlineVariant.withValues(alpha: 0.8), width: 1),
    ),
  );

  static const AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: KiranaColors.surface,
    foregroundColor: KiranaColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    titleTextStyle: KiranaTypography.titleLarge,
  );
}
