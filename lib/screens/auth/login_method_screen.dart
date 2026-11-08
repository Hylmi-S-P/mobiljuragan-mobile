import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'login_password_screen.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';

/// Layar pemilihan cara masuk.
///
/// Nomor diisi lebih dulu, lalu pengguna memilih **kode verifikasi** atau
/// **kata sandi**. Dua tombol selalu ditampilkan — bukan disembunyikan menurut
/// "akun ini punya kata sandi atau tidak" — karena tampilan yang berbeda-beda
/// membocorkan nomor mana yang terdaftar.
class LoginMethodScreen extends StatelessWidget {
  final String phoneNumber;
  final VoidCallback? onSuccess;

  const LoginMethodScreen({
    super.key,
    required this.phoneNumber,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final sedangKirim = auth.isLoadingOtp;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _tombolKembali(context),
                  const Spacer(),
                  Text(
                    'Langkah 2 dari 2',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Pilih cara masuk',
                style: TextStyle(
                  fontSize: AppTypography.sizeDisplay,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nomor $phoneNumber terdaftar. Masuk dengan kode WhatsApp atau kata sandi Anda.',
                style: const TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  height: 1.45,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderMedium),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_iphone_rounded,
                        size: 20, color: AppColors.primaryTeal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        phoneNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Ubah'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _tombolUtama(
                context,
                label: sedangKirim ? 'Mengirim kode...' : 'Kirim Kode OTP ke WhatsApp',
                ikon: Icons.chat_bubble_outline_rounded,
                onTap: sedangKirim
                    ? null
                    : () => _kirimOtp(context),
              ),
              const SizedBox(height: 12),
              _tombolSekunder(
                context,
                label: 'Masuk dengan kata sandi',
                ikon: Icons.lock_outline_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LoginPasswordScreen(
                        phoneNumber: phoneNumber,
                        onSuccess: onSuccess,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(onSuccess: onSuccess),
                      ),
                    );
                  },
                  child: const Text(
                    'Belum punya akun? Daftar',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _kirimOtp(BuildContext context) async {
    final auth = context.read<AuthController>();
    final terkirim = await auth.sendOtp(phoneNumber);

    if (!context.mounted) return;

    if (!terkirim) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Kode verifikasi belum terkirim. Periksa koneksi lalu coba lagi.',
          ),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: phoneNumber,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  Widget _tombolKembali(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _tombolUtama(
    BuildContext context, {
    required String label,
    required IconData ikon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(ikon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: AppTypography.sizeBodyLarge,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderMedium,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _tombolSekunder(
    BuildContext context, {
    required String label,
    required IconData ikon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(ikon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: AppTypography.sizeBodyLarge,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.borderMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
