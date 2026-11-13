import 'dart:async';
import '../core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/merauke_location_map_picker.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'order_status_screen.dart';
import '../theme/app_typography.dart';
import '../widgets/gambar_kendaraan.dart';
import '../data/remote/document_api_service.dart';
import '../core/util/berkas_unduhan.dart';

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
  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 16),
                    _buildVehicleSummaryCard(context, vehicle),
                    const SizedBox(height: 14),
                    _buildScheduleSummaryCard(context, booking),
                    const SizedBox(height: 14),
                    _buildRentalOptionsSummaryCard(context, booking),
                    const SizedBox(height: 14),
                    _buildCostBreakdownCard(booking),
                    const SizedBox(height: 14),
                    _buildDocumentPreparationCard(context, booking),
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
  Widget _buildVehicleSummaryCard(BuildContext context, VehicleModel vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Armada',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // Kembali ke layar pemilihan kendaraan
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Ubah',
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
          ),
          const SizedBox(height: 12),
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
                    cadangan: const Icon(
                      Icons.directions_car,
                      color: AppColors.textSecondary,
                    )),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
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
        ],
      ),
    );
  }

  /// Kartu Ringkasan 2: Jadwal Rental
  Widget _buildScheduleSummaryCard(BuildContext context, BookingController booking) {
    final startDate = booking.selectedDate;
    final endDate = startDate.add(Duration(days: booking.durationDays));

    final startStr = '${startDate.day} ${_monthNames[startDate.month - 1]} ${startDate.year}';
    final endStr = '${endDate.day} ${_monthNames[endDate.month - 1]} ${endDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Jadwal Rental',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // Kembali ke pengaturan jadwal sewa (Langkah 3)
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Ubah',
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
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Mulai Sewa', '$startStr, ${booking.selectedTime}'),
          const SizedBox(height: 6),
          _buildInfoRow('Durasi Pemakaian', '${booking.durationDays} Hari'),
          const SizedBox(height: 6),
          _buildInfoRow('Selesai Sewa', '$endStr, ${booking.selectedTime}'),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Ketentuan Jam',
            booking.withDriver ? 'Layanan sopir 12 jam/hari' : 'Penggunaan mandiri 24 jam/hari',
          ),
        ],
      ),
    );
  }

  /// Kartu Ringkasan 3: Detail Penjemputan & Layanan dengan Mini Map Preview dan Catatan Layanan Terpadu
  Widget _buildRentalOptionsSummaryCard(BuildContext context, BookingController booking) {
    final title = booking.withDriver
        ? 'Detail Penjemputan & Layanan'
        : 'Detail Serah Terima & Layanan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.commute_outlined, size: 18, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Ubah',
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
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Layanan Pengemudi',
            booking.withDriver ? 'Dengan Sopir Lokal' : 'Lepas Kunci',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            booking.withDriver ? 'Titik Penjemputan' : 'Titik Serah Terima',
            booking.withDriver
                ? booking.pickupLocation
                : 'Kantor MobilJuragan',
          ),
          if (!booking.withDriver) ...[
            const SizedBox(height: 2),
            const Text(
              'Jl. Pendidikan, Mandala, Kec. Merauke, Kabupaten Merauke, Papua Selatan 99614',
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
          const SizedBox(height: 12),
          /* Lepas kunci selalu diambil di kantor, jadi peta tidak perlu
             ditampilkan — yang dibutuhkan pelanggan hanya alamatnya. Peta tetap
             muncul untuk mode dengan sopir karena titik jemputnya bisa berubah. */
          if (booking.withDriver)
            MeraukeLocationMapPicker(
              selectedLocationName: booking.pickupLocation,
              selectedCoordinates: (booking.pickupLatitude != null && booking.pickupLongitude != null)
                  ? LatLng(booking.pickupLatitude!, booking.pickupLongitude!)
                  : null,
              isMiniPreview: true,
              showOverlayBanner: false,
              isWithDriver: booking.withDriver,
            ),
          const SizedBox(height: 12),
          // Inline Notice Box Netral
          _buildInlineServiceNotice(booking),
        ],
      ),
    );
  }

  /// Catatan Ketentuan Layanan / Verifikasi Dokumen Terpadu (Netral)
  Widget _buildInlineServiceNotice(BookingController booking) {
    final isDriver = booking.withDriver;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDriver ? Icons.airline_seat_recline_normal : Icons.verified_user_outlined,
            size: 18,
            color: AppColors.primaryNavy,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDriver
                      ? 'Sopir Resmi MobilJuragan'
                      : 'Verifikasi Dokumen Fisik',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isDriver
                      ? 'Armada dikemudikan staf profesional MobilJuragan. Bebas repot berkendara dan tanpa syarat SIM A pemesan.'
                      : 'Form Kesanggupan penyewa dapat diunduh pada halaman status pesanan, atau ditandatangani langsung secara fisik saat serah terima unit di Merauke.',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: AppColors.textSecondary,
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

  /// Rincian Biaya Estimasi Awal (Menunggu Rincian Tarif Final dari Admin)
  Widget _buildCostBreakdownCard(BookingController booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primaryTeal),
              SizedBox(width: 8),
              Text(
                'Rincian Biaya Sewa',
                style: TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          /* Satu angka saja. Rincian per komponen (sewa, sopir, penyesuaian)
             baru punya arti setelah admin menetapkan tarif; menampilkannya di
             tahap pengajuan membuat pelanggan mengira itu tagihan final. */
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Total perkiraan',
                style: TextStyle(
                  fontSize: AppTypography.sizeTitle,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'Rp ${_formatRupiah(booking.totalCalculatedCost)}',
                style: const TextStyle(
                  fontSize: AppTypography.sizeHeading,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.withDriver
                        ? 'Biaya final (termasuk rute luar kota, durasi sewa >12 jam/hari, atau potongan promo) akan dikonfirmasi admin setelah pengajuan dikirim.'
                        : 'Biaya final (termasuk penyesuaian rute atau potongan promo) akan dikonfirmasi admin setelah pengajuan dikirim.',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAgreementCheckbox(BookingController booking) {
    final isDriver = booking.withDriver;
    final agreementText = isDriver
        ? 'Saya menyetujui syarat & ketentuan rental MobilJuragan serta bersedia mematuhi tata tertib perjalanan bersama sopir resmi.'
        : 'Saya menyatakan bebas pengaruh alkohol/narkoba serta bersedia melengkapi unggahan e-KTP, SIM A, dan Surat Pernyataan setelah pesanan diajukan.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: InkWell(
        onTap: () => booking.setAgreementChecked(!booking.agreementChecked),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Text(
                agreementText,
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* Kartu persiapan dokumen.

     Dulu pelanggan baru tahu ada surat pernyataan setelah pesanan dikirim, di
     layar status, saat jamnya sudah berjalan. Kartu ini memindahkan
     informasinya ke depan: apa yang perlu disiapkan, dan template suratnya bisa
     diunduh sebelum mengirim pengajuan. */
  Widget _buildDocumentPreparationCard(BuildContext context, BookingController booking) {
    final butuhDokumen = !booking.withDriver;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 18, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              const Expanded(
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
          Text(
            butuhDokumen
                ? 'Setelah pengajuan dikirim, Anda punya 2 jam untuk mengunggah ketiga berkas ini. '
                    'Lewat dari itu pesanan dibatalkan otomatis.'
                : 'Setelah pengajuan dikirim, Anda punya 2 jam untuk melengkapi berkas yang diminta. '
                    'Lewat dari itu pesanan dibatalkan otomatis.',
            style: const TextStyle(
              fontSize: AppTypography.sizeCaption,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _buildDocumentRequirementRow('Foto e-KTP asli', wajib: true),
          _buildDocumentRequirementRow(
            'Foto SIM A aktif',
            wajib: butuhDokumen,
            catatan: butuhDokumen ? null : 'Hanya untuk sewa lepas kunci',
          ),
          _buildDocumentRequirementRow(
            'Surat pernyataan bertanda tangan',
            wajib: butuhDokumen,
            catatan: butuhDokumen ? null : 'Hanya untuk sewa lepas kunci',
          ),
          if (butuhDokumen) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _unduhTemplateSurat(context),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Unduh Template Surat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: AppColors.borderMedium),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cetak di kertas A4, isi, tanda tangani dengan meterai, lalu foto dan unggah di aplikasi.',
              style: TextStyle(
                fontSize: AppTypography.sizeTiny,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentRequirementRow(String label, {required bool wajib, String? catatan}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            wajib ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 14,
            color: wajib ? AppColors.primaryTeal : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              catatan == null ? label : '$label — $catatan',
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                color: wajib ? AppColors.textPrimary : AppColors.textSecondary,
                fontFamily: 'Inter',
                height: 1.35,
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
      final berkas = await DocumentApiService().downloadStatementTemplatePdf();
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
            'Gagal mengunduh formulir: ${e.toString().replaceAll('ApiException: ', '')}',
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _labelTenggatKirim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppTypography.sizeTiny,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            // Tinggi ikut skala teks sistem agar label tidak terpotong.
            height: (48 * MediaQuery.textScalerOf(context).scale(1)).clamp(48, 96),
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
                  borderRadius: BorderRadius.circular(12),
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
    );
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
      final errorMsg = e is ApiException ? e.message : 'Gagal mengirimkan pengajuan sewa: $e';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_circle_outlined,
                      color: AppColors.primaryTeal,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masuk atau Buat Akun',
                          style: TextStyle(
                            fontSize: AppTypography.sizeAmount,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Diperlukan sebelum konfirmasi pengajuan sewa',
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
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
              SizedBox(
                width: double.infinity,
                height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(modalCtx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          onSuccess: () {
                            Navigator.pop(context); // Pop dari LoginScreen
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: (44 * MediaQuery.textScalerOf(context).scale(1)).clamp(44, 88),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(modalCtx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(
                          onSuccess: () {
                            Navigator.pop(context); // Pop dari RegisterScreen
                            _processOrderSubmission(context, booking, vehicle);
                          },
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Daftar Akun Baru',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kedua sisi sama-sama fleksibel. Sebelumnya hanya nilai yang
        // Expanded, sehingga label panjang mendorong isi baris melebihi
        // lebar kartu saat ukuran teks sistem diperbesar.
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
