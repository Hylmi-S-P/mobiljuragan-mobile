import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import '../../theme/app_typography.dart';

/// Layar Registrasi Akun Pelanggan MobilJuragan (Clean Surface Auth Flow)
/// Mengumpulkan data: Nama Lengkap, Nomor WhatsApp, dan Jenis Kelamin (Segmented Pill)
/// Menggunakan kanvas putih minimalis tanpa kotak bertumpuk (Card-itis)
class RegisterScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const RegisterScreen({
    super.key,
    this.onSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Harun');
  final _phoneController = TextEditingController(text: '812-4800-2910');

  String _selectedGender = 'Laki-laki';
  bool _agreementChecked = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinueToOtp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreementChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui pernyataan data sebelum melanjutkan.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final rawPhone = _phoneController.text.trim();
      final fullPhone = rawPhone.startsWith('+62') ? rawPhone : '+62 $rawPhone';

      // Simpan data pendaftaran sementara ke controller
      auth.setPendingRegistration(
        name: _nameController.text.trim(),
        phone: fullPhone,
        gender: _selectedGender,
      );

      // Minta kode OTP ke nomor WhatsApp
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

  @override
  Widget build(BuildContext context) {
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
                // 1. Top Minimal Header + Step Indicator
                _buildTopHeader(),
                const SizedBox(height: 24),

                // 2. Hero Title & Subtitle (Langsung di kanvas putih)
                _buildHeroTitle(),
                const SizedBox(height: 24),

                // 3. Form Input: Nama Lengkap
                _buildNameField(),
                const SizedBox(height: 16),

                // 4. Form Input: Nomor WhatsApp dengan Prefix Box +62
                _buildPhoneField(),
                const SizedBox(height: 16),

                // 5. Form Input: Jenis Kelamin (Segmented Radio Pills)
                _buildGenderSelector(),
                const SizedBox(height: 16),

                // 6. Checkbox Persetujuan (Langsung inline tanpa card border)
                _buildAgreementCheckbox(),
                const SizedBox(height: 24),

                // 7. Tombol Primary CTA (Navy #1E293B)
                _buildSubmitButton(),
                const SizedBox(height: 18),

                // 8. Footer Masuk Akun
                _buildLoginFooter(),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Langkah 1 dari 2',
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
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
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
          'Buat Akun Pelanggan',
          style: TextStyle(
            fontSize: AppTypography.sizeDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lengkapi identitas singkat untuk kemudahan reservasi armada di Merauke.',
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

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Nama Lengkap (sesuai KTP)', isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: Harun',
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter',
            ),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryTeal,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nama lengkap wajib diisi.';
            }
            if (val.trim().length < 3) {
              return 'Nama lengkap minimal 3 karakter.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Nomor WhatsApp', isRequired: true),
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
                    hintText: '812-4800-2910',
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

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Jenis Kelamin', isRequired: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                label: 'Laki-laki',
                isSelected: _selectedGender == 'Laki-laki',
                onTap: () {
                  setState(() {
                    _selectedGender = 'Laki-laki';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                label: 'Perempuan',
                isSelected: _selectedGender == 'Perempuan',
                onTap: () {
                  setState(() {
                    _selectedGender = 'Perempuan';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.borderMedium,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _agreementChecked = !_agreementChecked;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreementChecked,
                activeColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  setState(() {
                    _agreementChecked = val ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Saya menyatakan data di atas benar dan menyetujui Syarat Layanan serta pengiriman OTP via WhatsApp.',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleContinueToOtp,
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
                    'Lanjut ke Verifikasi OTP',
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

  Widget _buildLoginFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sudah memiliki akun? ',
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
                  builder: (_) => LoginScreen(onSuccess: widget.onSuccess),
                ),
              );
            },
            child: const Text(
              'Masuk di sini',
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

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: AppTypography.sizeBody,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
