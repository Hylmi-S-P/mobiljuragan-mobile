import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Konfigurasi ThemeData global untuk aplikasi MobilJuragan
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryNavy,
        secondary: AppColors.primaryTeal,
        surface: AppColors.cardWhite,
        error: Color(0xFFEF4444),
      ),
      fontFamily: 'Inter',
      // SnackBar bawaan memakai lebar tetap dan satu baris, sehingga pesan
      // panjang meluber ke kanan saat ukuran teks sistem diperbesar. Dengan
      // teks yang boleh membungkus dan margin aman, seluruh SnackBar di
      // aplikasi ikut aman tanpa perlu diubah satu per satu.
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textWhite,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: AppTypography.sizeTitle,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: AppTypography.bodyLargeMedium,
        ),
      ),
    );
  }
}
