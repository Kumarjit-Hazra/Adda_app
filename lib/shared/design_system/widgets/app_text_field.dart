import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';

/// Styled input field with clean focus highlight and helper/error handling.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AddaColors.textSecondaryDark
                  : AddaColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          maxLines: maxLines,
          autofocus: autofocus,
          style: TextStyle(
            color: isDark
                ? AddaColors.textPrimaryDark
                : AddaColors.textPrimaryLight,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark
                ? AddaColors.surfaceVariantDark
                : AddaColors.surfaceVariantLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: AddaRadius.radiusMd,
              borderSide: BorderSide(
                color: isDark ? AddaColors.borderDark : AddaColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AddaRadius.radiusMd,
              borderSide: BorderSide(
                color: isDark ? AddaColors.borderDark : AddaColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AddaRadius.radiusMd,
              borderSide: const BorderSide(color: AddaColors.coral, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
