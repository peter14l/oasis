import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/app_initializer.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final int? maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool readOnly;
  final bool showCursor;
  final void Function()? onTap;
  final void Function(String)? onChanged;
  final String? initialValue;
  final String? label;
  final bool enabled;
  final Color? fillColor;
  final Color? textColor;
  final Color? hintColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor = true,
    this.onTap,
    this.onChanged,
    this.initialValue,
    this.label,
    this.enabled = true,
    this.fillColor,
    this.textColor,
    this.hintColor,
    this.borderRadius,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    
    final effectiveFillColor = fillColor ?? (isM3E ? colorScheme.primary.withValues(alpha: 0.05) : theme.inputDecorationTheme.fillColor);
    final effectiveTextColor = textColor ?? colorScheme.onSurface;
    final effectiveHintColor = hintColor ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    final effectiveRadius = borderRadius ?? (isM3E ? 24.0 : 16.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        autofocus: autofocus,
        readOnly: readOnly,
        showCursor: showCursor,
        onTap: onTap,
        onChanged: onChanged,
        initialValue: initialValue,
        enabled: enabled,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: effectiveTextColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: effectiveHintColor,
          ),
          labelStyle: theme.textTheme.bodyLarge?.copyWith(
            color: effectiveHintColor,
          ),
          filled: true,
          fillColor: effectiveFillColor,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: effectiveHintColor,
                )
              : null,
          prefixIconConstraints: prefixIconConstraints,
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIconConstraints,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveRadius),
            borderSide: isM3E 
              ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.1))
              : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveRadius),
            borderSide: isM3E 
              ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.1))
              : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(effectiveRadius),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
          counterText: '',
        ),
      ),
    );
  }
}

// Extension for easy creation of common text fields
extension CustomTextFieldExtension on CustomTextField {
  static Widget email({
    required TextEditingController controller,
    required FocusNode focusNode,
    required void Function(String) onFieldSubmitted,
    String? Function(String?)? validator,
    String hint = 'Email',
    TextInputAction? textInputAction,
    FocusNode? nextFocus,
  }) {
    return CustomTextField(
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction ?? TextInputAction.next,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
      onFieldSubmitted: (value) {
        onFieldSubmitted(value);
        if (nextFocus != null) {
          FocusScope.of(focusNode.context!).requestFocus(nextFocus);
        }
      },
    );
  }

  static Widget password({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    String hint = 'Password',
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return CustomTextField(
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      prefixIcon: Icons.lock_outline,
      obscureText: obscureText,
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
      onFieldSubmitted: onFieldSubmitted,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF9DA6B9),
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }

  static Widget name({
    required TextEditingController controller,
    required FocusNode focusNode,
    String? Function(String?)? validator,
    String hint = 'Name',
    TextInputAction? textInputAction,
    FocusNode? nextFocus,
  }) {
    return CustomTextField(
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      prefixIcon: Icons.person_outline,
      textInputAction: textInputAction ?? TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
      onFieldSubmitted: nextFocus != null
          ? (_) => FocusScope.of(focusNode.context!).requestFocus(nextFocus)
          : null,
    );
  }
}
