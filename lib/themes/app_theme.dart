import 'package:flutter/material.dart';

// App colors - consolidated in theme file
class AppColors {
  // Main color - change this to change entire app theme!
  static const Color primary = Colors.blue;
  
  // Background colors
  static const Color background = Colors.white;
  static const Color cardBackground = Colors.white;
  
  // Text colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const Color textWhite = Colors.white;
  
  // Input field colors
  static final Color inputFill = Colors.grey[100]!;
  static const Color inputBorder = Colors.blue;
  
  // Status colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
  
  // Other colors
  static const Color shadow = Colors.black12;
  static const Color divider = Colors.grey;
}

// Main app theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Main color
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      
      // AppBar style
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Button style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text field style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: 2,
          ),
        ),
      ),
      
      // Card style
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Use Material 3
      useMaterial3: true,
    );
  }
}

