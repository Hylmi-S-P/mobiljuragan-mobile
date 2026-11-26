import 'dart:async';
import '../core/network/api_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_section_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/legal_terms_sheet.dart';
import '../widgets/standard_bottom_sheet.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'order_status_screen.dart';
import '../theme/app_typography.dart';
import '../widgets/gambar_kendaraan.dart';
import '../data/remote/document_api_service.dart';
import '../core/util/berkas_unduhan.dart';
import '../core/util/pesan_galat.dart';
import '../core/util/format_tanggal.dart';

/// Layar peninjauan pesanan (Frame 06)
/// Menampilkan 3 kartu ringkasan pesanan dengan tombol Ubah dan rincian tarif resmi
/// Catatan: Verifikasi dokumen online ditiadakan, verifikasi fisik KTP & SIM A dilakukan di kantor
class OrderReviewScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const OrderReviewScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  late DocumentApiService _documentApiService;
  bool _serviceInitialized = false;
  late final TapGestureRecognizer _termsTapRecognizer;

  @override
  void initState() {
    super.initState();
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalTermsSheet.showSewaUnit(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_serviceInitialized) return;
    _serviceInitialized = true;
    ApiClient? sharedClient;
    try {
      sharedClient = Provider.of<ApiClient>(context, listen: false);
    } catch (_) {
      sharedClient = null;
    }
    _documentApiService = DocumentApiService(sharedClient);
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingController>();
    final vehicle = booking.selectedVehicle ?? widget.vehicle;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Tinjau Pesanan',
        stepSubtitle: 'Langkah 4 dari 4',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 16),
                    _buildUnifiedOrderSummaryCard(context, vehicle, booking),
                    const SizedBox(height: 14),
                    _buildCostBreakdownCard(booking),
                    /* Sewa dengan supir tidak meminta unggahan dokumen apa pun,
                       jadi kartu persiapan dokumen tidak ditampilkan. */
                    if (!booking.withDriver) ...[
                      const SizedBox(height: 14),
                      _buildDocumentPreparationCard(context, booking),
                    ],
                    const SizedBox(height: 16),
                    _buildAgreementCheckbox(booking),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildStickyCTA(context, booking, vehicle),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Periksa Rincian Pengajuan Sewa',
          style: TextStyle(
            fontSize: AppTypography.sizeHeading,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Pastikan pilihan armada, durasi tanggal, dan model rental telah sesuai.',
          style: TextStyle(
            fontSize: AppTypography.sizeBody,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  /// Ringkasan 1: Armada terpilih.
  ///
  /// Sengaja ringkas (nama + plat) sesuai permintaan revisi: kartu besar dengan
  /// foto kendaraan diulang dari layar sebelumnya dan tidak menambah informasi.
  Widget _buildUnifiedOrderSummaryCard(
    BuildContext context,
    VehicleModel vehicle,
    BookingController booking,
  ) {
    final startDate = booking.selectedDate;
    final endDate = startDate.add(Duration(days: booking.durationDays));
    final startStr = formatTanggalPanjang(startDate);
    final endStr = formatTanggalPanjang(endDate);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeaderRow(
            icon: Icons.directions_car_outlined,
            title: 'Armada',
            onEdit: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 64,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GambarKendaraan(
                    sumber: vehicle.imageUrl,
                    fit: BoxFit.contain,
                    lebarLogis: 64,
                    tinggiLogis: 52,
                    cadangan: const Icon(
                      Icons.directions_car,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeTitle,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.transmission} • ${vehicle.seatCapacity} • ${vehicle.bodyType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          _buildSectionHeaderRow(
            icon: Icons.calendar_today_outlined,
            title: 'Jadwal Rental',
            onEdit: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
          AppInfoRow(label: 'Mulai Sewa', value: '$startStr, ${booking.selectedTime}'),
          const SizedBox(height: 6),
          AppInfoRow(label: 'Durasi Pemakaian', value: '${booking.durationDays} Hari'),
          const SizedBox(height: 6),
          AppInfoRow(label: 'Selesai Sewa', value: '$endStr, ${booking.selectedTime}'),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          _buildSectionHeaderRow(
            icon: Icons.commute_outlined,
            title: booking.withDriver ? 'Penjemputan & Layanan' : 'Serah Terima & Layanan',
            onEdit: () {
              int count = 0;
              Navigator.of(context).popUntil((_) => count++ >= 2);
            },
          ),
          const SizedBox(height: 8),
          AppInfoRow(
            label: 'Layanan Pengemudi',
            value: booking.withDriver ? 'Dengan Sopir Lokal' : 'Lepas Kunci',
          ),
          const SizedBox(height: 6),
          AppInfoRow(
            label: booking.withDriver ? 'Titik Penjemputan' : 'Titik Serah Terima',
            value: booking.pickupLocation,
          ),
          if (booking.pickupAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              booking.pickupAddress,
              style: const TextStyle(
                fontSize: AppTypography.sizeBody,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeaderRow({
    required IconData icon,
    required String title,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Ubah',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  /// Rincian Biaya Estimasi Awal (Menunggu Rincian Tarif Final dari Admin)
  Widget _buildCostBreakdownCard(BookingController booking) {
    final unitSubtotal = booking.vehicleSubtotal;
    final driverSubtotal = booking.driverSubtotal;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rincian Biaya Sewa',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppInfoRow(
            label: 'Sewa Unit (${booking.durationDays} hari)',
            value: 'Rp ${_formatRupiah(unitSubtotal)}',
          ),
          if (booking.withDriver) ...[
            const SizedBox(height: 6),
            AppInfoRow(
              label: 'Layanan Sopir (${booking.durationDays} hari)',
              value: 'Rp ${_formatRupiah(driverSubtotal)}',
            ),
          ],
          const SizedBox(height: 6),
          const AppInfoRow(
            label: 'Biaya Layanan',
            value: 'Rp 0',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Text(
                  'Total perkiraan',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTitle,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Text(
                'Rp ${_formatRupiah(booking.totalCalculatedCost)}',
                style: const TextStyle(
                  fontSize: AppTypography.sizeHeading,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            booking.withDriver
                ? 'Biaya final (termasuk penyesuaian jam atau promo) dikonfirmasi admin sebelum Anda diminta membayar.'
                : 'Biaya final (termasuk penyesuaian atau promo dari admin) dikonfirmasi sebelum Anda diminta membayar.',
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCheckbox(BookingController booking) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: () => booking.setAgreementChecked(!booking.agreementChecked),
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: booking.agreementChecked,
                  activeColor: AppColors.primaryNavy,
                  onChanged: (val) {
                    if (val != null) booking.setAgreementChecked(val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(text: 'Saya menyetujui '),
                      TextSpan(
                        text: 'syarat dan ketentuan rental MobilJuragan',
                        recognizer: _termsTapRecognizer,
                        style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryNavy,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* Kartu persiapan dokumen lepas kunci (sumber kebenaran tunggal, tanpa
     duplikasi dengan kartu serah terima dan tanpa opsi tanda tangan fisik). */
  Widget _buildDocumentPreparationCard(BuildContext context, BookingController booking) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: AppColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dokumen yang Perlu Disiapkan',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ketiga berkas diunggah melalui tombol di halaman Status Pesanan dalam 2 jam setelah pengajuan dikirim. Lewat dari itu pesanan dibatalkan otomatis.',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          _buildDocumentRequirementRow('1. Foto e-KTP asli yang masih berlaku'),
          _buildDocumentRequirementRow('2. Foto SIM A aktif atas nama penyewa'),
          _buildDocumentRequirementRow('3. Surat Pernyataan Penyewa (cetak A4, isi, bubuhkan meterai, tanda tangani, lalu foto dan unggah di aplikasi)'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _unduhTemplateSurat(context),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Unduh Template Surat Pernyataan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryNavy,
              side: const BorderSide(color: AppColors.borderMedium),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRequirementRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppTypography.sizeBody,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unduhTemplateSurat(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final berkas = await _documentApiService.downloadStatementTemplatePdf();
      final path = await BerkasUnduhan.simpanDanBagikan(
        isi: berkas.isi,
        namaBerkas: berkas.namaBerkas,
        mime: berkas.mime,
        judul: 'Form Kesanggupan Penyewa',
        teks:
            'Cetak formulir ini di kertas A4, tanda tangani dengan meterai, lalu foto dan unggah kembali di aplikasi.',
      );

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 6),
          content: Text(
            'Formulir tersimpan. Cetak A4, tanda tangani, lalu foto dan unggah kembali.\n$path',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            PesanGalat.ramah('Formulir gagal diunduh', galat: e),
            style: const TextStyle(fontFamily: 'Inter'),
          ),
        ),
      );
    }
  }

  Widget _buildStickyCTA(
    BuildContext context,
    BookingController booking,
    VehicleModel vehicle,
  ) {
    final auth = context.watch<AuthController>();
    final isEnabled = booking.agreementChecked;
    final label = _labelBawahKirim(booking);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppTypography.sizeBody,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
              child: ElevatedButton(
                onPressed: isEnabled
                    ? () {
                        if (!auth.isLoggedIn) {
                          _showLoginRequiredSheet(context, auth, booking, vehicle);
                          return;
                        }
                        _processOrderSubmission(context, booking, vehicle);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: AppColors.textWhite,
                  disabledBackgroundColor: AppColors.borderSubtle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kirim Pengajuan Sewa',
                  style: AppTypography.sectionTitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* Label di atas tombol kirim menjawab satu pertanyaan saja: kalau tombol ini
     masih mati, apa yang kurang? Karena itu isinya bukan tenggat dokumen —
     pelanggan mode Dengan Sopir tidak mengunggah berkas apa pun — melainkan
     pemicu yang sebenarnya, yaitu centang persetujuan di atas tombol. Tenggat
     dokumen baru disebut setelah persetujuan dicentang, dan hanya untuk mode
     lepas kunci yang memang punya unggahan. */
  String? _labelBawahKirim(BookingController booking) {
    if (!booking.agreementChecked) {
      return 'Centang persetujuan sewa di atas untuk mengaktifkan tombol ini.';
    }
    if (booking.withDriver) return null;
    return _labelTenggatKirim();
  }

  /* Tombol kirim menyebut jam pasti, bukan "2 jam" yang harus dihitung sendiri
     oleh pelanggan. Jam batal mengikuti tenggat yang nanti dipakai server. */
  String _labelTenggatKirim() {
    final batas = DateTime.now().add(const Duration(hours: 2));
    final jam = batas.hour.toString().padLeft(2, '0');
    final menit = batas.minute.toString().padLeft(2, '0');
    return 'Dokumen dikunci 2 jam setelah pengajuan (sekitar pukul $jam.$menit WIT)';
  }

  void _processOrderSubmission(
    BuildContext context,
    BookingController booking,
    VehicleModel vehicle,
  ) async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      _showLoginRequiredSheet(context, auth, booking, vehicle);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );

    try {
      final newBooking = await booking.submitBooking();
      if (!context.mounted) return;
      unawaited(context.read<VehicleController>().refreshCatalog(force: true));
      Navigator.of(context).pop(); // Tutup dialog loading

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(
            booking: newBooking,
            fromOrderSubmission: true,
          ),
        ),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryNavy,
          content: Text(
            'Pengajuan sewa ${vehicle.name} (${newBooking.id}) berhasil dikirim! Menunggu konfirmasi rincian tarif final oleh admin operasional...',
            style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Tutup dialog loading jika gagal
      /* Galat mentah tidak lagi ditempelkan ke SnackBar. Teks exception bisa
         memuat nama kelas, jalur berkas, atau potongan respons server; bagi
         pengguna itu tidak membantu, dan menambah kode referensi membuat
         laporan tetap bisa ditelusuri. */
      final errorMsg = e is ApiException
          ? PesanGalat.dariServer(e.message)
          : PesanGalat.ramah('Pengajuan sewa gagal dikirim', galat: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusCancelled,
          content: Text(
            errorMsg,
            style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
          ),
        ),
      );
    }
  }

  void _showLoginRequiredSheet(
    BuildContext context,
    AuthController auth,
    BookingController booking,
    VehicleModel vehicle,
  ) {
    StandardBottomSheet.show(
      context: context,
      title: 'Masuk atau Buat Akun',
      subtitle: 'Diperlukan sebelum konfirmasi pengajuan sewa',
      icon: Icons.account_circle_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: const Text(
              'Sesuai ketentuan rental mobil di Merauke, pemesanan armada harus terhubung ke identitas penyewa agar admin dapat mengonfirmasi ketersediaan unit dan mengirimkan notifikasi tarif resmi.',
              style: TextStyle(
                fontSize: AppTypography.sizeBody,
                height: 1.45,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(
                      onSuccess: () {
                        Navigator.pop(context);
                        _processOrderSubmission(context, booking, vehicle);
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text(
                'Masuk via WhatsApp & OTP',
                style: AppTypography.cardTitle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(
                      onSuccess: () {
                        Navigator.pop(context);
                        _processOrderSubmission(context, booking, vehicle);
                      },
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
              ),
              child: const Text(
                'Daftar Akun Baru',
                style: TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
