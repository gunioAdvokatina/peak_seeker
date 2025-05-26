import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF3A7D44);
  static const Color primaryOrange = Color(0xFFDD663B);
  static const Color pastelGreen = Color(0xFF9DC08B);
  static const Color pastelGreenLight = Color(0xFFACD1B1);
  static const Color orange = Color(0xFFFF9746);
  static const Color orangeLight = Color(0xFFFFAA68);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.pastelGreen,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryGreen,
    primary: AppColors.primaryGreen,
    secondary: AppColors.primaryOrange,
    background: AppColors.pastelGreen,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.all(AppColors.orange),
    checkColor: MaterialStateProperty.all(Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
);
