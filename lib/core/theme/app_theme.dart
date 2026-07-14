import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF006D6F);

  static const background =
      Color.fromARGB(255, 227, 241, 244);
  static const white = Colors.white;

  static const grey = Colors.grey;

  static const black = Colors.black;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ),

    scaffoldBackgroundColor:
        AppColors.background,
  );
}