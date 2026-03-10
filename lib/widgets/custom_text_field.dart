import 'package:flutter/material.dart';

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
    Key? key,
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
    this.fillColor = const Color(0xFF282E39),
    this.textColor = Colors.white,
    this.hintColor = const Color(0xFF9DA6B9),
    this.borderRadius = 12.0,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.5,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 16,
            height: 1.5,
          ),
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 16,
            height: 1.5,
          ),
          filled: true,
          fillColor: fillColor,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: hintColor,
                )
              : null,
          prefixIconConstraints: prefixIconConstraints,
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIconConstraints,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius!), // Non-null assertion is safe here
            borderSide: BorderSide.none,
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
