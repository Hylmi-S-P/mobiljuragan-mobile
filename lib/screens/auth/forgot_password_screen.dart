import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';

/// Layar Pemulihan / Lupa Password
/// Mendukung pengiriman kode OTP pemulihan dan pembuatan password baru
/// dengan kriteria keamanan (8 karakter, 1 kapital, 1 simbol, 1 angka)
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController =
      TextEditingController(text: 'harun.merauke@gmail.com');
  final _otpController = TextEditingController(text: '123456');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOtpSent = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    final id = _identifierController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan email atau nomor WhatsApp akun Anda.'),
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
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode OTP pemulihan telah dikirimkan ke $id. Gunakan kode simulasi: 123456.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    });
  }

  void _handleResetPassword() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newPass = _passwordController.text;
    if (!PasswordRules.isValid(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru belum memenuhi semua persyaratan keamanan.'),
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
      final isSuccess = auth.resetPassword(
        identifier: _identifierController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: newPass,
      );

      setState(() {
        _isLoading = false;
      });

      if (isSuccess) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                SizedBox(width: 8),
                Text(
                  'Password Diperbarui',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            content: const Text(
              'Password akun Anda berhasil diganti. Silakan masuk kembali dengan password baru Anda.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
                fontFamily: 'Inter',
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Gagal memperbarui password.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: 'Lupa Password',
        stepSubtitle: _isOtpSent ? 'Atur Password Baru' : 'Verifikasi Akun Pemilik',
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
              if (!_isOtpSent) ...[
                _buildStepOneRequestOtp(),
              ] else ...[
                _buildStepTwoResetForm(),
              ],
              const SizedBox(height: 24),
              _buildFooterBackToLogin(),
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
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOtpSent ? 'Buat Password Baru' : 'Pemulihan Akses Akun',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isOtpSent
                      ? 'Masukkan kode OTP 6 digit yang dikirimkan dan tentukan password baru yang aman.'
                      : 'Masukkan email atau nomor WhatsApp yang terdaftar untuk menerima kode verifikasi OTP pemulihan.',
                  style: const TextStyle(
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

  Widget _buildStepOneRequestOtp() {
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
            'Email atau Nomor WhatsApp Terdaftar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _identifierController,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'nama@domain.com atau 812-xxxx-xxxx',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontFamily: 'Inter',
              ),
              prefixIcon: const Icon(Icons.account_circle_outlined, color: AppColors.primaryTeal, size: 20),
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
          ),
          const SizedBox(height: 12),
          const Text(
            'Kami akan mengirimkan kode 6 digit OTP untuk memverifikasi kepemilikan akun rental Anda di Merauke.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.35,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
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
                      'Kirim Kode OTP Pemulihan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwoResetForm() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Akun: ${_identifierController.text.trim()}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isOtpSent = false;
                  });
                },
                child: const Text(
                  'Ganti Akun',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Input OTP 6 Digit
          const Text(
            'Kode OTP 6 Digit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: AppColors.primaryNavy,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '123456',
              prefixIcon: const Icon(Icons.security_rounded, color: AppColors.primaryTeal, size: 20),
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
              if (val == null || val.trim().length != 6) {
                return 'Masukkan 6 digit kode OTP pemulihan.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Input Password Baru
          const Text(
            'Password Baru',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'Minimal 8 karakter unik',
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
                return 'Password belum memenuhi seluruh kriteria keamanan.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Kotak Persyaratan Password Terlihat (Checklist Real-time)
          _buildPasswordCriteriaBox(
            hasMinLength: hasMinLength,
            hasUppercase: hasUppercase,
            hasNumber: hasNumber,
            hasSymbol: hasSymbol,
          ),
          const SizedBox(height: 16),

          // Input Konfirmasi Password Baru
          const Text(
            'Konfirmasi Password Baru',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'Ulangi password baru',
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
                return 'Konfirmasi password tidak cocok dengan password baru.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Tombol Simpan Password Baru
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
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
                      'Simpan Password Baru & Masuk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
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
          const Text(
            'Syarat Keamanan Password:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          _buildCriteriaRow('Minimal 8 karakter panjangnya', hasMinLength),
          const SizedBox(height: 4),
          _buildCriteriaRow('Minimal 1 huruf kapital (A-Z)', hasUppercase),
          const SizedBox(height: 4),
          _buildCriteriaRow('Minimal 1 angka (0-9)', hasNumber),
          const SizedBox(height: 4),
          _buildCriteriaRow('Minimal 1 karakter simbol (@, #, \$, dll.)', hasSymbol),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isMet ? const Color(0xFF16A34A) : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            color: isMet ? const Color(0xFF166534) : AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBackToLogin() {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryTeal),
        label: const Text(
          'Kembali ke Halaman Masuk',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTeal,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
