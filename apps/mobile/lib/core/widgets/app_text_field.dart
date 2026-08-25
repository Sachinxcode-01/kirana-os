import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Touch-friendly text field with support for numeric numpads and barcodes.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool autofocus;
  final bool readOnly;
  final int? maxLength;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLength,
    this.errorText,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: KiranaTypography.labelLarge.copyWith(
              color: KiranaColors.textSecondary,
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          obscureText: obscureText,
          autofocus: autofocus,
          readOnly: readOnly,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: KiranaTypography.bodyLarge,
          decoration: InputDecoration(
            counterText: maxLength != null ? '' : null,
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
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
          ),
        ),
      ],
    );
  }
}
