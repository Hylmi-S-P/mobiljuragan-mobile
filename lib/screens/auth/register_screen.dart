import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import 'otp_verification_screen.dart';
import '../../theme/app_typography.dart';

/// Layar Registrasi Akun Pengguna Baru
/// Mengumpulkan data diri lengkap beserta kata sandi yang memenuhi kriteria keamanan
/// Selanjutnya mengarahkan pengguna ke tahap Verifikasi OTP untuk aktivasi akun
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreementChecked = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_onPasswordFocusChanged);
  }

  void _onPasswordFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_onPasswordFocusChanged);
    _passwordFocusNode.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nikController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  void _handleContinueToOtp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final password = _passwordController.text;
    if (!PasswordRules.isValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password belum memenuhi seluruh kriteria keamanan yang dipersyaratkan.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!_agreementChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui pernyataan keabsahan data sebelum melanjutkan.'),
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
      final rawPhone = _phoneController.text.trim();
      final fullPhone = rawPhone.startsWith('+62') ? rawPhone : '+62 $rawPhone';
      final email = _emailController.text.trim();

      // Simpan data pendaftaran ke controller untuk verifikasi OTP berikutnya
      auth.setPendingRegistration(
        name: _nameController.text.trim(),
        phone: fullPhone,
        email: email,
        idCard: _nikController.text.trim(),
        city: _cityController.text.trim(),
        password: password,
      );

      auth.sendOtp(fullPhone);

      setState(() {
        _isLoading = false;
      });

      // Buka Layar Verifikasi OTP Pendaftaran (Frame 12/12b style)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: fullPhone,
            email: email,
            onSuccess: widget.onSuccess,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Pendaftaran Akun',
        stepSubtitle: 'Langkah 1 dari 2 • Data Diri & Keamanan',
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
              const SizedBox(height: 18),
              _buildPersonalDataSection(),
              const SizedBox(height: 18),
              _buildSecuritySection(),
              const SizedBox(height: 16),
              _buildAgreementCheckbox(),
              const SizedBox(height: 22),
              _buildSubmitButton(),
              const SizedBox(height: 18),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
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
                    fontSize: AppTypography.sizeTitle,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lengkapi data resmi untuk reservasi unit rental di Merauke. Kode OTP 6 digit akan dikirimkan pada tahap berikutnya.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
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

  Widget _buildPersonalDataSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Identitas Diri',
            style: TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 14),

          _buildInputLabel('Nama Lengkap (Sesuai KTP)', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
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
          const SizedBox(height: 14),

          _buildInputLabel('Nomor WhatsApp', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
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
          const SizedBox(height: 14),

          _buildInputLabel('Alamat Email Aktif', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
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
          const SizedBox(height: 14),

          _buildInputLabel('Nomor Induk Kependudukan (NIK KTP)', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nikController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
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
          const SizedBox(height: 14),

          _buildInputLabel('Domisili / Kota Asal', isRequired: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cityController,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
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

  Widget _buildSecuritySection() {
    final passwordText = _passwordController.text;
    final hasMinLength = PasswordRules.hasMinLength(passwordText);
    final hasUppercase = PasswordRules.hasUppercase(passwordText);
    final hasNumber = PasswordRules.hasNumber(passwordText);
    final hasSymbol = PasswordRules.hasSymbol(passwordText);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keamanan & Password Akun',
            style: TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 14),

          _buildInputLabel('Password Akun', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: !_isPasswordVisible,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan password Anda',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryTeal, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                tooltip: _isPasswordVisible ? 'Sembunyikan password' : 'Lihat password',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || !PasswordRules.isValid(val)) {
                return 'Password belum memenuhi seluruh kriteria di bawah.';
              }
              return null;
            },
          ),

          // Checklist Syarat Keamanan Password (Hanya muncul saat mulai menulis password)
          if (_passwordFocusNode.hasFocus || passwordText.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildPasswordCriteriaBox(
              hasMinLength: hasMinLength,
              hasUppercase: hasUppercase,
              hasNumber: hasNumber,
              hasSymbol: hasSymbol,
            ),
          ],
          const SizedBox(height: 14),

          _buildInputLabel('Konfirmasi Password', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'Ulangi password di atas',
              prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryTeal, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                tooltip: _isConfirmPasswordVisible ? 'Sembunyikan password' : 'Lihat password',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val != _passwordController.text) {
                return 'Konfirmasi password tidak cocok dengan password di atas.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCriteriaBox({
    required bool hasMinLength,
    required bool hasUppercase,
    required bool hasNumber,
    required bool hasSymbol,
  }) {
    final bool isAllMet = hasMinLength && hasUppercase && hasNumber && hasSymbol;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAllMet ? const Color(0xFFF0FDF4) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAllMet ? const Color(0xFF86EFAC) : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAllMet ? Icons.shield_rounded : Icons.shield_outlined,
                size: 15,
                color: isAllMet ? const Color(0xFF16A34A) : AppColors.primaryTeal,
              ),
              const SizedBox(width: 6),
              Text(
                'Syarat Keamanan Password:',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w700,
                  color: isAllMet ? const Color(0xFF166534) : AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCriteriaRow('Minimal 8 karakter panjangnya', hasMinLength),
          const SizedBox(height: 4),
          _buildCriteriaRow('Minimal 1 huruf kapital (A-Z)', hasUppercase),
          const SizedBox(height: 4),
          _buildCriteriaRow('Minimal 1 angka (0-9)', hasNumber),
          const SizedBox(height: 4),
          _buildCriteriaRow('Minimal 1 karakter simbol (@, #, \$, dll.)', hasSymbol),
          if (isAllMet) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Password kuat dan memenuhi seluruh kriteria keamanan.',
                      style: TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String text, bool isMet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              key: ValueKey<bool>(isMet),
              size: 15,
              color: isMet ? const Color(0xFF16A34A) : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
                color: isMet ? const Color(0xFF166534) : AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
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
            fontSize: AppTypography.sizeBody,
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
              fontSize: AppTypography.sizeBody,
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
        fontSize: AppTypography.sizeBodyLarge,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontFamily: 'Inter',
      ),
      prefixIcon: Icon(icon, size: 18, color: AppColors.primaryTeal),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: AppTypography.sizeBody,
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
                  fontSize: AppTypography.sizeCaption,
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
      height: (48 * MediaQuery.textScalerOf(context).scale(1)).clamp(48, 96),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleContinueToOtp,
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjut ke Verifikasi OTP',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTitle,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
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
              fontSize: AppTypography.sizeBody,
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
}
