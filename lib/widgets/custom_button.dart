import 'package:flutter/material.dart';
import '../utils/theme.dart';

enum ButtonType {
  primary,
  secondary,
  outline,
  text,
  gradient,
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
  final Gradient? gradient;

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
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Define theme colors
    final primaryColor = AppTheme.primaryColor;
    final secondaryColor = AppTheme.primaryGreen;
    
    // Get the gradient from AppTheme or use the provided one
    final defaultGradient = AppTheme.gradientDecoration.gradient;
    
    // For gradient button
    if (type == ButtonType.gradient || gradient != null) {
      // Make sure we have a non-null gradient to use
      if (gradient != null || defaultGradient != null) {
        return _buildGradientButton(gradient ?? defaultGradient!);
      }
    }
    
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
          side: BorderSide(color: primaryColor),
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
      case ButtonType.gradient:
        // This case is handled separately
        buttonStyle = ElevatedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
        break;
    }

    // Create button content with icon if provided
    Widget buttonContent = _buildButtonContent();

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
      case ButtonType.gradient:
        // This case is handled separately
        button = ElevatedButton(
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        );
        break;
    }

    // Apply width constraints if needed
    return _applyWidthConstraints(button);
  }

  Widget _buildGradientButton(Gradient gradient) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: fullWidth ? double.infinity : width,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: padding,
            child: _buildButtonContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      return Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
  }

  Widget _applyWidthConstraints(Widget button) {
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
    final primaryColor = AppTheme.primaryColor;
    final secondaryColor = AppTheme.primaryGreen;
    
    Color iconColor;
    switch (type) {
      case ButtonType.primary:
        iconColor = primaryColor;
        break;
      case ButtonType.secondary:
        iconColor = secondaryColor;
        break;
      case ButtonType.outline:
      case ButtonType.text:
      case ButtonType.gradient:
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