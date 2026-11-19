import 'package:flutter/material.dart';

/// Token jarak dan tata letak standar aplikasi MobilJuragan.
///
/// Mengacu pada baseline layar Auth (Login, Register, OTP) agar seluruh layar
/// memiliki margin horizontal, jarak antar elemen, dan radius yang seragam.
class AppSpacing {
  AppSpacing._();

  /// Margin horizontal baku untuk seluruh layar konten (24 px).
  static const double screenH = 24.0;

  /// Margin vertikal baku untuk area gulir layar (16 px).
  static const double screenV = 16.0;

  /// Padding standar di dalam kartu konten (16 px).
  static const double cardPadding = 16.0;

  static const double gapXs = 4.0;
  static const double gapSm = 8.0;
  static const double gapMd = 12.0;
  static const double gapLg = 16.0;
  static const double gapXl = 24.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenH,
    vertical: screenV,
  );
}

/// Skala radius sudut baku aplikasi MobilJuragan.
class AppRadius {
  AppRadius._();

  /// Radius kontrol interaktif: input field, tombol, dan baris unggah.
  static const double control = 12.0;

  /// Radius kartu konten utama.
  static const double card = 16.0;

  /// Radius pill dan filter chip.
  static const double pill = 20.0;

  /// Radius sudut atas modal bottom sheet.
  static const double sheet = 24.0;
}
