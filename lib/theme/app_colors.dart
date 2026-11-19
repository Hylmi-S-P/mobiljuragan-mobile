import 'package:flutter/material.dart';

/// Design tokens warna untuk aplikasi MobilJuragan
class AppColors {
  // Brand Primary Navy
  static const Color primaryNavy = Color(0xFF1E3A5F);
  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyLight = Color(0xFF2D4B73);

  // Accent (alias semantik; nilai lama primaryTeal dipertahankan untuk kompatibilitas)
  static const Color accent = Color(0xFF1E3A5F);
  static const Color accentSoft = Color(0xFFEFF6FF);
  static const Color accentMuted = Color(0xFFDBEAFE);

  // Accent Teal (dialihkan ke Navy: tombol dan teks utama tetap biru tua seperti header)
  static const Color primaryTeal = Color(0xFF1E3A5F);
  static const Color tealDark = Color(0xFF0F172A);
  static const Color tealLight = Color(0xFFEFF6FF);
  static const Color tealMuted = Color(0xFFDBEAFE);

  // Backgrounds & Surfaces
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9); // Slate 100

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600 (WCAG AA >= 4.5:1)
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textWhite = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFE2E8F0); // Slate 200
  static const Color borderMedium = Color(0xFFCBD5E1); // Slate 300

  // Semantic Status Tokens (WCAG AA >= 4.5:1)
  static const Color statusNeutralBg = Color(0xFFF1F5F9);
  static const Color statusNeutralFg = Color(0xFF334155);
  static const Color statusNeutralBorder = Color(0xFFE2E8F0);

  static const Color statusInfoBg = Color(0xFFF0F9FF);
  static const Color statusInfoFg = Color(0xFF0369A1);
  static const Color statusInfoBorder = Color(0xFFBAE6FD);

  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusWarningFg = Color(0xFF92400E);
  static const Color statusWarningBorder = Color(0xFFFDE68A);

  static const Color statusDangerBg = Color(0xFFFEF2F2);
  static const Color statusDangerFg = Color(0xFF991B1B);
  static const Color statusDangerBorder = Color(0xFFFECACA);

  static const Color statusSuccessBg = Color(0xFFECFDF5);
  static const Color statusSuccessFg = Color(0xFF065F46);
  static const Color statusSuccessBorder = Color(0xFFD1FAE5);

  // Status & Badges (kompatibilitas)
  static const Color badgeAmberBg = Color(0xFFFEF3C7);
  static const Color badgeAmberText = Color(0xFF92400E);
  static const Color badgeGreenBg = Color(0xFFECFDF5);
  static const Color badgeGreenText = Color(0xFF065F46);
  static const Color badgeNavyBg = Color(0xFF1E3A5F);
  static const Color statusCancelled = Color(0xFFDC2626);
  static const Color statusCancelledBg = Color(0xFFFEF2F2);
}
