import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const primaryBlue = Color(0xFF1E88E5);
  static const primaryGreen = Color(0xFF26A69A);
  static const primaryYellow = Color(0xFFFDD835);
  
  // Map to legacy color names to avoid breaking existing code
  static const primaryColor = primaryBlue;
  static const secondaryColor = primaryGreen;
  static const textPrimary = lightTextPrimary;
  static const textSecondary = lightTextSecondary;
  
  // Background Gradient
  static const gradientStart = Color(0xFF1E88E5); // Blue
  static const gradientMiddle = Color(0xFF26A69A); // Green
  static const gradientEnd = Color(0xFFFDD835);    // Yellow
  
  // Light Theme Colors
  static const lightTextPrimary = Color(0xFF2A2A2A);
  static const lightTextSecondary = Color(0xFF6C6C6C);
  static const lightTextMuted = Color(0xFF9E9E9E);
  static const lightBackgroundLight = Color(0xFFF8F9FA);
  static const lightBackgroundWhite = Colors.white;
  static const lightCardBackground = Colors.white;
  static const lightDivider = Color(0xFFEEEEEE);
  
  // Status Colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE53935);
  static const info = Color(0xFF2196F3);
  
  // Common Dimensions
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  
  // Text Styles for Light Theme
  static TextStyle _headingLargeLight = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: lightTextPrimary,
  );
  
  static TextStyle _headingMediumLight = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: lightTextPrimary,
  );
  
  static TextStyle _headingSmallLight = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: lightTextPrimary,
  );
  
  static TextStyle _bodyLargeLight = const TextStyle(
    fontSize: 16,
    color: lightTextPrimary,
  );
  
  static TextStyle _bodyMediumLight = const TextStyle(
    fontSize: 14,
    color: lightTextPrimary,
  );
  
  static TextStyle _bodySmallLight = const TextStyle(
    fontSize: 12,
    color: lightTextSecondary,
  );
  
  // Button Text Style
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    // Base colors
    primaryColor: primaryBlue,
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryGreen,
      tertiary: primaryYellow,
      surface: lightBackgroundWhite,
      background: lightBackgroundLight,
      error: error,
    ),
    
    // Text theme
    textTheme: TextTheme(
      displayLarge: _headingLargeLight,
      displayMedium: _headingMediumLight,
      displaySmall: _headingSmallLight,
      bodyLarge: _bodyLargeLight,
      bodyMedium: _bodyMediumLight,
      bodySmall: _bodySmallLight,
      labelLarge: buttonText,
    ),
    
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 1,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey.shade50,
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      color: lightCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    
    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackgroundWhite,
      foregroundColor: lightTextPrimary,
      elevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: lightTextPrimary),
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: lightBackgroundWhite,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Divider color
    dividerColor: lightDivider,
    
    // Scaffold background color
    scaffoldBackgroundColor: lightBackgroundLight,
    
    // Misc
    splashColor: primaryBlue.withOpacity(0.1),
    highlightColor: primaryBlue.withOpacity(0.05),
  );
  
  // Common Gradient Decoration
  static final gradientDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        gradientStart,
        gradientMiddle,
        gradientEnd,
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );
  
  // Section headers
  static Widget sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: primaryBlue,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
      ),
    );
  }
} 