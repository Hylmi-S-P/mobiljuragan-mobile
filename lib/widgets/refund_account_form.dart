import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../core/constants/api_constants.dart';
import '../models/booking_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'standard_bottom_sheet.dart';

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

/// Baris ringkas rekening tujuan pengembalian dana pada kartu pesanan batal.
Widget kotakRekeningRefund(BookingModel booking) {
  final bank = booking.cancellationBank?.trim() ?? '';
  final nomor = booking.cancellationAccountNumber?.trim() ?? '';
  final pemilik = booking.cancellationAccountName?.trim() ?? '';
  final adaRekening = bank.isNotEmpty && nomor.isNotEmpty;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          adaRekening
              ? 'Rekening Tujuan: $bank • $nomor'
              : 'Rekening tujuan belum diisi',
          style: const TextStyle(
            fontSize: AppTypography.sizeCaption,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          adaRekening
              ? 'Atas Nama: ${pemilik.isEmpty ? "-" : pemilik}'
              : (!booking.danaTerverifikasi
                    ? 'Rekening dapat diisi setelah kantor memverifikasi dana masuk.'
                    : 'Isi nomor rekening supaya dana bisa ditransfer kantor.'),
          style: const TextStyle(
            fontSize: AppTypography.sizeCaption,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    ),
  );
}

/// Baris keadaan pengembalian dana beserta tombol klaim/ubah rekening atau
/// lihat bukti transfer jika dana sudah ditransfer kantor.
///
/// Rekening dikunci setelah kantor mulai memproses (`DIPROSES`) supaya staf
/// tidak mentransfer ke rekening yang berubah di tengah jalan, serta ditahan
/// sebelum `danaTerverifikasi` bernilai benar.
Widget barisStatusRefund(BuildContext context, BookingModel booking) {
  final status = booking.refundStatus?.toUpperCase();
  final adaRekening = (booking.cancellationBank?.trim().isNotEmpty ?? false) &&
      (booking.cancellationAccountNumber?.trim().isNotEmpty ?? false);
  final adaBuktiTransfer = booking.refundProofUrl?.trim().isNotEmpty ?? false;

  late final String teks;
  late final Color warna;
  late final IconData ikon;
  String? labelTombol;
  VoidCallback? aksiTombol;

  if (status == 'SELESAI') {
    teks = 'Dana sudah ditransfer kantor.';
    warna = AppColors.statusSuccessFg;
    ikon = Icons.check_circle_outline_rounded;
    if (adaBuktiTransfer) {
      labelTombol = 'Lihat Bukti Transfer';
      aksiTombol = () => tampilkanSheetBuktiRefund(context, booking);
    }
  } else if (status == 'DIPROSES') {
    teks = 'Sedang diproses staf kantor. Rekening tidak bisa diubah lagi.';
    warna = AppColors.statusInfoFg;
    ikon = Icons.schedule;
  } else if (!booking.danaTerverifikasi) {
    teks =
        'Menunggu verifikasi dana masuk sebelum pengembalian dana diproses kantor.';
    warna = AppColors.statusWarningFg;
    ikon = Icons.hourglass_top_rounded;
  } else if (adaRekening) {
    teks = booking.paymentStatus == 'PENDING_VERIFICATION'
        ? 'Menunggu verifikasi dana masuk sebelum pengembalian dana diproses kantor.'
        : 'Menunggu transfer dari kantor.';
    warna = AppColors.statusInfoFg;
    ikon = Icons.schedule;
    labelTombol = 'Ubah Rekening';
    aksiTombol = () => tampilkanSheetRekeningRefund(context, booking);
  } else {
    /* Pengingat: pengembalian dana yang rekeningnya kosong lebih dari tiga hari
       tidak akan pernah bisa ditransfer kantor, jadi umurnya disebutkan. */
    final hari = booking.cancelledAt == null
        ? 0
        : DateTime.now().difference(booking.cancelledAt!).inDays;
    teks = hari >= 3
        ? 'Rekening belum diisi sejak $hari hari lalu. Dana tidak bisa ditransfer sebelum rekening lengkap.'
        : 'Lengkapi rekening supaya dana bisa dikembalikan.';
    warna = AppColors.statusWarningFg;
    ikon = Icons.error_outline_rounded;
    labelTombol = 'Klaim Pengembalian Dana';
    aksiTombol = () => tampilkanSheetRekeningRefund(context, booking);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(ikon, size: 15, color: warna),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              teks,
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w500,
                color: warna,
                height: 1.35,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
      if (labelTombol != null && aksiTombol != null) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: aksiTombol,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: status == 'SELESAI'
                  ? AppColors.primaryNavy
                  : AppColors.primaryTeal,
              side: BorderSide(
                color: status == 'SELESAI'
                    ? AppColors.borderMedium
                    : AppColors.primaryTeal,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(labelTombol, style: AppTypography.captionBold),
          ),
        ),
      ],
    ],
  );
}

/// Modal preview bukti transfer pengembalian dana dari admin kantor.
void tampilkanSheetBuktiRefund(BuildContext context, BookingModel booking) {
  final rawUrl = booking.refundProofUrl?.trim() ?? '';
  if (rawUrl.isEmpty) return;
  final fullUrl = ApiConstants.alamatMedia(rawUrl);

  StandardBottomSheet.show<void>(
    context: context,
    title: 'Bukti Transfer Pengembalian Dana',
    subtitle: 'Kode Reservasi: ${booking.id}',
    icon: Icons.receipt_long_outlined,
    child: Builder(
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 360),
                color: AppColors.surfaceLight,
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bukti transfer belum dapat dimuat. Tarik halaman ke bawah untuk menyegarkan tautan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tutup', style: AppTypography.bodyStrong),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Form klaim/ubah rekening pengembalian dana untuk pesanan yang sudah batal.
void tampilkanSheetRekeningRefund(BuildContext context, BookingModel booking) {
  final namaAkun = context.read<AuthController>().currentUser?.name.trim() ?? '';
  RefundAccountDraft draft = RefundAccountDraft(
    bankName: booking.cancellationBank ?? '',
    accountNumber: booking.cancellationAccountNumber ?? '',
    accountHolderName: booking.cancellationAccountName ?? '',
  );
  bool sedangKirim = false;

  StandardBottomSheet.show<void>(
    context: context,
    title: 'Rekening Pengembalian Dana',
    subtitle: 'Kode Reservasi: ${booking.id}',
    icon: Icons.account_balance_outlined,
    child: StatefulBuilder(
      builder: (sheetContext, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RefundAccountForm(
              initialHolderName: namaAkun,
              initialBankName: booking.cancellationBank,
              initialAccountNumber: booking.cancellationAccountNumber,
              initialHolderNameValue: booking.cancellationAccountName,
              onChanged: (nilai) {
                setModalState(() => draft = nilai);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: sedangKirim
                        ? null
                        : () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal', style: AppTypography.bodyStrong),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: sedangKirim
                        ? null
                        : () async {
                            final galat = validasiRefundAccount(draft);
                            if (galat != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(galat),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }

                            setModalState(() => sedangKirim = true);
                            final berhasil = await context
                                .read<BookingController>()
                                .claimRefundAccount(
                                  bookingId: booking.id,
                                  bankName: draft.bankName,
                                  accountNumber: draft.accountNumber,
                                  accountHolderName: draft.accountHolderName,
                                );
                            if (!sheetContext.mounted) return;
                            setModalState(() => sedangKirim = false);

                            if (!berhasil) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Rekening gagal disimpan. Periksa koneksi, atau pengembalian dana ini sudah ditutup kantor.',
                                  ),
                                  backgroundColor: Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Rekening pengembalian dana tersimpan.',
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      sedangKirim ? 'Menyimpan...' : 'Simpan Rekening',
                      style: AppTypography.bodyBold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}