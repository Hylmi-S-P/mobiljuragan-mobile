import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import 'register_screen.dart';

/// Layar Autentikasi Pengguna & Verifikasi OTP (Figma Frame 12 & 12b)
/// Menampilkan form input nomor WhatsApp dan 6 kotak kode OTP terpadu
/// Dilengkapi status verifikasi cepat, countdown timer 01:45, support box, dan simulasi demo error state 12b
class LoginScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const LoginScreen({
    super.key,
    this.onSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController(text: '812-4800-2910');
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _agreeTerms = true;
  int _resendSeconds = 105; // 01:45 hitung mundur sesuai spesifikasi Frame 12
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
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
    final rawPhone = _phoneController.text.trim();
    final fullPhone = '+62 $rawPhone';
    context.read<AuthController>().sendOtp(fullPhone);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode OTP baru telah dikirimkan ke $fullPhone via WhatsApp/SMS.'),
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
      final isSuccess = auth.verifyOtp(code);

      setState(() {
        _isLoading = false;
      });

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil! Selamat datang kembali di MobilJuragan.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        HapticFeedback.vibrate();
      }
    });
  }

  void _fillDemoOtp(String code) {
    final auth = context.read<AuthController>();
    auth.clearErrorState();

    for (int i = 0; i < 6; i++) {
      if (i < code.length) {
        _otpControllers[i].text = code[i];
      } else {
        _otpControllers[i].clear();
      }
    }

    if (code.length >= 6) {
      _otpFocusNodes[5].requestFocus();
      _handleVerifyOtp();
    } else {
      _otpFocusNodes[code.length].requestFocus();
    }
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

  void _showSupportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.headset_mic_rounded, color: AppColors.primaryNavy, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Pusat Bantuan CS Merauke',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Kendala saat menerima kode OTP 6 digit? Tim layanan pelanggan CV. Mobil Juragan Merauke siap membantu aktivasi akun rental Anda.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_outlined, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Resmi CS',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '+62 812-4800-9921',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungkan ke layanan CS WhatsApp Merauke (+62 812-4800-9921)...'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text(
                    'Hubungi via WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final hasError = auth.hasLoginError;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: 'Masuk Akun',
        stepSubtitle: hasError
            ? 'Verifikasi Gagal • Kode Tidak Sesuai'
            : 'Merauke, Papua Selatan',
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
              hasError ? 'State: Error' : 'Verifikasi Cepat',
              style: TextStyle(
                fontSize: 10.5,
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
            // 1. Hero Card S12 (Verifikasi Akun Pelanggan)
            _buildHeroCard(),
            const SizedBox(height: 16),

            // 2. Form Card S12 (Nomor WhatsApp & 6 Digit OTP)
            _buildFormCard(auth, hasError),
            const SizedBox(height: 16),

            // 3. Tombol Aksi Masuk Utama
            _buildSubmitButton(auth, hasError),
            const SizedBox(height: 14),

            // 4. Support Box S12 (Hubungi CS Merauke)
            _buildSupportBox(),
            const SizedBox(height: 16),

            // 5. Helper Pengujian Demo UAS
            _buildDemoHelper(auth),
            const SizedBox(height: 20),

            // 6. Footer Registrasi & Grounding Identitas
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Hero Card S12 (Node 1071:1749 / 1213:560)
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
                Icons.verified_user_outlined,
                color: AppColors.primaryTeal,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verifikasi Akun Pelanggan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Masuk aman untuk memantau status pesanan dan konfirmasi armada rental di Merauke.',
                  style: TextStyle(
                    fontSize: 11.5,
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

  /// Form Card S12 (Node 1071:1754 / 1213:565)
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
          // Input Nomor WhatsApp
          const Text(
            'Nomor WhatsApp / Telepon',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderMedium),
                ),
                alignment: Alignment.center,
                child: const Row(
                  children: [
                    Text('🇮🇩', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      '+62',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                    decoration: InputDecoration(
                      hintText: '812-xxxx-xxxx',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderMedium),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderMedium),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kode OTP 6 digit dikirimkan via SMS atau WhatsApp.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 14),

          // Garis Pemisah
          const Divider(color: AppColors.borderSubtle, thickness: 1, height: 1),
          const SizedBox(height: 14),

          // Label OTP 6 Digit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kode Verifikasi OTP (6 Digit)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              if (hasError)
                const Text(
                  'Kode Salah',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),

          // Error Banner Frame 12b (jika error)
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
                      'Kode OTP tidak sesuai atau kedaluwarsa. Silakan periksa kembali SMS atau WhatsApp Anda.',
                      style: TextStyle(
                        fontSize: 11,
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

          // 6 Kotak Digit OTP Sesuai Desain Figma
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
                      fontSize: 19,
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
          const SizedBox(height: 14),

          // Timer Hitung Mundur 01:45 atau Tombol Kirim Ulang
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
                          fontSize: 11.5,
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Checkbox Persetujuan Syarat & Ketentuan Layanan
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
                    fontSize: 11,
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

  /// Tombol Masuk Utama (Node 1071:1779 / 1213:590)
  Widget _buildSubmitButton(AuthController auth, bool hasError) {
    return SizedBox(
      width: double.infinity,
      height: 50,
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
                hasError ? 'Coba Lagi' : 'Masuk Sekarang',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
      ),
    );
  }

  /// Support Box S12 (Node 1071:1781 / 1213:592)
  Widget _buildSupportBox() {
    return InkWell(
      onTap: _showSupportDialog,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Butuh Bantuan Masuk?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hubungi CS Merauke: +62 812-4800-9921',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFF60A5FA),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper Simulasi Pengujian Demo UAS
  Widget _buildDemoHelper(AuthController auth) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primaryTeal),
              SizedBox(width: 6),
              Text(
                'Pintasan Pengujian Demo UAS:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _fillDemoOtp('123456'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Uji Sukses (123456)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _fillDemoOtp('999999'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Uji Error 12b (999999)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Footer Registrasi & Grounding Identitas
  Widget _buildFooter() {
    return Column(
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Belum memiliki akun rental?',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(onSuccess: widget.onSuccess),
                    ),
                  );
                },
                child: const Text(
                  'Daftar Sekarang',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'CV. Mobil Juragan Express Transport • Merauke, Papua Selatan',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
