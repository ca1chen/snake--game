import 'package:flutter/material.dart';

/// 设计 Token — 颜色定义
class AppColors {
  // 品牌色
  static const primary = Color(0xFF4A90D9);
  static const primaryDark = Color(0xFF2C5F8A);

  // 背景
  static const backgroundLight = Color(0xFFF5F6FA);
  static const backgroundDark = Color(0xFF1A1A2E);

  // 卡片
  static const cardLight = Colors.white;
  static const cardDark = Color(0xFF16213E);

  // 文字
  static const textPrimaryLight = Color(0xFF2D3436);
  static const textPrimaryDark = Color(0xFFE4E6EB);
  static const textSecondaryLight = Color(0xFF636E72);
  static const textSecondaryDark = Color(0xFFB0B3B8);

  // 分割线
  static const dividerLight = Color(0xFFE0E0E0);
  static const dividerDark = Color(0xFF2A2A4A);

  // 优先级色
  static const priorityHigh = Color(0xFFEF5350);
  static const priorityMedium = Color(0xFFFFA726);
  static const priorityLow = Color(0xFF9E9E9E);

  // 成功/完成
  static const success = Color(0xFF2ECC71);

  // 导航栏
  static const navBarLight = Colors.white;
  static const navBarDark = Color(0xFF0F3460);
}

/// 浅色主题
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: AppColors.primary,
  scaffoldBackgroundColor: AppColors.backgroundLight,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0.5,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardLight,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.navBarLight,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondaryLight,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.dividerLight, thickness: 0.5),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.backgroundLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);

/// 深色主题
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: AppColors.primary,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0.5,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardDark,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.navBarDark,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondaryDark,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.dividerDark, thickness: 0.5),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardDark,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);
