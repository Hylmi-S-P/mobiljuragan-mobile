import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/validators/password_policy.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pemulihan kata sandi lewat kode verifikasi WhatsApp.
///
/// Satu layar, dua tahap: minta kode, lalu isi kode + kata sandi baru. Dipisah
/// dengan `_tahap` agar pengguna tidak perlu berpindah layar dan kehilangan
/// konteks nomor.
class ForgotPasswordScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback? onSuccess;

  const ForgotPasswordScreen({
    super.key,
    required this.phoneNumber,
    this.onSuccess,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _tahapKedua = false;
  bool _isLoading = false;
  bool _obscure = true;
  bool _passwordTouched = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refresh);
    _confirmController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refresh);
    _confirmController.removeListener(_refresh);
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _konfirmasiCocok =>
      _confirmController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;

  Future<void> _mintaKode() async {
    final auth = context.read<AuthController>();
    setState(() => _isLoading = true);

    try {
      await auth.mintaResetKataSandi(widget.phoneNumber);
      if (!mounted) return;
      setState(() {
        _tahapKedua = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode verifikasi dikirim ke ${widget.phoneNumber}.'),
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Kode belum terkirim. Coba lagi.'),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _simpanKataSandi() async {
    if (!_formKey.currentState!.validate()) return;

    if (!kataSandiValid(_passwordController.text)) {
      setState(() => _passwordTouched = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanKataSandiTidakValid(_passwordController.text)),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_konfirmasiCocok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulangi kata sandi dengan isian yang sama.'),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    setState(() => _isLoading = true);

    final galat = await auth.resetKataSandi(
      phoneNumber: widget.phoneNumber,
      otp: _otpController.text.trim(),
      kataSandiBaru: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (galat != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(galat),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kata sandi berhasil diperbarui. Anda sudah masuk.'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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
                Material(
                  color: AppColors.surfaceLight,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Lupa kata sandi',
                  style: TextStyle(
                    fontSize: AppTypography.sizeDisplay,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tahapKedua
                      ? 'Masukkan kode 6 digit yang dikirim ke WhatsApp, lalu buat kata sandi baru.'
                      : 'Kami akan mengirim kode verifikasi ke ${widget.phoneNumber} untuk membuktikan nomor ini milik Anda.',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    height: 1.45,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 24),
                if (!_tahapKedua) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _mintaKode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.borderMedium,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Kirim Kode Verifikasi',
                              style: TextStyle(
                                fontSize: AppTypography.sizeBodyLarge,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  _label('Kode Verifikasi'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                    decoration: _dekorasi(
                      hint: '000000',
                      prefix: Icons.pin_outlined,
                    ),
                    validator: (val) {
                      if (val == null || val.length != 6) {
                        return 'Kode verifikasi harus 6 digit.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('Kata Sandi Baru'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.newPassword],
                    onTap: () {
                      if (!_passwordTouched) setState(() => _passwordTouched = true);
                    },
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                    decoration: _dekorasi(
                      hint: 'Buat kata sandi baru',
                      prefix: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Kata sandi wajib diisi.';
                      return null;
                    },
                  ),
                  if (_passwordTouched) _checklist(),
                  const SizedBox(height: 12),
                  _label('Ulangi Kata Sandi'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                    decoration: _dekorasi(
                      hint: 'Ketik ulang kata sandi',
                      prefix: Icons.lock_outline_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Ulangi kata sandi wajib diisi.';
                      }
                      if (val != _passwordController.text) {
                        return 'Kata sandi belum sama.';
                      }
                      return null;
                    },
                  ),
                  if (_confirmController.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _konfirmasiCocok
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 14,
                          color: _konfirmasiCocok
                              ? AppColors.tealDark
                              : AppColors.statusCancelled,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _konfirmasiCocok ? 'Kata sandi cocok' : 'Belum cocok',
                          style: TextStyle(
                            fontSize: AppTypography.sizeTiny,
                            fontWeight: FontWeight.w600,
                            color: _konfirmasiCocok
                                ? AppColors.tealDark
                                : AppColors.statusCancelled,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanKataSandi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.borderMedium,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Simpan Kata Sandi Baru',
                              style: TextStyle(
                                fontSize: AppTypography.sizeBodyLarge,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _mintaKode,
                      child: const Text(
                        'Kirim ulang kode',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String teks) {
    return Text(
      teks,
      style: const TextStyle(
        fontSize: AppTypography.sizeBody,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        fontFamily: 'Inter',
      ),
    );
  }

  InputDecoration _dekorasi({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: AppTypography.sizeBodyLarge,
        fontWeight: FontWeight.normal,
        fontFamily: 'Inter',
      ),
      prefixIcon: Icon(prefix, color: AppColors.primaryTeal, size: 20),
      suffixIcon: suffix,
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
    );
  }

  Widget _checklist() {
    final gagal = periksaKataSandi(_passwordController.text);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: aturanTampil.map((aturan) {
          final lulus = !gagal.contains(aturan);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                lulus ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 13,
                color: lulus ? AppColors.tealDark : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                labelAturan(aturan),
                style: TextStyle(
                  fontSize: AppTypography.sizeTiny,
                  fontWeight: lulus ? FontWeight.w600 : FontWeight.w400,
                  color: lulus ? AppColors.tealDark : AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
