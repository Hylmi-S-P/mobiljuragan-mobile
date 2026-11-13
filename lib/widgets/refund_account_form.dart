import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Isi rekening tujuan pengembalian dana yang sedang diisi pelanggan.
class RefundAccountDraft {
  const RefundAccountDraft({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.atasNamaSendiri = true,
    this.hubungan = 'Keluarga',
  });

  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final bool atasNamaSendiri;
  final String hubungan;

  bool get lengkap =>
      bankName.trim().isNotEmpty &&
      accountNumber.trim().isNotEmpty &&
      accountHolderName.trim().isNotEmpty;
}

/// Memeriksa isian rekening sebelum dikirim ke server.
///
/// Aturannya sama dengan validasi backend (`refundAccountSchema`): nama bank
/// 2–60 karakter, nomor rekening 6–30 angka tanpa spasi, nama pemilik 2–120.
String? validasiRefundAccount(RefundAccountDraft draft) {
  final bank = draft.bankName.trim();
  final nomor = draft.accountNumber.trim();
  final pemilik = draft.accountHolderName.trim();

  if (bank.isEmpty) return 'Pilih bank tujuan pengembalian dana.';
  if (bank.length < 2) return 'Nama bank terlalu pendek.';
  if (!RegExp(r'^\d{6,30}$').hasMatch(nomor)) {
    return 'Nomor rekening harus 6–30 angka tanpa spasi.';
  }
  if (pemilik.length < 2) return 'Nama pemilik rekening wajib diisi.';
  if (pemilik.length > 120) return 'Nama pemilik rekening maksimal 120 karakter.';
  return null;
}

/// Form rekening tujuan pengembalian dana.
///
/// Dipakai dua tempat: saat pelanggan membatalkan pesanan yang sudah dibayar,
/// dan saat pelanggan mengklaim pengembalian dana setelah pesanan terlanjur
/// batal. Satu widget supaya isian dan aturannya tidak berbeda di kedua layar.
class RefundAccountForm extends StatefulWidget {
  const RefundAccountForm({
    super.key,
    this.initialHolderName = '',
    this.initialBankName,
    this.initialAccountNumber,
    this.initialHolderNameValue,
    required this.onChanged,
  });

  /// Nama pemilik yang diisikan lebih dulu (biasanya nama akun pelanggan).
  final String initialHolderName;

  /// Nilai awal saat pelanggan mengganti rekening yang sudah tersimpan.
  final String? initialBankName;
  final String? initialAccountNumber;
  final String? initialHolderNameValue;

  final ValueChanged<RefundAccountDraft> onChanged;

  @override
  State<RefundAccountForm> createState() => _RefundAccountFormState();
}

class _RefundAccountFormState extends State<RefundAccountForm> {
  static const List<String> _daftarBank = [
    'Bank BRI',
    'Bank BCA',
    'Bank BNI',
    'Bank Mandiri',
    'Bank Papua',
    'Bank BTN',
    'Bank Syariah Indonesia',
    'CIMB Niaga',
    'Bank Permata',
    'Bank Danamon',
  ];

  late final TextEditingController _bankLainController;
  late final TextEditingController _nomorController;
  late final TextEditingController _pemilikController;

  String? _bankTerpilih;
  bool _atasNamaSendiri = true;
  String _hubungan = 'Keluarga';

  @override
  void initState() {
    super.initState();

    final bankAwal = widget.initialBankName?.trim();
    if (bankAwal != null && bankAwal.isNotEmpty) {
      _bankTerpilih = _daftarBank.contains(bankAwal) ? bankAwal : 'Bank lain';
    }

    _bankLainController = TextEditingController(
      text: _bankTerpilih == 'Bank lain' ? (bankAwal ?? '') : '',
    );
    _nomorController = TextEditingController(
      text: widget.initialAccountNumber?.trim() ?? '',
    );
    _pemilikController = TextEditingController(
      text: (widget.initialHolderNameValue?.trim().isNotEmpty ?? false)
          ? widget.initialHolderNameValue!.trim()
          : widget.initialHolderName.trim(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _bankLainController.dispose();
    _nomorController.dispose();
    _pemilikController.dispose();
    super.dispose();
  }

  String get _bankFinal => _bankTerpilih == 'Bank lain'
      ? _bankLainController.text.trim()
      : (_bankTerpilih ?? '');

  void _emit() {
    if (!mounted) return;
    widget.onChanged(
      RefundAccountDraft(
        bankName: _bankFinal,
        accountNumber: _nomorController.text.trim(),
        accountHolderName: _pemilikController.text.trim(),
        atasNamaSendiri: _atasNamaSendiri,
        hubungan: _hubungan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _bankTerpilih,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Nama Bank',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: [
            ..._daftarBank.map(
              (bank) => DropdownMenuItem(value: bank, child: Text(bank)),
            ),
            const DropdownMenuItem(value: 'Bank lain', child: Text('Bank lain')),
          ],
          onChanged: (value) {
            setState(() => _bankTerpilih = value);
            _emit();
          },
        ),
        if (_bankTerpilih == 'Bank lain') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _bankLainController,
            maxLength: 60,
            onChanged: (_) => _emit(),
            decoration: InputDecoration(
              labelText: 'Nama bank / e-wallet',
              hintText: 'Contoh: Bank Sulselbar',
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextFormField(
          controller: _nomorController,
          keyboardType: TextInputType.number,
          maxLength: 30,
          onChanged: (_) => _emit(),
          decoration: InputDecoration(
            labelText: 'Nomor Rekening',
            hintText: '6–30 angka, tanpa spasi atau tanda hubung',
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _pemilikController,
          maxLength: 120,
          onChanged: (_) => _emit(),
          decoration: InputDecoration(
            labelText: 'Nama Pemilik Rekening',
            hintText: 'Sesuai buku tabungan / identitas',
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          value: _atasNamaSendiri,
          onChanged: (value) {
            setState(() => _atasNamaSendiri = value ?? true);
            _emit();
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          title: const Text(
            'Rekening atas nama saya sendiri',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        if (!_atasNamaSendiri) ...[
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _hubungan,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Hubungan dengan pemilik rekening',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: const [
              DropdownMenuItem(value: 'Keluarga', child: Text('Keluarga')),
              DropdownMenuItem(value: 'Rekan kerja', child: Text('Rekan kerja')),
              DropdownMenuItem(value: 'Pihak lain', child: Text('Pihak lain')),
            ],
            onChanged: (value) {
              setState(() => _hubungan = value ?? 'Keluarga');
              _emit();
            },
          ),
        ],
      ],
    );
  }
}
