import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/merauke_location_map_picker.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'order_status_screen.dart';
import 'rental_options_screen.dart';
import '../theme/app_typography.dart';

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
      body: Column(
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
                  const SizedBox(height: 16),
                  _buildPhysicalVerificationNotice(booking),
                  const SizedBox(height: 16),
                  _buildCostBreakdownCard(booking),
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
          'Pastikan pilihan armada, durasi tanggal, dan moda rental telah sesuai.',
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

  /// Kartu Ringkasan 1: Armada Kendaraan Terpilih
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car_outlined, size: 18, color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Armada Kendaraan',
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
              ),
              InkWell(
                onTap: () {
                  // Kembali ke layar pemilihan kendaraan
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  child: Image.asset(
                    vehicle.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.directions_car,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
                      'Plat: ${vehicle.plateNumber}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.transmission} • ${vehicle.seatCapacity} • ${vehicle.bodyType}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryNavy,
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Jadwal Rental',
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
              ),
              InkWell(
                onTap: () {
                  // Kembali ke pengaturan jadwal sewa (Langkah 3)
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  /// Kartu Ringkasan 3: Moda Rental & Lokasi Penjemputan dengan Mini Map Preview
  Widget _buildRentalOptionsSummaryCard(BuildContext context, BookingController booking) {
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
              // Flexible di dalam Row bersarang ini membuat judul panjang
              // membungkus ke baris berikutnya alih-alih meluber ke kanan.
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.commute_outlined, size: 18, color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Moda & Lokasi Serah Terima',
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
              ),
              InkWell(
                onTap: () {
                  final vehicle = booking.selectedVehicle ?? widget.vehicle;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RentalOptionsScreen(vehicle: vehicle),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            booking.withDriver ? 'Dengan Sopir Lokal' : 'Lepas Kunci (Self-Drive)',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            booking.withDriver ? 'Titik Penjemputan' : 'Titik Serah Terima',
            booking.pickupLocation,
          ),
          const SizedBox(height: 12),
          // Cuplikan Mini Map Preview
          MeraukeLocationMapPicker(
            selectedLocationName: booking.pickupLocation,
            selectedCoordinates: (booking.pickupLatitude != null && booking.pickupLongitude != null)
                ? LatLng(booking.pickupLatitude!, booking.pickupLongitude!)
                : null,
            isMiniPreview: true,
            isWithDriver: booking.withDriver,
          ),
        ],
      ),
    );
  }

  /// Banner Pemberitahuan Ketentuan Dokumen / Staf Sopir (Adaptif)
  Widget _buildPhysicalVerificationNotice(BookingController booking) {
    final isDriver = booking.withDriver;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDriver ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDriver ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDriver ? Icons.airline_seat_recline_normal : Icons.verified_user_outlined,
            size: 20,
            color: isDriver ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDriver
                      ? 'Layanan Sopir Karyawan Tetap & Bebas Deposit'
                      : 'Verifikasi Fisik Dokumen di Kantor / Lapangan',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w700,
                    color: isDriver ? const Color(0xFF166534) : const Color(0xFF1D4ED8),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isDriver
                      ? 'Armada dikemudikan langsung oleh staf pengemudi resmi MobilJuragan. Bebas uang deposit jaminan sewa dan tidak memerlukan SIM A dari penyewa.'
                      : 'Sesuai ketentuan resmi MobilJuragan Merauke, verifikasi fisik KTP asli dan SIM A dilakukan langsung oleh staf lapangan saat serah terima unit kendaraan.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w400,
                    color: isDriver ? const Color(0xFF14532D) : const Color(0xFF1E40AF),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
              const Text(
                'Rincian Biaya Sewa',
                style: TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.badgeAmberBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Menunggu Detail Harga',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w700,
                    color: AppColors.badgeAmberText,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Sewa Unit (${booking.durationDays} Hari)',
            'Rp ${_formatRupiah(booking.vehicleSubtotal)}',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Layanan Sopir (${booking.durationDays} Hari)',
            booking.withDriver ? 'Rp ${_formatRupiah(booking.driverSubtotal)}' : 'Gratis',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Biaya Layanan Sistem Operasional',
            'Rp ${_formatRupiah(booking.serviceFee)}',
          ),
          const Divider(height: 20, color: AppColors.borderSubtle),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text(
                'Total Terhitung',
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
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.withDriver
                        ? 'Rincian biaya final resmi (termasuk konfirmasi rute luar kota jika ada, durasi jam operasional 12 jam/hari, atau diskon promo pengguna baru) akan dikonfirmasi langsung oleh admin dari dashboard.'
                        : 'Rincian biaya final resmi (termasuk biaya layanan jam operasional kantor, deposit jaminan refundable, atau diskon promo pengguna baru) akan dikonfirmasi langsung oleh admin dari dashboard.',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: Color(0xFF92400E),
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
    return InkWell(
      onTap: () => booking.setAgreementChecked(!booking.agreementChecked),
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
                value: booking.agreementChecked,
                activeColor: AppColors.primaryNavy,
                onChanged: (val) {
                  if (val != null) booking.setAgreementChecked(val);
                },
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Saya menyetujui syarat & ketentuan rental MobilJuragan serta bersedia menunjukkan dokumen fisik asli saat serah terima unit di Merauke.',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      child: SafeArea(
        top: false,
        child: SizedBox(
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
              'Kirim Pengajuan & Tunggu Tarif Final',
              style: AppTypography.sectionTitle,
            ),
          ),
        ),
      ),
    );
  }

  void _processOrderSubmission(
    BuildContext context,
    BookingController booking,
    VehicleModel vehicle,
  ) {
    final newBooking = booking.submitBooking();
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        auth.loginAsDefault();
                        Navigator.pop(modalCtx);
                        _processOrderSubmission(context, booking, vehicle);
                      },
                      child: const Text(
                        'Pintasan Demo: Masuk Cepat sebagai Harun',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
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
