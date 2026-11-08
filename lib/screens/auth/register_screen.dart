import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/validators/password_policy.dart';
import '../../data/remote/auth_api_service.dart' show NiatOtp;
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

  /* Tidak ada lagi isian yang diisi lebih dulu.
   *
   * Sebelumnya kolom nama berisi "Harun" dan nomor terisi sebagian. Nilai itu
   * bukan sekadar contoh tampilan: kalau pengguna menekan lanjut tanpa mengubah,
   * yang terkirim adalah identitas orang lain. */
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  String _selectedGender = 'Laki-laki';
  bool _agreementChecked = false;
  bool _isLoading = false;

  /// Checklist baru muncul setelah kolom kata sandi disentuh.
  bool _passwordTouched = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordState);
    _passwordConfirmController.addListener(_refreshPasswordState);
  }

  void _refreshPasswordState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordState);
    _passwordConfirmController.removeListener(_refreshPasswordState);
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  /// Aturan kata sandi yang belum terpenuhi, memakai nama & nomor yang diketik
  /// supaya kata sandi yang menyalin identitas sendiri ikut tertolak.
  Set<AturanKataSandi> get _pelanggaranKataSandi => periksaKataSandi(
        _passwordController.text,
        namaLengkap: _nameController.text,
        nomorTelepon: _phoneController.text,
      );

  bool get _konfirmasiCocok =>
      _passwordConfirmController.text.isNotEmpty &&
      _passwordController.text == _passwordConfirmController.text;


  void _handleContinueToOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreementChecked) {
      _tampilkanPesan('Harap setujui pernyataan data sebelum melanjutkan.');
      return;
    }

    /* Kata sandi diperiksa lagi di sini — bukan hanya lewat validator form —
     * karena aturan "jangan memakai nama/nomor sendiri" butuh nilai dari kolom
     * lain. Server tetap memeriksa ulang; ini hanya agar pengguna tidak menunggu
     * satu perjalanan jaringan untuk tahu aturannya belum lengkap. */
    if (periksaKataSandi(
      _passwordController.text,
      namaLengkap: _nameController.text,
      nomorTelepon: _phoneController.text,
    ).isNotEmpty) {
      setState(() => _passwordTouched = true);
      _tampilkanPesan('Kata sandi belum memenuhi semua syarat.');
      return;
    }

    if (!_konfirmasiCocok) {
      _tampilkanPesan('Ulangi kata sandi dengan isian yang sama.');
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    final rawPhone = _phoneController.text.trim();
    final fullPhone = rawPhone.startsWith('+62') ? rawPhone : '+62 $rawPhone';

    // Simpan data pendaftaran sementara (termasuk kata sandi) di memori.
    auth.setPendingRegistration(
      name: _nameController.text.trim(),
      phone: fullPhone,
      gender: _selectedGender,
      password: _passwordController.text,
    );

    // Minta kode verifikasi. Kegagalan tidak disembunyikan lagi.
    final terkirim = await auth.sendOtp(fullPhone, niat: NiatOtp.register);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!terkirim) {
      _tampilkanPesan(
        auth.errorMessage ?? 'Kode verifikasi belum terkirim. Periksa koneksi lalu coba lagi.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: fullPhone,
          onSuccess: widget.onSuccess,
        ),
      ),
    );
  }

  void _tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: AppColors.statusCancelled,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

                // 5. Kata sandi + checklist hidup
                _buildPasswordField(),
                const SizedBox(height: 16),

                // 6. Ulangi kata sandi
                _buildPasswordConfirmField(),
                const SizedBox(height: 16),

                // 7. Form Input: Jenis Kelamin (Segmented Radio Pills)
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
                    hintText: '812-3456-7890',
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

  /// Kolom kata sandi dengan checklist hidup.
  ///
  /// Checklist muncul setelah kolom disentuh, dan tingginya dipesan lewat
  /// `AnimatedSize` supaya tata letak tidak melompat saat status berubah.
  /// Status dibedakan ikon + teks, bukan warna saja.
  Widget _buildPasswordField() {
    final pelanggaran = _pelanggaranKataSandi;
    final adaIsi = _passwordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Kata Sandi', isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onTap: () {
            if (!_passwordTouched) setState(() => _passwordTouched = true);
          },
          onChanged: (nilai) {
            if (!_passwordTouched && nilai.isNotEmpty) {
              setState(() => _passwordTouched = true);
            }
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
          decoration: _dekorasiKataSandi(
            hint: 'Buat kata sandi yang kuat',
            obscure: _obscurePassword,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Kata sandi wajib diisi.';
            final gagal = periksaKataSandi(
              val,
              namaLengkap: _nameController.text,
              nomorTelepon: _phoneController.text,
            );
            if (gagal.isEmpty) return null;
            return pesanKataSandiTidakValid(
              val,
              namaLengkap: _nameController.text,
              nomorTelepon: _phoneController.text,
            );
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: (_passwordTouched || adaIsi)
              ? _buildChecklistKataSandi(pelanggaran)
              : const SizedBox(height: 8, width: double.infinity),
        ),
      ],
    );
  }

  /// Kolom ulangi kata sandi dengan indikator kecocokan.
  Widget _buildPasswordConfirmField() {
    final terisi = _passwordConfirmController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Ulangi Kata Sandi', isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordConfirmController,
          obscureText: _obscureConfirm,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
          decoration: _dekorasiKataSandi(
            hint: 'Ketik ulang kata sandi',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Ulangi kata sandi wajib diisi.';
            if (val != _passwordController.text) return 'Kata sandi belum sama.';
            return null;
          },
        ),
        if (terisi) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _konfirmasiCocok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 14,
                color: _konfirmasiCocok ? AppColors.tealDark : AppColors.statusCancelled,
              ),
              const SizedBox(width: 6),
              Text(
                _konfirmasiCocok ? 'Kata sandi cocok' : 'Belum cocok',
                style: TextStyle(
                  fontSize: AppTypography.sizeTiny,
                  fontWeight: FontWeight.w600,
                  color: _konfirmasiCocok ? AppColors.tealDark : AppColors.statusCancelled,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Checklist aturan kata sandi.
  ///
  /// Hanya aturan yang diminta produk yang ditampilkan. Aturan teknis (batas
  /// byte, identitas, kata sandi umum) muncul lewat pesan galat supaya layar
  /// tidak penuh.
  Widget _buildChecklistKataSandi(Set<AturanKataSandi> pelanggaran) {
    final layarSempit = MediaQuery.sizeOf(context).width < 360;

    final item = aturanTampil.map((aturan) {
      final lulus = !pelanggaran.contains(aturan);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lulus ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 13,
            color: lulus ? AppColors.tealDark : AppColors.textMuted,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              labelAturan(aturan),
              style: TextStyle(
                fontSize: AppTypography.sizeTiny,
                height: 1.3,
                fontWeight: lulus ? FontWeight.w600 : FontWeight.w400,
                color: lulus ? AppColors.tealDark : AppColors.textMuted,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: layarSempit
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final baris in item)
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: baris),
              ],
            )
          : Wrap(spacing: 14, runSpacing: 4, children: item),
    );
  }

  /// Dekorasi kolom kata sandi, mengikuti gaya kolom lain di layar ini.
  InputDecoration _dekorasiKataSandi({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: AppTypography.sizeBodyLarge,
        fontWeight: FontWeight.normal,
        fontFamily: 'Inter',
      ),
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: AppColors.primaryTeal,
        size: 20,
      ),
      suffixIcon: IconButton(
        tooltip: obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
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
