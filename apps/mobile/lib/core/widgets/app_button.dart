import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum AppButtonVariant { primary, secondary, outlined, destructive }

/// Touch-friendly production button standard (minimum 48dp height).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppButtonVariant.primary => (
          KiranaColors.primary,
          Colors.white,
          Colors.transparent
        ),
      AppButtonVariant.secondary => (
          KiranaColors.secondary,
          Colors.white,
          Colors.transparent
        ),
      AppButtonVariant.outlined => (
          Colors.transparent,
          KiranaColors.primary,
          KiranaColors.outline
        ),
      AppButtonVariant.destructive => (
          KiranaColors.error,
          Colors.white,
          Colors.transparent
        ),
    };

    return SizedBox(
      width: width,
      height: 52, // Generous 52dp height for quick touch
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: KiranaRadius.borderMd,
            side: BorderSide(
              color: borderColor,
              width: variant == AppButtonVariant.outlined ? 1.5 : 0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.xl),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fgColor),
                    const SizedBox(width: KiranaSpacing.sm),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: KiranaTypography.labelLarge
                            .copyWith(color: fgColor),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
