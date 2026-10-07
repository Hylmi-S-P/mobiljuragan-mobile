import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../theme/app_typography.dart';

/// Layar Masuk / Login Standar Aplikasi Mobile
/// Pengguna hanya perlu memasukkan Email atau Nomor HP dan Password
/// Dilengkapi fitur Lupa Password, toggle show/hide password, dan pintasan akun demo
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
  final TextEditingController _identifierController =
      TextEditingController(text: 'harun.merauke@gmail.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Merauke#2026');

  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final id = _identifierController.text.trim();
    final pass = _passwordController.text;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final isSuccess = auth.loginWithPassword(identifier: id, password: pass);

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
                'Mengalami kendala saat login atau lupa data akun Anda? Layanan pelanggan CV. Mobil Juragan Merauke siap membantu pada jam operasional (06.00 - 22.00 WIT).',
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
                            'WhatsApp Resmi CS',
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
            ? 'Login Gagal • Kredensial Tidak Sesuai'
            : 'Merauke, Papua Selatan',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Card Sambutan
              _buildHeroCard(),
              const SizedBox(height: 16),

              // 2. Form Login Card (Email/No HP & Password)
              _buildFormCard(auth, hasError),
              const SizedBox(height: 16),

              // 3. Tombol Masuk Utama
              _buildSubmitButton(auth, hasError),
              const SizedBox(height: 14),

              // 4. Support Box CS Merauke
              _buildSupportBox(),
              const SizedBox(height: 24),

              // 5. Footer Registrasi & Grounding Identitas
              _buildFooter(),
            ],

          ),
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
                Icons.person_pin_circle_outlined,
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
                  'Portal Layanan Rental Pelanggan',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTitle,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Masuk menggunakan Email atau Nomor HP terdaftar untuk mengelola sewa dan memantau status pesanan.',
                  style: TextStyle(
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
          // Banner Error (jika login gagal)
          if (hasError) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.errorMessage ?? 'Email/No HP atau password salah. Cek kembali data Anda.',
                      style: const TextStyle(
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

          // Field 1: Email atau Nomor WhatsApp
          const Text(
            'Email atau Nomor WhatsApp',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _identifierController,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'nama@domain.com atau 812-xxxx-xxxx',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppTypography.sizeBody,
                fontFamily: 'Inter',
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryTeal, size: 20),
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
              if (val == null || val.trim().isEmpty) {
                return 'Email atau Nomor WhatsApp wajib diisi.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Field 2: Password
          const Text(
            'Password Akun',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan password Anda',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppTypography.sizeBody,
                fontFamily: 'Inter',
              ),
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
              if (val == null || val.isEmpty) {
                return 'Password tidak boleh kosong.';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Baris Ingat Saya & Lupa Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      activeColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Ingat Saya',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Lupa Password?',
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
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthController auth, bool hasError) {
    return SizedBox(
      width: double.infinity,
      height: (50 * MediaQuery.textScalerOf(context).scale(1)).clamp(50, 100),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                style: AppTypography.sectionTitle,
              ),
      ),
    );
  }

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
                      fontSize: AppTypography.sizeBody,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hubungi CS Merauke: +62 812-4800-9921',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
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
                  fontSize: AppTypography.sizeBody,
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
                    fontSize: AppTypography.sizeBody,
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
              fontSize: AppTypography.sizeCaption,
              color: AppColors.textMuted,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
