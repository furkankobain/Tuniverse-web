import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../animations/enhanced_animations.dart';

// Enhanced Button
class EnhancedButton extends ConsumerWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool fullWidth;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final animationState = ref.watch(animationProvider);

    Widget button = _buildButton(context, themeColors);

    if (animationState.animationsEnabled) {
      button = EnhancedAnimations.press(child: button);
    }

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildButton(BuildContext context, ThemeColors themeColors) {
    final buttonStyle = _getButtonStyle(themeColors);
    final textStyle = _getTextStyle(context);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: isLoading
          ? SizedBox(
              width: _getIconSize(),
              height: _getIconSize(),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  type == ButtonType.primary ? Colors.white : themeColors.primaryColor,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: _getIconSize()),
                  const SizedBox(width: 8),
                ],
                Text(text, style: textStyle),
              ],
            ),
    );
  }

  ButtonStyle _getButtonStyle(ThemeColors themeColors) {
    final backgroundColor = _getBackgroundColor(themeColors);
    final foregroundColor = _getForegroundColor(themeColors);

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      elevation: type == ButtonType.primary ? 2 : 0,
    );
  }

  Color _getBackgroundColor(ThemeColors themeColors) {
    switch (type) {
      case ButtonType.primary:
        return themeColors.primaryColor;
      case ButtonType.secondary:
        return themeColors.surfaceColor;
      case ButtonType.outline:
        return Colors.transparent;
      case ButtonType.ghost:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(ThemeColors themeColors) {
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return themeColors.textPrimary;
      case ButtonType.outline:
        return themeColors.primaryColor;
      case ButtonType.ghost:
        return themeColors.textPrimary;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return Theme.of(context).textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w600,
        );
      case ButtonSize.medium:
        return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
        );
      case ButtonSize.large:
        return Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.w600,
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 6;
      case ButtonSize.medium:
        return 8;
      case ButtonSize.large:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

enum ButtonType { primary, secondary, outline, ghost }
enum ButtonSize { small, medium, large }

// Enhanced Card
class EnhancedCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool enableHover;
  final bool enablePress;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.enableHover = true,
    this.enablePress = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final animationState = ref.watch(animationProvider);

    Widget card = Card(
      elevation: elevation ?? 2,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      color: backgroundColor ?? themeColors.cardColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (animationState.animationsEnabled) {
      if (enableHover) {
        card = EnhancedAnimations.hover(child: card);
      }
      if (enablePress) {
        card = EnhancedAnimations.press(child: card);
      }
    }

    return card;
  }
}

// Enhanced Text Field
class EnhancedTextField extends ConsumerWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final TextCapitalization textCapitalization;

  const EnhancedTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final animationState = ref.watch(animationProvider);

    Widget textField = TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: themeColors.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.errorColor, width: 2),
        ),
      ),
    );

    if (animationState.animationsEnabled) {
      textField = EnhancedAnimations.fadeIn(child: textField);
    }

    return textField;
  }
}

// Enhanced Loading Indicator
class EnhancedLoadingIndicator extends ConsumerWidget {
  final String? message;
  final double size;
  final Color? color;

  const EnhancedLoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final animationState = ref.watch(animationProvider);

    Widget indicator = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? themeColors.primaryColor,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (animationState.animationsEnabled) {
      indicator = EnhancedAnimations.pulse(
        child: SizedBox(
          width: size,
          height: size,
          child: indicator,
        ),
      );
    }

    return Center(child: indicator);
  }
}

// Enhanced Snackbar
class EnhancedSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    final colors = _getSnackbarColors(type, theme);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getSnackbarIcon(type),
              color: colors.foregroundColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: colors.foregroundColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static _SnackbarColors _getSnackbarColors(SnackbarType type, ThemeData theme) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarColors(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        );
      case SnackbarType.error:
        return _SnackbarColors(
          backgroundColor: const Color(0xFFFF5252),
          foregroundColor: Colors.white,
        );
      case SnackbarType.warning:
        return _SnackbarColors(
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: Colors.white,
        );
      case SnackbarType.info:
        return _SnackbarColors(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
        );
    }
  }

  static IconData _getSnackbarIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.warning:
        return Icons.warning;
      case SnackbarType.info:
        return Icons.info;
    }
  }
}

enum SnackbarType { success, error, warning, info }

class _SnackbarColors {
  final Color backgroundColor;
  final Color foregroundColor;

  _SnackbarColors({
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

// Enhanced Dialog
class EnhancedDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Evet',
    String cancelText = 'Hayır',
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      child: Consumer(
        builder: (context, ref, child) {
          // final themeColors = ref.watch(themeColorsProvider); // Unused variable
          
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: EnhancedButton(
                        text: cancelText,
                        type: ButtonType.outline,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EnhancedButton(
                        text: confirmText,
                        type: isDestructive ? ButtonType.primary : ButtonType.primary,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
