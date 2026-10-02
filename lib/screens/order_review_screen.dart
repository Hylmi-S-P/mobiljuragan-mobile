import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'order_status_screen.dart';

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
        stepSubtitle: 'Langkah 5 dari 5',
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
                  _buildPhysicalVerificationNotice(),
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Pastikan pilihan armada, durasi tanggal, dan moda rental telah sesuai.',
          style: TextStyle(
            fontSize: 12,
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
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Armada Kendaraan',
                    style: TextStyle(
                      fontSize: 13,
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
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 12,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plat: ${vehicle.plateNumber}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.transmission} • ${vehicle.seatCapacity} Kursi • ${vehicle.bodyType}',
                      style: const TextStyle(
                        fontSize: 11,
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
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Jadwal Rental',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // Kembali ke pengaturan jadwal sewa
                  Navigator.pop(context); // Pop dari Opsi Rental atau pop dua kali
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 12,
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
        ],
      ),
    );
  }

  /// Kartu Ringkasan 3: Moda Rental & Lokasi Penjemputan
  Widget _buildRentalOptionsSummaryCard(BuildContext context, BookingController booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.commute_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Moda & Lokasi Serah Terima',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Kembali ke Opsi Rental
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 12,
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
          _buildInfoRow('Titik Serah Terima', booking.pickupLocation),
        ],
      ),
    );
  }

  /// Banner Pemberitahuan Verifikasi Fisik di Kantor (Bukan Online)
  Widget _buildPhysicalVerificationNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFF1D4ED8)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verifikasi Fisik Dokumen di Kantor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sesuai ketentuan resmi MobilJuragan Merauke, verifikasi fisik KTP asli dan SIM A dilakukan langsung oleh staf kantor saat serah terima unit kendaraan.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1E40AF),
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
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimasi Biaya',
                style: TextStyle(
                  fontSize: 13,
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
                    fontSize: 10,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimasi Biaya',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'Rp ${_formatRupiah(booking.totalCalculatedCost)}',
                style: const TextStyle(
                  fontSize: 16,
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
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rincian biaya final resmi (termasuk biaya layanan jam operasional, deposit jaminan refundable, atau diskon promo pengguna baru) akan diinput dan dikonfirmasi langsung oleh admin dari dashboard setelah pengajuan dikirim.',
                    style: TextStyle(
                      fontSize: 11,
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
                  fontSize: 11,
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
          height: 48,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
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
        builder: (_) => OrderStatusScreen(booking: newBooking),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Diperlukan sebelum konfirmasi pengajuan sewa',
                          style: TextStyle(
                            fontSize: 11,
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
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
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
                height: 44,
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
                      fontSize: 13,
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
                  TextButton(
                    onPressed: () {
                      auth.loginAsDefault();
                      Navigator.pop(modalCtx);
                      _processOrderSubmission(context, booking, vehicle);
                    },
                    child: const Text(
                      'Pintasan Demo: Masuk Cepat sebagai Harun',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
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
