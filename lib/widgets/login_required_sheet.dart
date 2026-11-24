import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'standard_bottom_sheet.dart';

/// Menampilkan bottom sheet pilihan masuk/daftar untuk fitur yang mewajibkan akun.
Future<void> showLoginRequiredSheet({
  required BuildContext context,
  required String subtitle,
  required String description,
  required VoidCallback onAuthenticated,
}) async {
  final navigator = Navigator.of(context);
  final returnRoute = ModalRoute.of(context);

  void selesaikanAutentikasi() {
    navigator.popUntil(
      (route) => route == returnRoute || route.isFirst,
    );
    onAuthenticated();
  }

  await StandardBottomSheet.show<void>(
    context: context,
    title: 'Masuk atau Buat Akun',
    subtitle: subtitle,
    icon: Icons.account_circle_outlined,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              height: 1.45,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
          child: ElevatedButton.icon(
            onPressed: () {
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    onSuccess: selesaikanAutentikasi,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text(
              'Masuk ke Akun',
              style: AppTypography.cardTitle,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
          child: OutlinedButton(
            onPressed: () {
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(
                    onSuccess: selesaikanAutentikasi,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
            ),
            child: const Text(
              'Daftar Akun Baru',
              style: TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
