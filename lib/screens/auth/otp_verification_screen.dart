import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_typography.dart';

/// Layar Verifikasi OTP untuk Pendaftaran Akun Baru (Frame 12 & 12b style)
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final VoidCallback? onSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.email,
    this.onSuccess,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _agreeTerms = true;
  int _resendSeconds = 105; // 01:45 hitung mundur
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdownTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendSeconds = 105;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTimer {
    final minutes = (_resendSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleResendOtp() {
    if (_resendSeconds > 0) return;
    _startCountdownTimer();
    context.read<AuthController>().sendOtp(widget.phoneNumber);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode OTP baru telah dikirimkan ke nomor ${widget.phoneNumber}.'),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  void _handleVerifyOtp() {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui Ketentuan Layanan dan Kebijakan Privasi terlebih dahulu.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final code = _otpControllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan 6 digit kode OTP secara lengkap.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final isSuccess = auth.verifyRegisterOtp(code);

      setState(() {
        _isLoading = false;
      });

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi berhasil! Selamat datang di MobilJuragan Merauke.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          // Tutup layar auth dan kembali ke halaman utama aplikasi
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        HapticFeedback.vibrate();
      }
    });
  }

  void _resetOtpForm() {
    final auth = context.read<AuthController>();
    auth.clearErrorState();
    for (final c in _otpControllers) {
      c.clear();
    }
    setState(() {
      _isLoading = false;
    });
    _otpFocusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final hasError = auth.hasLoginError;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: 'Verifikasi Nomor OTP',
        stepSubtitle: hasError
            ? 'Kode OTP Tidak Cocok'
            : 'Langkah 2 dari 2 • Aktivasi Pendaftaran',
        showBackButton: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasError ? const Color(0xFFFEE2E2) : AppColors.badgeAmberBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasError ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
              ),
            ),
            child: Text(
              hasError ? 'State: Error' : 'Tahap OTP',
              style: TextStyle(
                fontSize: AppTypography.sizeTiny,
                fontWeight: FontWeight.w700,
                color: hasError ? const Color(0xFFB91C1C) : AppColors.badgeAmberText,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card
            _buildHeroCard(),
            const SizedBox(height: 16),

            // 2. Form Card 6 Kotak OTP
            _buildFormCard(auth, hasError),
            const SizedBox(height: 16),

            // 3. Tombol Aksi Utama
            _buildSubmitButton(auth, hasError),
            const SizedBox(height: 24),

            // 4. Grounding Footer Institusional
            const Center(
              child: Text(
                'CV. Mobil Juragan Express Transport • Merauke, Papua Selatan',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.mark_email_read_outlined,
                color: AppColors.primaryTeal,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verifikasi Akun Baru',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTitle,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Masukkan 6 digit kode OTP yang telah dikirimkan ke nomor ${widget.phoneNumber} untuk mengaktifkan akun rental Anda.',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthController auth, bool hasError) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? const Color(0xFFFCA5A5) : AppColors.borderSubtle,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nomor WhatsApp Terdaftar',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Ubah Data',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, thickness: 1, height: 1),
          const SizedBox(height: 14),

          // Label OTP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kode Verifikasi OTP (6 Digit)',
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              if (hasError)
                const Text(
                  'Kode Tidak Cocok',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),

          // Error Banner jika OTP keliru
          if (hasError) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kode OTP tidak sesuai atau kedaluwarsa. Silakan periksa kembali pesan WhatsApp Anda.',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB91C1C),
                        height: 1.35,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 6 Kotak Digit OTP
          Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Container(
                  height: 48,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 3,
                    right: index == 5 ? 0 : 3,
                  ),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMetric,
                      fontWeight: FontWeight.w800,
                      color: hasError ? const Color(0xFFDC2626) : AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: hasError
                          ? const Color(0xFFFEF2F2)
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: hasError ? const Color(0xFFDC2626) : AppColors.borderMedium,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: hasError ? const Color(0xFFDC2626) : AppColors.borderMedium,
                          width: hasError ? 1.5 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: hasError ? const Color(0xFFDC2626) : AppColors.primaryTeal,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (hasError) {
                        auth.clearErrorState();
                      }
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else {
                          _otpFocusNodes[index].unfocus();
                          _handleVerifyOtp();
                        }
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Timer Hitung Mundur 01:45
          Center(
            child: _resendSeconds > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kirim ulang kode dalam $_formattedTimer',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: _handleResendOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.primaryTeal),
                    label: const Text(
                      'Kirim Ulang Kode OTP Sekarang',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Checkbox Persetujuan Syarat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreeTerms,
                  onChanged: (val) {
                    setState(() {
                      _agreeTerms = val ?? true;
                    });
                  },
                  activeColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Saya menyetujui Ketentuan Layanan dan Kebijakan Privasi MobilJuragan.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthController auth, bool hasError) {
    return SizedBox(
      width: double.infinity,
      height: (50 * MediaQuery.textScalerOf(context).scale(1)).clamp(50, 100),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (hasError ? _resetOtpForm : _handleVerifyOtp),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasError ? const Color(0xFFDC2626) : AppColors.primaryNavy,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                hasError ? 'Coba Lagi' : 'Verifikasi & Selesaikan Pendaftaran',
                style: const TextStyle(
                  fontSize: AppTypography.sizeTitle,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
      ),
    );
  }
}
