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
      elevation: 0,
      minimumSize: const Size(88, 48), // Touch-friendly 48dp+
      padding: const EdgeInsets.symmetric(
        horizontal: KiranaSpacing.xl,
        vertical: KiranaSpacing.md,
      ),
      shape: const RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
      textStyle: KiranaTypography.labelLarge.copyWith(color: Colors.white),
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
      shape: const RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
      textStyle: KiranaTypography.labelLarge,
    ),
  );

  static final InputDecorationTheme inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: KiranaColors.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: KiranaSpacing.lg,
      vertical: KiranaSpacing.md,
    ),
    border: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderMd,
      borderSide: BorderSide(color: KiranaColors.outline),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderMd,
      borderSide: BorderSide(color: KiranaColors.outlineVariant),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderMd,
      borderSide: BorderSide(color: KiranaColors.primary, width: 2),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: KiranaRadius.borderMd,
      borderSide: BorderSide(color: KiranaColors.error),
    ),
    hintStyle: KiranaTypography.bodyMedium.copyWith(color: KiranaColors.textMuted),
    labelStyle: KiranaTypography.bodyMedium.copyWith(color: KiranaColors.textSecondary),
  );

  static const CardThemeData cardTheme = CardThemeData(
    color: KiranaColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: KiranaRadius.borderMd,
      side: BorderSide(color: KiranaColors.outlineVariant, width: 1),
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
