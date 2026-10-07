import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/order_empty_state.dart';
import 'date_time_screen.dart';
import 'order_status_screen.dart';
import '../theme/app_typography.dart';

/// Layar Riwayat Pesanan (Frame 08)
/// Menampilkan daftar pesanan berjalan dan riwayat selesai dengan segmented tab switcher
class OrderHistoryScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onNavigateToPesan;

  const OrderHistoryScreen({
    super.key,
    this.showBackButton = false,
    this.onNavigateToPesan,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedSegment = 0; // 0: Pesanan Berjalan, 1: Riwayat Selesai

  final List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  Widget build(BuildContext context) {
    final bookingController = context.watch<BookingController>();
    final activeBookings = bookingController.activeBookings;
    final completedBookings = bookingController.completedBookings;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: 'Riwayat Pesanan',
        showBackButton: widget.showBackButton,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubtitleHeader(),
            const SizedBox(height: 14),
            _buildSegmentedControl(
              activeCount: activeBookings.length,
              completedCount: completedBookings.length,
            ),
            const SizedBox(height: 20),
            if (_selectedSegment == 0) ...[
              _buildActiveSection(activeBookings),
            ] else ...[
              _buildCompletedSection(completedBookings),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lacak Status Armada & Transaksi',
          style: TextStyle(
            fontSize: AppTypography.sizeTitle,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Pantau proses verifikasi, penyiapan armada, dan kepulangan unit di Merauke.',
          style: TextStyle(
            fontSize: AppTypography.sizeBody,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  /// Segmented Control Switcher (Frame 08)
  Widget _buildSegmentedControl({
    required int activeCount,
    required int completedCount,
  }) {
    return Container(
      width: double.infinity,
      // Tinggi mengikuti skala teks perangkat. Tinggi tetap 48 px membuat
      // label terpotong saat ukuran teks sistem diperbesar.
      height: (48 * MediaQuery.textScalerOf(context).scale(1)).clamp(48, 96),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              index: 0,
              label: 'Pesanan Berjalan',
              count: activeCount,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentButton(
              index: 1,
              label: 'Riwayat Selesai',
              count: completedCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedSegment == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSegment = index;
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.primaryNavy,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Bagian Pesanan Berjalan
  Widget _buildActiveSection(List<BookingModel> activeBookings) {
    if (activeBookings.isEmpty) {
      return OrderEmptyState(
        title: 'Tidak Ada Pesanan Berjalan',
        description:
            'Saat ini Anda tidak memiliki jadwal sewa unit yang sedang aktif. Silakan pilih armada untuk keperluan perjalanan Anda di Merauke.',
        ctaText: 'Pesan Mobil Sekarang',
        onCtaPressed: () {
          if (widget.onNavigateToPesan != null) {
            widget.onNavigateToPesan!();
          } else {
            Navigator.pop(context);
          }
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
            Text(
              'Pesanan Aktif (${activeBookings.length})',
              style: const TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const Text(
              'Pembaruan real-time',
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...activeBookings.map((booking) => _buildBookingCard(booking, isActive: true)),
      ],
    );
  }

  /// Bagian Riwayat Selesai
  Widget _buildCompletedSection(List<BookingModel> completedBookings) {
    if (completedBookings.isEmpty) {
      return OrderEmptyState(
        title: 'Belum Ada Riwayat Selesai',
        description:
            'Semua transaksi sewa armada yang telah rampung dan dikembalikan ke kantor MobilJuragan Merauke akan tersimpan di sini.',
        ctaText: 'Mulai Sewa Pertama',
        onCtaPressed: () {
          if (widget.onNavigateToPesan != null) {
            widget.onNavigateToPesan!();
          } else {
            Navigator.pop(context);
          }
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Sewa Sebelumnya (${completedBookings.length})',
          style: const TextStyle(
            fontSize: AppTypography.sizeBodyLarge,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        ...completedBookings.map((booking) => _buildBookingCard(booking, isActive: false)),
      ],
    );
  }

  /// Kartu Pesanan Reusable (Frame 08: Card Pesanan Berjalan S8)
  Widget _buildBookingCard(BookingModel booking, {required bool isActive}) {
    final vehicle = booking.vehicle;
    final startDate = booking.startDate;
    final endDate = booking.endDate;

    final startStr =
        '${startDate.day} ${_monthNames[startDate.month - 1]} ${startDate.year}';
    final endStr =
        '${endDate.day} ${_monthNames[endDate.month - 1]} ${endDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primaryTeal.withValues(alpha: 0.35) : AppColors.borderSubtle,
          width: isActive ? 1.2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu: Status Badge & Booking Ref
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
            children: [
              _buildStatusBadge(booking.status),
              Text(
                booking.id,
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          // Detail Armada Kendaraan
          Row(
            children: [
              Container(
                width: 60,
                height: 48,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeBodyLarge,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plat: ${vehicle.plateNumber} • ${booking.modeLabel}',
                      style: const TextStyle(
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
          const SizedBox(height: 12),

          // Info Jadwal & Lokasi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$startStr, ${booking.startTime} (${booking.durationDays} Hari) - Kembali: $endStr',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.pickupLocation,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
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
          const SizedBox(height: 12),

          if (booking.status == BookingStatus.dibatalkan) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.remove_circle_outline_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Alasan: ${booking.cancellationReason ?? "Dibatalkan oleh pelanggan"}',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (booking.cancellationRefundAmount != null &&
                      booking.cancellationRefundAmount! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pengembalian Dana: Rp ${_formatRupiah(booking.cancellationRefundAmount!)}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Tarif & Aksi
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.isFinalTariffConfirmed ? 'Tarif Resmi Final' : 'Estimasi Total Biaya',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${_formatRupiah(booking.totalCost)}',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTitle,
                      fontWeight: FontWeight.w800,
                      color: booking.isFinalTariffConfirmed
                          ? AppColors.primaryNavy
                          : AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              if (isActive) ...[
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderStatusScreen(booking: booking),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cek Status',
                          style: AppTypography.bodyBold,
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      // Sewa lagi: pilih kendaraan ini dan navigasi ke tanggal
                      final bookingCtrl = context.read<BookingController>();
                      bookingCtrl.selectVehicle(vehicle);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DateTimeScreen(vehicle: vehicle),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: AppColors.primaryNavy, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Sewa Lagi',
                      style: AppTypography.bodyBold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case BookingStatus.permintaanDiterima:
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        label = 'Pengajuan Diterima';
        icon = Icons.inbox_outlined;
        break;
      case BookingStatus.pemeriksaanArmada:
        bg = const Color(0xFFF0FDF4);
        text = const Color(0xFF15803D);
        label = 'Armada Tersedia';
        icon = Icons.check_circle_outline;
        break;
      case BookingStatus.menungguTarifFinal:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'Hitung Tarif Final';
        icon = Icons.calculate_outlined;
        break;
      case BookingStatus.menungguPembayaran:
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFB91C1C);
        label = 'Menunggu Pembayaran';
        icon = Icons.payment_outlined;
        break;
      case BookingStatus.pembayaranSelesai:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = 'Pembayaran Terkonfirmasi';
        icon = Icons.verified_outlined;
        break;
      case BookingStatus.verifikasiKantor:
        bg = const Color(0xFFF5F3FF);
        text = const Color(0xFF6D28D9);
        label = 'Verifikasi Fisik Kantor';
        icon = Icons.business_outlined;
        break;
      case BookingStatus.mobilSiapDigunakan:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = 'Armada Siap Jalan';
        icon = Icons.directions_car_outlined;
        break;
      case BookingStatus.selesai:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF334155);
        label = 'Selesai Digunakan';
        icon = Icons.task_alt;
        break;
      case BookingStatus.dibatalkan:
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFF991B1B);
        label = 'Dibatalkan';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.sizeTiny,
              fontWeight: FontWeight.w700,
              color: text,
              fontFamily: 'Inter',
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
