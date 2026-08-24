import 'package:flutter/material.dart';
import 'colors.dart';
import 'component_theme.dart';
import 'typography.dart';

/// Root App ThemeData configuration for KiranaOS.
abstract final class KiranaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: KiranaColors.primary,
        onPrimary: KiranaColors.textOnPrimary,
        primaryContainer: KiranaColors.primaryContainer,
        onPrimaryContainer: KiranaColors.onPrimaryContainer,
        secondary: KiranaColors.secondary,
        onSecondary: KiranaColors.textOnSecondary,
        secondaryContainer: KiranaColors.secondaryContainer,
        onSecondaryContainer: KiranaColors.onSecondaryContainer,
        error: KiranaColors.error,
        onError: Colors.white,
        errorContainer: KiranaColors.errorContainer,
        onErrorContainer: KiranaColors.error,
        surface: KiranaColors.surface,
        onSurface: KiranaColors.textPrimary,
        surfaceContainerHighest: KiranaColors.surfaceVariant,
        outline: KiranaColors.outline,
        outlineVariant: KiranaColors.outlineVariant,
      ),
      scaffoldBackgroundColor: KiranaColors.background,
      appBarTheme: KiranaComponentThemes.appBarTheme,
      elevatedButtonTheme: KiranaComponentThemes.elevatedButtonTheme,
      outlinedButtonTheme: KiranaComponentThemes.outlinedButtonTheme,
      inputDecorationTheme: KiranaComponentThemes.inputDecorationTheme,
      cardTheme: KiranaComponentThemes.cardTheme,
      textTheme: const TextTheme(
        displayLarge: KiranaTypography.displayTotal,
        headlineLarge: KiranaTypography.headlineLarge,
        headlineMedium: KiranaTypography.headlineMedium,
        titleLarge: KiranaTypography.titleLarge,
        titleMedium: KiranaTypography.titleMedium,
        bodyLarge: KiranaTypography.bodyLarge,
        bodyMedium: KiranaTypography.bodyMedium,
        bodySmall: KiranaTypography.bodySmall,
        labelLarge: KiranaTypography.labelLarge,
        labelSmall: KiranaTypography.labelSmall,
      ),
    );
  }
}
