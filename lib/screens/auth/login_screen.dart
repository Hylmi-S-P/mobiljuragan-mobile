import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';
import '../../theme/app_typography.dart';

/// Layar Masuk Akun Pelanggan MobilJuragan (Clean Surface Auth Flow)
/// Desain kanvas putih minimalis, tanpa kartu berulang (Box-in-a-Box)
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController =
      TextEditingController(text: '812-4800-2910');

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRequestOtp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final rawPhone = _phoneController.text.trim();
    final fullPhone = rawPhone.startsWith('+62') ? rawPhone : '+62 $rawPhone';

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      auth.sendOtp(fullPhone);

      setState(() {
        _isLoading = false;
      });

      // Buka Layar Verifikasi OTP
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: fullPhone,
            onSuccess: widget.onSuccess,
          ),
        ),
      );
    });
  }

  void _showSupportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.headset_mic_rounded, color: AppColors.primaryNavy, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Pusat Bantuan CS Merauke',
                    style: TextStyle(
                      fontSize: AppTypography.sizeHeading,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Mengalami kendala saat masuk akun rental? Layanan pelanggan CV. Mobil Juragan Merauke siap membantu pada jam operasional (06.00 : 22.00 WIT).',
                style: TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
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
                            'WhatsApp Resmi Layanan CS',
                            style: TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '+62 812-4800-9921',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTitle,
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
                height: 48,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Minimal Header
                _buildTopHeader(),
                const SizedBox(height: 28),

                // 2. Hero Title & Subtitle (Langsung di kanvas putih, tanpa card border)
                _buildHeroTitle(),
                const SizedBox(height: 28),

                // 3. Banner Error jika ada
                if (hasError) ...[
                  _buildErrorBanner(auth.errorMessage),
                  const SizedBox(height: 16),
                ],

                // 4. Form Input Nomor WhatsApp dengan Prefix Box +62
                _buildPhoneField(),
                const SizedBox(height: 22),

                // 5. Tombol Primary CTA (Navy #1E293B)
                _buildSubmitButton(),
                const SizedBox(height: 20),

                // 6. Link Pendaftaran Akun Baru
                _buildRegisterLink(),
                const SizedBox(height: 36),

                // 7. Footer Bantuan Ringkas (Border atas tipis)
                _buildFooterSupport(),
                const SizedBox(height: 16),
              ],
            ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'MobilJuragan Merauke',
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

  Widget _buildHeroTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat Datang Kembali',
          style: TextStyle(
            fontSize: AppTypography.sizeDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan nomor WhatsApp Anda yang terdaftar untuk menerima kode masuk (OTP).',
          style: TextStyle(
            fontSize: AppTypography.sizeBodyLarge,
            color: AppColors.textSecondary,
            height: 1.45,
            fontFamily: 'Inter',
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
              message ?? 'Nomor WhatsApp belum terdaftar atau tidak valid.',
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

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nomor WhatsApp',
          style: TextStyle(
            fontSize: AppTypography.sizeBody,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderMedium),
          ),
          child: Row(
            children: [
              // Prefix Box +62 centered tanpa bendera
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
                  border: Border(
                    right: BorderSide(color: AppColors.borderMedium),
                  ),
                ),
                child: const Text(
                  '+62',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTitle,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              // Input nomor telepon
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                  decoration: const InputDecoration(
                    hintText: '812-xxxx-xxxx',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Inter',
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 8) {
                      return 'Masukkan nomor WhatsApp valid (minimal 8 digit).';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRequestOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kirim Kode OTP',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Belum memiliki akun? ',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(onSuccess: widget.onSuccess),
                ),
              );
            },
            child: const Text(
              'Daftar baru',
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
    );
  }

  Widget _buildFooterSupport() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kendala saat masuk akun?',
            style: TextStyle(
              fontSize: AppTypography.sizeCaption,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          InkWell(
            onTap: _showSupportDialog,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hubungi CS',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryTeal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
