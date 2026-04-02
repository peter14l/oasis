import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/app_initializer.dart';

class AppButton extends StatelessWidget {
  // ... (previous fields remain)
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final double? width;
  final double? height;
  final bool disabled;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 28.0,
    this.padding,
    this.icon,
    this.width,
    this.height = 56.0,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    final buttonStyle = _getButtonStyle(theme, isM3E);
    final buttonChild = _buildButtonChild(theme);

    final button = isOutlined
        ? OutlinedButton(
            onPressed: disabled || isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: disabled || isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          );

    if (isFullWidth) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: button,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: button,
    );
  }

  Widget _buildButtonChild(ThemeData theme) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: textColor ?? (isOutlined ? theme.colorScheme.primary : Colors.white),
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          textWidget,
        ],
      );
    }

    return textWidget;
  }

  ButtonStyle _getButtonStyle(ThemeData theme, bool isM3E) {
    final colorScheme = theme.colorScheme;
    final backgroundColor = this.backgroundColor ?? colorScheme.primary;
    final foregroundColor = textColor ?? (isOutlined ? colorScheme.primary : Colors.white);
    final shape = isM3E ? const StadiumBorder() : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            );

    final baseStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: disabled ? colorScheme.onSurface.withValues(alpha: 0.12) : colorScheme.primary,
              width: isM3E ? 2.0 : 1.5,
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: shape,
          )
        : ElevatedButton.styleFrom(
            foregroundColor: foregroundColor,
            backgroundColor: disabled ? colorScheme.onSurface.withValues(alpha: 0.12) : backgroundColor,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: shape,
            elevation: isM3E ? 0 : 0, // M3E prefers flat but vibrant
          );

    return baseStyle.copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color>(
        (states) {
          if (states.contains(WidgetState.pressed)) {
            return foregroundColor.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return foregroundColor.withValues(alpha: 0.05);
          }
          return Colors.transparent;
        },
      ),
    );
  }

  // Primary Button
  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 28.0,
    EdgeInsetsGeometry? padding,
    Widget? icon,
    double? width,
    double? height = 56.0,
    bool disabled = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: false,
      isFullWidth: isFullWidth,
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderRadius: borderRadius,
      padding: padding,
      icon: icon,
      width: width,
      height: height,
      disabled: disabled,
    );
  }

  // Secondary Button
  factory AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 28.0,
    EdgeInsetsGeometry? padding,
    Widget? icon,
    double? width,
    double? height = 56.0,
    bool disabled = false,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: true,
      isFullWidth: isFullWidth,
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderRadius: borderRadius,
      padding: padding,
      icon: icon,
      width: width,
      height: height,
      disabled: disabled,
    );
  }
}
