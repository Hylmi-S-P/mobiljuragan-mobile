import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_support_screen.dart';
import 'main_navigation_screen.dart';

/// Layar pelacakan status pesanan (Frame 07)
/// Mengikuti alur stepper Figma dengan penambahan tahap Menunggu Pembayaran
/// Menjalankan verifikasi tarif final admin 10 detik di latar belakang dan memicu notifikasi native sistem
class OrderStatusScreen extends StatefulWidget {
  final BookingModel? booking;

  const OrderStatusScreen({
    super.key,
    this.booking,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Timer? _calculationTimer;
  bool _notificationShown = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTimer();
  }

  void _checkAndStartTimer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BookingController>();
      final currentBooking = widget.booking ?? controller.activeBooking;

      if (currentBooking != null &&
          currentBooking.status == BookingStatus.menungguTarifFinal) {
        _startAdminCalculationTimer();
      }
    });
  }

  void _startAdminCalculationTimer() {
    _calculationTimer?.cancel();
    _notificationShown = false;

    // Timer berjalan hening 10 detik di latar belakang tanpa hitung mundur visual
    _calculationTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _onAdminCalculationCompleted();
      }
    });
  }

  void _onAdminCalculationCompleted() {
    if (!mounted) return;
    final controller = context.read<BookingController>();
    controller.confirmFinalTariffFromAdmin();

    final currentBooking = widget.booking != null
        ? (controller.bookingHistory.firstWhere(
            (b) => b.id == widget.booking!.id,
            orElse: () => widget.booking!,
          ))
        : controller.activeBooking;

    // Memicu notifikasi native sistem perangkat (terlihat di luar aplikasi)
    if (currentBooking != null) {
      NotificationService().showTariffReadyNotification(
        bookingId: currentBooking.id,
        vehicleName: currentBooking.vehicle.name,
        totalCost: currentBooking.totalCost,
      );
    }

    if (!_notificationShown) {
      _notificationShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryNavy,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.notifications_active, color: Color(0xFFFDE68A), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Biaya final sudah tersedia dari admin! Status masuk ke Menunggu Pembayaran.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _calculationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingController = context.watch<BookingController>();
    final activeBooking = widget.booking != null
        ? (bookingController.bookingHistory.firstWhere(
            (b) => b.id == widget.booking!.id,
            orElse: () => widget.booking!,
          ))
        : bookingController.activeBooking;

    if (activeBooking == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: const CustomAppBar(title: 'Status Pesanan', showBackButton: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Pesanan Aktif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan lakukan pemesanan armada kendaraan terlebih dahulu.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Buka Katalog Armada'),
              ),
            ],
          ),
        ),
      );
    }

    final isWaitingPayment = activeBooking.status == BookingStatus.menungguPembayaran;
    final isPaid = activeBooking.status == BookingStatus.pembayaranSelesai ||
        activeBooking.status == BookingStatus.verifikasiKantor ||
        activeBooking.status == BookingStatus.mobilSiapDigunakan ||
        activeBooking.status == BookingStatus.selesai;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: 'Status Pesanan',
        showBackButton: true,
        onBackPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeaderCard(activeBooking),
            const SizedBox(height: 14),

            _buildVehicleSummaryCard(activeBooking),
            const SizedBox(height: 16),

            // Stepper Mengikuti Figma + Menunggu Pembayaran
            _buildFigmaStepper(activeBooking),
            const SizedBox(height: 16),

            // Rincian Tarif Final dari Admin (Muncul setelah tarif final terbit)
            if (activeBooking.isFinalTariffConfirmed) ...[
              _buildFinalTariffDetailsCard(activeBooking),
              const SizedBox(height: 16),
            ] else ...[
              _buildPendingTariffNoticeCard(activeBooking),
              const SizedBox(height: 16),
            ],

            // Panduan Pembayaran via Chat CS & Bot
            if (isWaitingPayment) ...[
              _buildChatPaymentCard(context, activeBooking),
              const SizedBox(height: 16),
            ] else if (isPaid) ...[
              _buildPaidStatusNoticeCard(activeBooking),
              const SizedBox(height: 16),
            ],

            _buildActionButtons(context, activeBooking),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeaderCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kode Reservasi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                booking.id,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusBgColor(booking.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              booking.statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _getStatusTextColor(booking.status),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVehicleSummaryCard(BookingModel booking) {
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
            children: [
              Container(
                width: 60,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    booking.vehicle.imageUrl,
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
                      booking.vehicle.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.vehicle.plateNumber} • ${booking.durationDays} Hari (${booking.modeLabel})',
                      style: const TextStyle(
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
          const Divider(height: 20, color: AppColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.isFinalTariffConfirmed ? 'Total Tarif Resmi Final' : 'Estimasi Biaya',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'Rp ${_formatRupiah(booking.totalCost)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: booking.isFinalTariffConfirmed ? AppColors.primaryTeal : AppColors.primaryNavy,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stepper Mengikuti 5 Tahapan Resmi (Tanpa Verifikasi Fisik KTP)
  Widget _buildFigmaStepper(BookingModel booking) {
    final status = booking.status;

    // Tahap 1: Permintaan diterima
    final step1Done = true;

    // Tahap 2: Pemeriksaan armada (siap & jadwal terkonfirmasi)
    final step2Done = true;

    // Tahap 3: Konfirmasi tarif final
    final step3Active = status == BookingStatus.menungguTarifFinal;
    final step3Done = booking.isFinalTariffConfirmed ||
        status == BookingStatus.menungguPembayaran ||
        status == BookingStatus.pembayaranSelesai ||
        status == BookingStatus.mobilSiapDigunakan ||
        status == BookingStatus.selesai;

    // Tahap 4: Menunggu Pembayaran
    final step4Active = status == BookingStatus.menungguPembayaran;
    final step4Done = status == BookingStatus.pembayaranSelesai ||
        status == BookingStatus.mobilSiapDigunakan ||
        status == BookingStatus.selesai;

    // Tahap 5: Mobil siap digunakan
    final step5Active = status == BookingStatus.mobilSiapDigunakan ||
        status == BookingStatus.pembayaranSelesai;
    final step5Done = status == BookingStatus.selesai;

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
          const Text(
            'Tahapan Proses Pesanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            stepNumber: 1,
            title: 'Permintaan diterima',
            subtitle: 'Data pengajuan telah tercatat di sistem MobilJuragan',
            isDone: step1Done,
            isActive: false,
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: 2,
            title: 'Pemeriksaan armada',
            subtitle: 'Armada siap dan jadwal operasional terkonfirmasi',
            isDone: step2Done,
            isActive: false,
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: 3,
            title: 'Konfirmasi tarif final',
            subtitle: step3Done
                ? 'Rincian tarif final resmi telah diterbitkan oleh admin'
                : 'Sedang diverifikasi oleh admin operasional',
            isDone: step3Done,
            isActive: step3Active,
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: 4,
            title: 'Menunggu Pembayaran',
            subtitle: step4Done
                ? 'Pembayaran telah dikonfirmasi oleh tim CS'
                : (step4Active
                    ? 'Silakan lakukan pembayaran dan konfirmasi via Chat CS'
                    : 'Menunggu penerbitan rincian tarif final resmi'),
            isDone: step4Done,
            isActive: step4Active,
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: 5,
            title: 'Mobil siap digunakan',
            subtitle: step5Done
                ? 'Masa sewa telah selesai dan unit telah kembali'
                : (step5Active
                    ? 'Pembayaran tervalidasi. Kunci dan armada siap diserahterimakan di ${booking.pickupLocation}'
                    : 'Kunci dan armada akan diserahkan setelah pembayaran selesai'),
            isDone: step5Done,
            isActive: step5Active,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required bool isLast,
  }) {
    Color iconColor;
    Color iconBgColor;
    Widget iconChild;

    if (isDone) {
      iconBgColor = AppColors.badgeGreenBg;
      iconColor = AppColors.badgeGreenText;
      iconChild = Icon(Icons.check, size: 14, color: iconColor);
    } else if (isActive) {
      iconBgColor = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF1D4ED8);
      iconChild = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: iconColor,
          shape: BoxShape.circle,
        ),
      );
    } else {
      iconBgColor = AppColors.surfaceLight;
      iconColor = AppColors.textSecondary;
      iconChild = Text(
        '$stepNumber',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: iconColor,
          fontFamily: 'Inter',
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF1D4ED8)
                        : (isDone ? AppColors.badgeGreenText : AppColors.borderSubtle),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Center(child: iconChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.badgeGreenText : AppColors.borderSubtle,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF1D4ED8)
                                : (isDone ? AppColors.textPrimary : AppColors.textSecondary),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PROSES',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Rincian Tarif Final dari Admin (Menampilkan Surcharge, Deposit, dan Diskon)
  Widget _buildFinalTariffDetailsCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rincian Tarif Resmi Final',
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
                  color: AppColors.badgeGreenBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Divalidasi Admin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.badgeGreenText,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTariffRow('Sewa Unit (${booking.durationDays} Hari)', 'Rp ${_formatRupiah(booking.vehicleSubtotal)}'),
          const SizedBox(height: 6),
          _buildTariffRow(
            'Layanan Sopir (${booking.durationDays} Hari)',
            booking.withDriver ? 'Rp ${_formatRupiah(booking.driverSubtotal)}' : 'Gratis',
          ),
          const SizedBox(height: 6),
          _buildTariffRow('Biaya Layanan Sistem Operasional', 'Rp ${_formatRupiah(booking.serviceFee)}'),

          // Rincian Tambahan / Penyesuaian dari Admin Dashboard
          if (booking.adminAdjustments.isNotEmpty) ...[
            const Divider(height: 16, color: AppColors.borderSubtle),
            const Text(
              'Penyesuaian Biaya (Admin Dashboard):',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            ...booking.adminAdjustments.map((adj) {
              final isNegative = adj.isDeduction;
              final prefix = isNegative ? '-Rp ' : '+Rp ';
              final absAmount = adj.amount.abs();
              final color = isNegative ? const Color(0xFF059669) : const Color(0xFF1D4ED8);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adj.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (adj.note != null)
                            Text(
                              adj.note!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '$prefix${_formatRupiah(absAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const Divider(height: 20, color: AppColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tarif Final Resmi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'Rp ${_formatRupiah(booking.totalCost)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTariffNoticeCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_top, size: 18, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text(
                'Menunggu Rincian Tarif Final',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Estimasi awal saat ini Rp ${_formatRupiah(booking.baseEstimatedCost)}. Rincian penyesuaian biaya operasional atau deposit akan tampil di sini segera setelah dikonfirmasi admin.',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffRow(String label, String value) {
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

  Widget _buildChatPaymentCard(BuildContext context, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text(
                'Metode Pembayaran via Chat CS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Rincian tagihan resmi, nomor rekening transfer Bank BRI Merauke, dan validasi pembayaran dikirimkan langsung melalui Chat CS. Buka chat untuk menerima instruksi lengkap dan konfirmasi pembayaran.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF14532D),
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidStatusNoticeCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.badgeGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeGreenText.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 22, color: AppColors.badgeGreenText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembayaran Lunas via Chat CS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.badgeGreenText,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pembayaran telah diverifikasi oleh tim CS. Armada ${booking.vehicle.name} siap digunakan di ${booking.pickupLocation}.',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.badgeGreenText,
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

  Widget _buildActionButtons(BuildContext context, BookingModel booking) {
    final isWaitingPayment = booking.status == BookingStatus.menungguPembayaran;

    return Column(
      children: [
        if (isWaitingPayment) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatSupportScreen(booking: booking),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
              label: const Text(
                'Bayar & Konfirmasi via Chat CS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Metode pembayaran dan konfirmasi transfer diproses melalui Chat CS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatSupportScreen(booking: booking),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent, size: 18, color: AppColors.primaryTeal),
              label: const Text(
                'Hubungi CS MobilJuragan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryTeal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusBgColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.permintaanDiterima:
      case BookingStatus.pemeriksaanArmada:
      case BookingStatus.menungguTarifFinal:
        return const Color(0xFFEFF6FF);
      case BookingStatus.menungguPembayaran:
        return const Color(0xFFFFFBEB);
      case BookingStatus.pembayaranSelesai:
      case BookingStatus.verifikasiKantor:
      case BookingStatus.mobilSiapDigunakan:
      case BookingStatus.selesai:
        return AppColors.badgeGreenBg;
      case BookingStatus.dibatalkan:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _getStatusTextColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.permintaanDiterima:
      case BookingStatus.pemeriksaanArmada:
      case BookingStatus.menungguTarifFinal:
        return const Color(0xFF1D4ED8);
      case BookingStatus.menungguPembayaran:
        return const Color(0xFFB45309);
      case BookingStatus.pembayaranSelesai:
      case BookingStatus.verifikasiKantor:
      case BookingStatus.mobilSiapDigunakan:
      case BookingStatus.selesai:
        return AppColors.badgeGreenText;
      case BookingStatus.dibatalkan:
        return const Color(0xFFB91C1C);
    }
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
