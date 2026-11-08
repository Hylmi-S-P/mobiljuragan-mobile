import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/validators/password_policy.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Lembar untuk membuat atau mengganti kata sandi dari halaman profil.
///
/// Akun lama (belum punya kata sandi) tidak perlu mengisi kata sandi saat ini.
/// Setelah berhasil, semua perangkat lain dikeluarkan oleh server.
class UbahKataSandiSheet extends StatefulWidget {
  final bool sudahPunyaKataSandi;

  const UbahKataSandiSheet({super.key, required this.sudahPunyaKataSandi});

  /// Menampilkan lembar; mengembalikan true bila kata sandi berhasil disimpan.
  static Future<bool> tampilkan(
    BuildContext context, {
    required bool sudahPunyaKataSandi,
  }) async {
    final hasil = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: UbahKataSandiSheet(sudahPunyaKataSandi: sudahPunyaKataSandi),
      ),
    );
    return hasil ?? false;
  }

  @override
  State<UbahKataSandiSheet> createState() => _UbahKataSandiSheetState();
}

class _UbahKataSandiSheetState extends State<UbahKataSandiSheet> {
  final _formKey = GlobalKey<FormState>();
  final _lamaController = TextEditingController();
  final _baruController = TextEditingController();
  final _ulangiController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _baruTersentuh = false;

  @override
  void initState() {
    super.initState();
    _baruController.addListener(_refresh);
    _ulangiController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _baruController.removeListener(_refresh);
    _ulangiController.removeListener(_refresh);
    _lamaController.dispose();
    _baruController.dispose();
    _ulangiController.dispose();
    super.dispose();
  }

  bool get _cocok =>
      _ulangiController.text.isNotEmpty && _baruController.text == _ulangiController.text;

  Set<AturanKataSandi> get _gagal => periksaKataSandi(_baruController.text);

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gagal.isNotEmpty) {
      setState(() => _baruTersentuh = true);
      _pesan('Kata sandi belum memenuhi semua syarat.');
      return;
    }
    if (!_cocok) {
      _pesan('Ulangi kata sandi dengan isian yang sama.');
      return;
    }

    final auth = context.read<AuthController>();
    setState(() => _isLoading = true);

    final galat = await auth.ubahKataSandi(
      kataSandiBaru: _baruController.text,
      kataSandiSaatIni: widget.sudahPunyaKataSandi ? _lamaController.text : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (galat != null) {
      _pesan(galat);
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        backgroundColor: AppColors.statusCancelled,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const _gayaIsi = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'Inter',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: 18),
            Text(
              widget.sudahPunyaKataSandi ? 'Ganti kata sandi' : 'Buat kata sandi',
              style: const TextStyle(
                fontSize: AppTypography.sizeHeading,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.sudahPunyaKataSandi
                  ? 'Setelah diganti, semua perangkat lain otomatis dikeluarkan.'
                  : 'Dengan kata sandi, Anda bisa masuk tanpa menunggu kode WhatsApp.',
              style: const TextStyle(
                fontSize: AppTypography.sizeBody,
                height: 1.45,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 18),
            if (widget.sudahPunyaKataSandi) ...[
              _label('Kata sandi saat ini'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lamaController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                style: _gayaIsi,
                decoration: _dekorasi('Kata sandi saat ini'),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Kata sandi saat ini wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],
            _label('Kata sandi baru'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _baruController,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              onTap: () {
                if (!_baruTersentuh) setState(() => _baruTersentuh = true);
              },
              style: _gayaIsi,
              decoration: _dekorasi(
                'Buat kata sandi baru',
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Kata sandi baru wajib diisi.';
                return null;
              },
            ),
            if (_baruTersentuh) _checklist(),
            const SizedBox(height: 14),
            _label('Ulangi kata sandi baru'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ulangiController,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              style: _gayaIsi,
              decoration: _dekorasi('Ketik ulang kata sandi baru'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Ulangi kata sandi wajib diisi.';
                if (val != _baruController.text) return 'Kata sandi belum sama.';
                return null;
              },
            ),
            if (_ulangiController.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    _cocok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 14,
                    color: _cocok ? AppColors.tealDark : AppColors.statusCancelled,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _cocok ? 'Kata sandi cocok' : 'Belum cocok',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      fontWeight: FontWeight.w600,
                      color: _cocok ? AppColors.tealDark : AppColors.statusCancelled,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderMedium),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpan,
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
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String teks) => Text(
        teks,
        style: const TextStyle(
          fontSize: AppTypography.sizeBody,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
      );

  InputDecoration _dekorasi(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: AppTypography.sizeBodyLarge,
          fontWeight: FontWeight.normal,
          fontFamily: 'Inter',
        ),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppColors.primaryTeal, size: 20),
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

  Widget _checklist() {
    final gagal = _gagal;
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
