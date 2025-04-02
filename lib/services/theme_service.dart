import 'package:flutter/material.dart';

class ThemeService {
  // Singleton instance
  static final ThemeService _instance = ThemeService._internal();
  
  factory ThemeService() {
    return _instance;
  }
  
  ThemeService._internal();
  
  // Theme mode notifier - always light mode
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  
  // Initialize theme - no need for shared preferences anymore
  Future<void> init() async {
    // Always use light mode
    themeMode.value = ThemeMode.light;
  }
  
  // No dark mode support
  bool get isDarkMode => false;
} 