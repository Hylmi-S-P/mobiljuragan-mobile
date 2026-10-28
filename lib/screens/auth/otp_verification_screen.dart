import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Layar Verifikasi OTP Pelanggan MobilJuragan (Clean Surface Auth Flow)
/// Kanvas putih minimalis, tanpa badge redundan, tanpa checkbox ganda, dilengkapi auto-submit 6 digit
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? email;
  final VoidCallback? onSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.email,
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
        content: Text('Kode OTP baru telah dikirimkan ke WhatsApp ${widget.phoneNumber}.'),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  void _handleVerifyOtp() {
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

    Future.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final isSuccess = await auth.verifyOtp(code);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (isSuccess) {
        if (!mounted) return;
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Minimal Header (Tanpa Badge Kuning Berlebih)
              _buildTopHeader(),
              const SizedBox(height: 28),

              // 2. Hero Title & Integrated Target Phone Box
              _buildHeroTitle(),
              const SizedBox(height: 28),

              // 3. Error Banner jika ada
              if (hasError) ...[
                _buildErrorBanner(auth.errorMessage),
                const SizedBox(height: 20),
              ],

              // 4. 6 Kotak Digit OTP dengan Auto-Submit
              _buildOtpBoxes(auth, hasError),
              const SizedBox(height: 20),

              // 5. Timer Hitung Mundur Bersih (Tanpa Checkbox Kedua!)
              _buildResendRow(),
              const SizedBox(height: 32),

              // 6. Tombol Primary CTA (Navy #1E293B)
              _buildSubmitButton(hasError),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Langkah 2 dari 2',
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 56,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verifikasi Kode OTP',
          style: TextStyle(
            fontSize: AppTypography.sizeDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan 6 digit kode yang dikirim via WhatsApp ke nomor:',
          style: TextStyle(
            fontSize: AppTypography.sizeBodyLarge,
            color: AppColors.textSecondary,
            height: 1.45,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '•',
                style: TextStyle(color: AppColors.borderMedium),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String? message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'Kode OTP tidak sesuai atau kedaluwarsa. Silakan periksa kembali pesan WhatsApp Anda.',
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB91C1C),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBoxes(AuthController auth, bool hasError) {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Container(
            height: 52,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == 5 ? 0 : 4,
            ),
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: hasError ? const Color(0xFFDC2626) : AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: hasError
                    ? const Color(0xFFFEF2F2)
                    : (_otpControllers[index].text.isNotEmpty
                        ? Colors.white
                        : AppColors.surfaceLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? const Color(0xFFDC2626) : AppColors.borderMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? const Color(0xFFDC2626)
                        : (_otpControllers[index].text.isNotEmpty
                            ? AppColors.primaryNavy
                            : AppColors.borderMedium),
                    width: _otpControllers[index].text.isNotEmpty ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? const Color(0xFFDC2626) : AppColors.primaryNavy,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                if (hasError) {
                  auth.clearErrorState();
                }
                setState(() {});
                if (value.isNotEmpty) {
                  if (index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else {
                    _otpFocusNodes[index].unfocus();
                    // Auto-submit saat kotak ke-6 terisi
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
    );
  }

  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Belum menerima pesan?',
          style: TextStyle(
            fontSize: AppTypography.sizeCaption,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        _resendSeconds > 0
            ? Text(
                'Kirim ulang ($_formattedTimer)',
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              )
            : InkWell(
                onTap: _handleResendOtp,
                child: const Text(
                  'Kirim Ulang OTP',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildSubmitButton(bool hasError) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (hasError ? _resetOtpForm : _handleVerifyOtp),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasError ? const Color(0xFFDC2626) : AppColors.primaryNavy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                hasError ? 'Coba Lagi' : 'Verifikasi & Masuk',
                style: const TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
      ),
    );
  }
}
