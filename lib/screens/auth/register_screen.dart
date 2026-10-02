import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';

/// Layar Registrasi Akun Pengguna Baru (Frame 12c)
/// Mengumpulkan data identitas resmi penyewa untuk verifikasi rental di Merauke
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
  final _emailController = TextEditingController(text: 'harun.merauke@gmail.com');
  final _nikController = TextEditingController(text: '9101012304980002');
  final _cityController = TextEditingController(text: 'Merauke, Papua Selatan');

  bool _agreementChecked = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nikController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreementChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui pernyataan keabsahan data sebelum mendaftar.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final fullPhone = _phoneController.text.trim().startsWith('+62')
          ? _phoneController.text.trim()
          : '+62 ${_phoneController.text.trim()}';

      auth.register(
        name: _nameController.text.trim(),
        phone: fullPhone,
        email: _emailController.text.trim(),
        idCard: _nikController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Akun Anda telah aktif dan terverifikasi.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Pendaftaran Akun',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderNotice(),
              const SizedBox(height: 20),
              _buildFormFields(),
              const SizedBox(height: 16),
              _buildAgreementCheckbox(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 20),
              _buildLoginFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_ind_outlined,
              size: 20,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrasi Pelanggan Baru',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sesuai ketentuan rental di Merauke, data identitas digunakan untuk perjanjian sewa sah dan verifikasi penjemputan unit.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Nama Lengkap (Sesuai KTP)', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: _inputDecoration(
              hint: 'Contoh: Harun',
              icon: Icons.person_outline_rounded,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nama lengkap wajib diisi.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildInputLabel('Nomor WhatsApp', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: _inputDecoration(
              hint: '812-4800-2910',
              icon: Icons.phone_android_rounded,
              prefixText: '+62 ',
            ),
            validator: (val) {
              if (val == null || val.trim().length < 8) {
                return 'Masukkan nomor WhatsApp valid (minimal 8 digit).';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildInputLabel('Alamat Email Aktif', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: _inputDecoration(
              hint: 'nama@domain.com',
              icon: Icons.email_outlined,
            ),
            validator: (val) {
              if (val == null || !val.contains('@') || !val.contains('.')) {
                return 'Masukkan format alamat email yang valid.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildInputLabel('Nomor Induk Kependudukan (NIK KTP)', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nikController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: _inputDecoration(
              hint: '16 digit NIK KTP',
              icon: Icons.badge_outlined,
            ).copyWith(counterText: ''),
            validator: (val) {
              if (val == null || val.trim().length != 16) {
                return 'NIK KTP harus terdiri dari tepat 16 digit.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildInputLabel('Domisili / Kota Asal', isRequired: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cityController,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: _inputDecoration(
              hint: 'Merauke, Papua Selatan',
              icon: Icons.location_on_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDC2626),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontFamily: 'Inter',
      ),
      prefixIcon: Icon(icon, size: 18, color: AppColors.primaryTeal),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
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
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreementChecked,
                activeColor: AppColors.primaryNavy,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _agreementChecked = val);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Saya menyatakan data yang saya isi adalah benar dan bersedia menunjukkan KTP fisik asli saat serah terima unit di Merauke.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
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
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
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
            : const Text(
                'Daftar & Masuk ke Akun',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
      ),
    );
  }

  Widget _buildLoginFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Sudah memiliki akun?',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Masuk di sini',
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
    );
  }
}
