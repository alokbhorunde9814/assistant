import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isHomeScreen;
  final List<Widget>? actions;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  
  const CustomAppBar({
    Key? key,
    required this.title,
    this.isHomeScreen = false,
    this.actions,
    this.elevation = 0.5,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Use a custom title layout only when not on home screen
      title: isHomeScreen 
        ? Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ) 
        : Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
      centerTitle: isHomeScreen, // Center title only on home screen
      elevation: elevation,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
      iconTheme: IconThemeData(color: foregroundColor ?? Colors.black),
      
      // Custom back button - show on every screen except home screen
      automaticallyImplyLeading: false, // Disable default back button
      leading: isHomeScreen 
        ? null 
        : IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
          ),
      titleSpacing: 0, // Remove space between back button and title
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 