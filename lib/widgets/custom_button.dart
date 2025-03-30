import 'package:flutter/material.dart';

enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.width,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    // Define theme colors
    const primaryColor = Color(0xFF6A11CB);
    const secondaryColor = Color(0xFFE85CD3);
    
    // Determine button style based on type
    ButtonStyle buttonStyle;
    
    switch (type) {
      case ButtonType.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
        break;
      case ButtonType.secondary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
        break;
      case ButtonType.outline:
        buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
        break;
      case ButtonType.text:
        buttonStyle = TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
        break;
    }

    // Create button content with icon if provided
    Widget buttonContent;
    if (isLoading) {
      buttonContent = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      buttonContent = Text(label);
    }

    // Create the appropriate button based on type
    Widget button;
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        button = ElevatedButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        );
        break;
      case ButtonType.outline:
        button = OutlinedButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        );
        break;
    }

    // Apply width constraints if needed
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    } else if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    } else {
      return button;
    }
  }
}

// Icon Button Variant
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final ButtonType type;
  final double size;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A11CB);
    
    Color iconColor;
    switch (type) {
      case ButtonType.primary:
        iconColor = primaryColor;
        break;
      case ButtonType.secondary:
        iconColor = const Color(0xFFE85CD3);
        break;
      case ButtonType.outline:
      case ButtonType.text:
        iconColor = primaryColor;
        break;
    }
    
    return IconButton(
      icon: Icon(icon, color: iconColor, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
} 