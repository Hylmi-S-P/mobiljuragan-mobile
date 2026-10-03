import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_support_screen.dart';
import 'date_time_screen.dart';
import 'main_navigation_screen.dart';

/// Layar pelacakan status pesanan (Frame 07)
/// Mengikuti alur stepper Figma dengan penambahan tahap Menunggu Pembayaran
/// Menjalankan verifikasi tarif final admin 10 detik di latar belakang dan memicu notifikasi native sistem
class OrderStatusScreen extends StatefulWidget {
  final BookingModel? booking;
  final bool fromOrderSubmission;

  const OrderStatusScreen({
    super.key,
    this.booking,
    this.fromOrderSubmission = false,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Timer? _calculationTimer;
  bool _notificationShown = false;
  bool _isTariffDetailsExpanded = false;

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

    final isCancelled = activeBooking.status == BookingStatus.dibatalkan;
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
          if (widget.fromOrderSubmission) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainNavigationScreen(initialTabIndex: 0),
              ),
              (route) => false,
            );
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainNavigationScreen(initialTabIndex: 0),
              ),
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

            if (isCancelled) ...[
              _buildCancelledBannerCard(activeBooking),
              const SizedBox(height: 16),
              _buildVehicleSummaryCard(activeBooking),
              const SizedBox(height: 16),
              _buildCancelledAssistanceCard(context, activeBooking),
              const SizedBox(height: 16),
            ] else ...[
              _buildVehicleSummaryCard(activeBooking),
              const SizedBox(height: 16),

              // Kartu Khusus Staf Pengemudi (Dengan Sopir) atau Panduan Serah Terima (Lepas Kunci)
              if (activeBooking.withDriver) ...[
                _buildAssignedDriverCard(context, activeBooking),
                const SizedBox(height: 16),
              ] else ...[
                _buildSelfDriveHandoverGuideCard(activeBooking),
                const SizedBox(height: 16),
              ],

              // Stepper Mengikuti Figma + Menunggu Pembayaran
              _buildFigmaStepper(activeBooking),
              const SizedBox(height: 16),

              // Notifikasi menunggu konfirmasi tarif final (hanya saat proses kalkulasi admin berlangsung)
              if (!activeBooking.isFinalTariffConfirmed) ...[
                _buildPendingTariffNoticeCard(activeBooking),
                const SizedBox(height: 16),
              ],

              // Kartu Pengingat Pembayaran atau E-Ticket Resmi
              if (isWaitingPayment) ...[
                _buildPaymentNoticeCard(context, activeBooking),
                const SizedBox(height: 16),
              ] else if (isPaid) ...[
                _buildETicketCard(context, activeBooking),
                const SizedBox(height: 16),
              ],
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
    final isCancelled = booking.status == BookingStatus.dibatalkan;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: booking.isFinalTariffConfirmed && !isCancelled
              ? AppColors.primaryTeal.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
          width: booking.isFinalTariffConfirmed && !isCancelled ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info kendaraan
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 50,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking.vehicle.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          if (isCancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Reservasi Ditutup',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                        ],
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
          ),

          const Divider(height: 1, color: AppColors.borderSubtle),

          // Baris Total Tarif dengan tombol interaktif buka/tutup rincian
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isCancelled
                  ? null
                  : () {
                      setState(() {
                        _isTariffDetailsExpanded = !_isTariffDetailsExpanded;
                      });
                    },
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(_isTariffDetailsExpanded ? 0 : 14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCancelled
                              ? 'Total Nilai Sewa (Batal)'
                              : (booking.isFinalTariffConfirmed
                                  ? 'Total Tarif Resmi Final'
                                  : 'Estimasi Total Biaya'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (!isCancelled) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isTariffDetailsExpanded
                                    ? 'Sembunyikan Rincian'
                                    : 'Lihat Rincian Tarif',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                _isTariffDetailsExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color: AppColors.primaryTeal,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Rp ${_formatRupiah(booking.totalCost)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isCancelled
                            ? AppColors.textMuted
                            : (booking.isFinalTariffConfirmed
                                ? AppColors.primaryTeal
                                : AppColors.primaryNavy),
                        fontFamily: 'Inter',
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Konten rincian biaya yang terbuka saat di-expand
          if (_isTariffDetailsExpanded && !isCancelled) ...[
            const Divider(height: 1, color: AppColors.borderSubtle),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTariffRow('Sewa Unit (${booking.durationDays} Hari)', 'Rp ${_formatRupiah(booking.vehicleSubtotal)}'),
                  const SizedBox(height: 6),
                  _buildTariffRow(
                    'Layanan Sopir (${booking.durationDays} Hari)',
                    booking.withDriver ? 'Rp ${_formatRupiah(booking.driverSubtotal)}' : 'Gratis',
                  ),
                  const SizedBox(height: 6),
                  _buildTariffRow('Biaya Layanan Sistem Operasional', 'Rp ${_formatRupiah(booking.serviceFee)}'),

                  // Penyesuaian Biaya Operasional jika ada
                  if (booking.adminAdjustments.isNotEmpty) ...[
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    const Text(
                      'Penyesuaian Biaya Operasional:',
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Stepper Mengikuti 5 Tahapan Resmi (Adaptif: Lepas Kunci vs Dengan Sopir)
  Widget _buildFigmaStepper(BookingModel booking) {
    final status = booking.status;
    final isDriver = booking.withDriver;

    // Tahap 1: Permintaan diterima
    final step1Done = true;

    // Tahap 2: Pemeriksaan armada (Lepas Kunci) atau Penugasan sopir (Dengan Sopir)
    final step2Done = true;

    // Tahap 3: Konfirmasi tarif final
    final step3Active = status == BookingStatus.menungguTarifFinal;
    final step3Done = booking.isFinalTariffConfirmed ||
        status == BookingStatus.menungguPembayaran ||
        status == BookingStatus.pembayaranSelesai ||
        status == BookingStatus.mobilSiapDigunakan ||
        status == BookingStatus.selesai;

    final isCod = booking.paymentMethodType == PaymentMethodType.tunaiDiTempat;

    // Tahap 4: Pembayaran Online / Pelunasan Tunai (COD)
    // Jika COD: aktif saat mobilSiapDigunakan (menunggu penyerahan unit & uang tunai di lokasi). Selesai jika status == selesai.
    // Jika Online: aktif saat menungguPembayaran, selesai jika pembayaran telah lunas (pembayaranSelesai/mobilSiapDigunakan/selesai).
    final step4Active = isCod
        ? (status == BookingStatus.mobilSiapDigunakan)
        : (status == BookingStatus.menungguPembayaran);
    final step4Done = isCod
        ? (status == BookingStatus.selesai)
        : (status == BookingStatus.pembayaranSelesai ||
            status == BookingStatus.mobilSiapDigunakan ||
            status == BookingStatus.selesai);

    // Tahap 5: Mobil siap digunakan / Sopir standby menjemput
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
            title: isDriver ? 'Penugasan sopir operasional' : 'Pemeriksaan armada',
            subtitle: isDriver
                ? 'Staf pengemudi tetap telah dialokasikan. Kontak dikoordinasikan via Chat CS'
                : 'Armada siap dan jadwal operasional terkonfirmasi di pool',
            isDone: step2Done,
            isActive: false,
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: 3,
            title: isDriver ? 'Konfirmasi tarif final resmi' : 'Konfirmasi tarif final & deposit',
            subtitle: step3Done
                ? (isDriver
                    ? 'Rincian tarif final resmi harian telah diterbitkan oleh admin'
                    : 'Rincian tarif final dan deposit jaminan telah diterbitkan admin')
                : (isDriver
                    ? 'Admin sedang memvalidasi rute dan durasi 12 jam/hari'
                    : 'Sedang diverifikasi oleh admin operasional'),
            isDone: step3Done,
            isActive: step3Active,
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: 4,
            title: isCod ? 'Pelunasan Tunai di Tempat (COD)' : 'Menunggu Pembayaran',
            subtitle: isCod
                ? (step4Done
                    ? 'Pembayaran tunai telah diterima staf atau pengemudi di lokasi'
                    : (step4Active
                        ? 'Siapkan uang tunai pas Rp ${_formatRupiah(booking.totalCost)} saat serah terima unit'
                        : 'Menunggu serah terima unit untuk pelunasan tunai'))
                : (step4Done
                    ? 'Pembayaran telah dikonfirmasi oleh tim CS'
                    : (step4Active
                        ? 'Silakan lakukan pembayaran dan konfirmasi via Chat CS'
                        : 'Menunggu penerbitan rincian tarif final resmi')),
            isDone: step4Done,
            isActive: step4Active,
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: 5,
            title: isDriver ? 'Sopir standby menjemput' : 'Serah terima unit & kunci',
            subtitle: step5Done
                ? (isDriver
                    ? 'Layanan sopir telah selesai dan armada telah kembali ke pool'
                    : 'Masa sewa telah selesai dan unit telah kembali ke pool')
                : (step5Active
                    ? (isCod
                        ? (isDriver
                            ? 'Sopir siap menjemput Anda di ${booking.pickupLocation}. Pembayaran tunai saat penjemputan'
                            : 'Kunci dan armada siap diserahterimakan di ${booking.pickupLocation}. Pembayaran tunai saat serah terima')
                        : (isDriver
                            ? 'Pembayaran tervalidasi. Sopir siap menjemput Anda di ${booking.pickupLocation}'
                            : 'Pembayaran tervalidasi. Kunci dan armada siap diserahterimakan di ${booking.pickupLocation}'))
                    : (isDriver
                        ? 'Sopir akan standby menjemput setelah jadwal terkonfirmasi'
                        : 'Kunci dan armada akan diserahkan setelah jadwal terkonfirmasi')),
            isDone: step5Done,
            isActive: step5Active,
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// Kartu Informasi Staf Pengemudi Tetap (Khusus Dengan Sopir, Tanpa Rating Ojol)
  Widget _buildAssignedDriverCard(BuildContext context, BookingModel booking) {
    final driver = booking.assignedDriver;
    final driverName = driver?.driverName ?? 'Bung Yohanes Mahuze';
    final role = driver?.operationalRole ?? 'Staf Pengemudi Tetap MobilJuragan Merauke';

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
              const Row(
                children: [
                  Icon(Icons.badge_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Staf Pengemudi Bertugas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.badgeGreenBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Karyawan Tetap',
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chat_outlined, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nomor WhatsApp sopir telah dibagikan oleh CS di ruang chat. Sopir juga telah menerima nomor Anda dan akan menghubungi sebelum waktu penjemputan untuk koordinasi lokasi.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: Color(0xFF166534),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Standby 12 Jam/Hari (mulai ${booking.startTime})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatSupportScreen(booking: booking),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Buka Chat CS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Kartu Panduan Serah Terima Mandiri (Khusus Lepas Kunci)
  Widget _buildSelfDriveHandoverGuideCard(BookingModel booking) {
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
                  Icon(Icons.key_rounded, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Panduan Serah Terima Mandiri',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Lepas Kunci',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryNavy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lokasi: ${booking.pickupLocation}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Catatan penting serah terima unit:\n'
            '• Tunjukkan fisik asli e-KTP dan SIM A yang masih berlaku kepada staf lapangan.\n'
            '• Pengecekan bersama kondisi bodi, interior, ban cadangan, dan indikator bahan bakar.\n'
            '• Deposit jaminan sewa (refundable) akan dikembalikan utuh setelah masa sewa berakhir.',
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
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
            booking.withDriver
                ? 'Estimasi awal saat ini Rp ${_formatRupiah(booking.baseEstimatedCost)}. Rincian penyesuaian operasional sopir atau rute perjalanan akan tampil di sini segera setelah dikonfirmasi admin.'
                : 'Estimasi awal saat ini Rp ${_formatRupiah(booking.baseEstimatedCost)}. Rincian penyesuaian biaya operasional atau deposit jaminan refundable akan tampil di sini segera setelah dikonfirmasi admin.',
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

  Widget _buildMiniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildTicketDetailItem({
    required String label,
    required String value,
    String? subValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        if (subValue != null) ...[
          const SizedBox(height: 1),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentNoticeCard(BuildContext context, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menunggu Pembayaran',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tarif resmi final telah diterbitkan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: Color(0xFFB45309)),
                    SizedBox(width: 4),
                    Text(
                      '23:59:00',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tagihan Pembayaran',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'Rp ${_formatRupiah(booking.totalCost)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.primaryTeal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tekan tombol "Bayar Sekarang" di bawah untuk memilih metode pembayaran (Online QRIS/VA atau Tunai COD).',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                      height: 1.3,
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

  void _showPaymentMethodPickerSheet(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(pickerContext),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total yang Harus Dibayar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'Rp ${_formatRupiah(booking.totalCost)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Opsi 1: QRIS & Virtual Account Otomatis
              InkWell(
                onTap: () {
                  Navigator.pop(pickerContext);
                  _showOnlinePaymentSheet(context, booking);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 22,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Transfer & QRIS Otomatis',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Verifikasi Cepat',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'QRIS instan dan Virtual Account (BCA, Mandiri, BRI, BNI). Verifikasi otomatis tanpa kirim bukti transfer.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildMiniBadge('QRIS'),
                                _buildMiniBadge('BCA'),
                                _buildMiniBadge('BRI'),
                                _buildMiniBadge('BNI'),
                                _buildMiniBadge('Mandiri'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Opsi 2: Bayar Tunai di Tempat (COD)
              InkWell(
                onTap: () {
                  Navigator.pop(pickerContext);
                  _showCodConfirmationSheet(context, booking);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.handshake_outlined,
                          size: 22,
                          color: Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Bayar Tunai di Tempat (COD)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Serah Terima',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Bayar langsung saat serah terima kunci dan cek fisik kendaraan di titik penjemputan Merauke.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Jaminan Keamanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: AppColors.primaryTeal),
                    SizedBox(width: 6),
                    Text(
                      'Transaksi aman & bergaransi resmi MobilJuragan Merauke',
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
        );
      },
    );
  }

  Widget _buildETicketCard(BuildContext context, BookingModel booking) {
    final isCod = booking.isCodPayment;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tiket Resmi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.confirmation_num_outlined, size: 18, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'E-TICKET RESMI MOBILJURAGAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white70,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          booking.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCod ? const Color(0xFF1E3A8A) : const Color(0xFF065F46),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCod ? const Color(0xFF60A5FA) : const Color(0xFF34D399),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isCod ? 'METODE COD' : 'LUNAS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isCod ? const Color(0xFFDBEAFE) : const Color(0xFFD1FAE5),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Isi Tiket
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Status Pelunasan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCod ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCod ? Icons.info_outline : Icons.verified_outlined,
                        size: 16,
                        color: isCod ? const Color(0xFF1D4ED8) : const Color(0xFF047857),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isCod
                              ? 'Pelunasan Tunai: Siapkan Rp ${_formatRupiah(booking.totalCost)} saat serah terima.'
                              : 'Pembayaran Lunas: Terverifikasi resmi sistem operasional.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCod ? const Color(0xFF1E40AF) : const Color(0xFF065F46),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Grid Ringkasan Reservasi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'Armada Kendaraan',
                        value: booking.vehicle.name,
                        subValue: 'Plat: ${booking.vehicle.plateNumber}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'Moda Sewa',
                        value: booking.modeLabel,
                        subValue: '${booking.durationDays} Hari Operasional',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'Waktu Penjemputan',
                        value: '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                        subValue: booking.startTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'Lokasi Penjemputan',
                        value: booking.pickupLocation,
                        subValue: 'Merauke, Papua Selatan',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Barcode / Verifikasi Digital Mockup
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 36, color: AppColors.primaryNavy),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kode Validasi Unit: VALID-MBJ-OK',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.withDriver && booking.assignedDriver != null
                                  ? 'Sopir Bertugas: ${booking.assignedDriver!.driverName}'
                                  : 'Serah Terima: Staf Kantor MobilJuragan',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOnlinePaymentSheet(BuildContext context, BookingModel booking) {
    int selectedTab = 0; // 0: QRIS, 1: Virtual Account
    String selectedBank = 'Bank BRI';
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final vaNumber = selectedBank == 'Bank BRI'
                ? '8801 2026 0043 18'
                : selectedBank == 'Bank BNI'
                    ? '9880 2026 0043 18'
                    : selectedBank == 'Bank Mandiri'
                        ? '8950 2026 0043 18'
                        : '1230 2026 0043 18';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pembayaran Otomatis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reservasi #${booking.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.schedule, size: 12, color: Color(0xFFB45309)),
                              SizedBox(width: 4),
                              Text(
                                '15:00',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Card Total Tagihan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                          ),
                          Text(
                            'Rp ${_formatRupiah(booking.totalCost)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Switcher (QRIS vs Virtual Account)
                    Container(
                      height: 42,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  selectedTab = 0;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selectedTab == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedTab == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'QRIS Dinamis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                    color: selectedTab == 0 ? AppColors.primaryNavy : AppColors.textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  selectedTab = 1;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selectedTab == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: selectedTab == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Virtual Account Bank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                    color: selectedTab == 1 ? AppColors.primaryNavy : AppColors.textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (selectedTab == 0) ...[
                      // Konten Tab QRIS
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'QRIS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'STANDAR PEMBAYARAN NASIONAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 140,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Scan dengan aplikasi perbankan atau e-wallet apa saja:\nBCA, BRI, Mandiri, Dana, GoPay, OVO, ShopeePay',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Inter',
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Kode QR berhasil disimpan ke galeri perangkat.'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: const Text('Simpan Kode QR', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderSubtle),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Konten Tab Virtual Account
                      const Text(
                        'Pilih Bank Tujuan Transfer',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Bank BRI', 'Bank BNI', 'Bank Mandiri', 'Bank BCA'].map((bank) {
                          final isBankSelected = selectedBank == bank;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    selectedBank = bank;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isBankSelected ? AppColors.primaryNavy : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isBankSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    bank.replaceFirst('Bank ', ''),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isBankSelected ? Colors.white : AppColors.textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nomor Virtual Account $selectedBank',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter'),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  vaNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: vaNumber.replaceAll(' ', '')));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Nomor Virtual Account $selectedBank berhasil disalin.'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: const Text('Salin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryTeal,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Atas Nama: MobilJuragan Merauke',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Tombol Aksi Verifikasi & Simulasi
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isVerifying
                            ? null
                            : () {
                                setSheetState(() {
                                  isVerifying = true;
                                });
                                Future.delayed(const Duration(milliseconds: 1400), () {
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    final controller = context.read<BookingController>();
                                    controller.completeOnlinePayment(
                                      bookingId: booking.id,
                                      paymentMethod: selectedTab == 0
                                          ? PaymentMethodType.qrisOtomatis
                                          : PaymentMethodType.virtualAccount,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        content: Text(
                                          'Pembayaran Rp ${_formatRupiah(booking.totalCost)} berhasil diverifikasi otomatis!',
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: isVerifying
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Memverifikasi Transaksi...', style: TextStyle(fontSize: 12)),
                                ],
                              )
                            : const Text(
                                'Cek Status Pembayaran (Otomatis)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tombol Simulasi Berhasil Instan (Khusus Demo PBL)
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          final controller = context.read<BookingController>();
                          controller.completeOnlinePayment(
                            bookingId: booking.id,
                            paymentMethod: selectedTab == 0
                                ? PaymentMethodType.qrisOtomatis
                                : PaymentMethodType.virtualAccount,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              content: const Text(
                                'Simulasi pembayaran berhasil! E-Ticket resmi telah terbit.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryTeal,
                          side: const BorderSide(color: AppColors.primaryTeal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Simulasikan Pembayaran Berhasil (Demo Sandbox)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCodConfirmationSheet(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      color: Color(0xFF047857),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Bayar di Tempat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pelunasan tunai saat serah terima unit di lokasi jemput.',
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
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 14),

              // Rincian Pembayaran Tunai
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pelunasan Tunai', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_formatRupiah(booking.totalCost)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryNavy, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Titik Serah Terima: ${booking.pickupLocation}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Ketentuan Serah Terima COD:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 8),
              _buildCodRuleItem(Icons.badge_outlined, 'Wajib menunjukkan fisik KTP elektronik asli sesuai nama pemesan.'),
              const SizedBox(height: 6),
              _buildCodRuleItem(Icons.card_membership_outlined, 'Wajib menunjukkan SIM A aktif untuk sewa lepas kunci.'),
              const SizedBox(height: 6),
              _buildCodRuleItem(Icons.payments_outlined, 'Menyiapkan uang tunai pas saat pemeriksaan fisik kendaraan bersama staf.'),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Batal / Ubah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        final controller = context.read<BookingController>();
                        controller.confirmCodPayment(booking.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            content: Text(
                              'Pesanan #${booking.id} dikonfirmasi COD. E-Ticket resmi telah terbit!',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Konfirmasi COD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCodRuleItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.primaryTeal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledBannerCard(BookingModel booking) {
    final isCod = booking.paymentMethodType == PaymentMethodType.tunaiDiTempat;
    final hasRefund = !isCod &&
        booking.cancellationRefundAmount != null &&
        booking.cancellationRefundAmount! > 0;
    final cancelledAtText = booking.cancelledAt != null
        ? '${booking.cancelledAt!.day.toString().padLeft(2, '0')}/${booking.cancelledAt!.month.toString().padLeft(2, '0')}/${booking.cancelledAt!.year}, ${booking.cancelledAt!.hour.toString().padLeft(2, '0')}.${booking.cancelledAt!.minute.toString().padLeft(2, '0')} WIT'
        : 'Waktu tidak tercatat';

    return Container(
      padding: const EdgeInsets.all(18),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 22,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reservasi Dibatalkan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Selesai Ditutup',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          cancelledAtText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          // Baris Alasan Pembatalan (Layout Rapi & Profesional)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 125,
                child: Text(
                  'Alasan Pembatalan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  booking.cancellationReason ?? 'Dibatalkan oleh pemesan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Penyelesaian Finansial (Ledger Box Profesional)
          if (isCod) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primaryNavy),
                      SizedBox(width: 6),
                      Text(
                        'Penyelesaian Finansial (COD)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Bebas Biaya',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Metode sewa adalah Tunai di Tempat (COD) dan pembayaran belum diserahkan ke tim lapangan. Tidak ada penalti dan tidak ada proses transfer dana (Refund Rp 0).',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasRefund) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.primaryTeal),
                      SizedBox(width: 6),
                      Text(
                        'Rincian Pengembalian Dana',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Telah Dibayar',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter'),
                      ),
                      Text(
                        'Rp ${_formatRupiah(booking.totalCost)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Potongan Operasional (15%)',
                        style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontFamily: 'Inter'),
                      ),
                      Text(
                        '-Rp ${_formatRupiah(booking.totalCost - booking.cancellationRefundAmount!)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626), fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dana Dikembalikan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534), fontFamily: 'Inter'),
                      ),
                      Text(
                        'Rp ${_formatRupiah(booking.cancellationRefundAmount!)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF15803D), fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekening Tujuan: ${booking.cancellationBank ?? "-"} • ${booking.cancellationAccountNumber ?? "-"}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1F2937), fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atas Nama: ${booking.cancellationAccountName ?? "-"}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: Color(0xFF0D9488)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Status: Sedang diproses oleh staf finance (Estimasi 1x24 jam kerja).',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF0F766E), fontFamily: 'Inter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pesanan dibatalkan sebelum pembayaran dilakukan. Tidak ada tagihan atau potongan yang timbul.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kartu Bantuan Layanan Khusus Pesanan Dibatalkan
  Widget _buildCancelledAssistanceCard(BuildContext context, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butuh Bantuan atau Jadwal Baru?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Konsultasikan tanggal pengganti atau unit armada lainnya bersama tim CS MobilJuragan.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatSupportScreen(booking: booking),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: const BorderSide(color: AppColors.primaryTeal),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Chat CS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancellationBottomSheet(BuildContext context, BookingModel booking) {
    final isCod = booking.paymentMethodType == PaymentMethodType.tunaiDiTempat;
    final isPaid = !isCod &&
        (booking.status == BookingStatus.pembayaranSelesai ||
            booking.status == BookingStatus.verifikasiKantor ||
            booking.status == BookingStatus.mobilSiapDigunakan);

    final refundAmount = isPaid ? (booking.totalCost * 0.85).round() : 0;
    final penaltyAmount = isPaid ? (booking.totalCost - refundAmount) : 0;

    String selectedReason = 'Perubahan rencana atau jadwal perjalanan';
    final customReasonController = TextEditingController();
    final bankController = TextEditingController(text: 'Bank BRI');
    final accNumberController = TextEditingController();
    final accNameController = TextEditingController();

    final List<String> reasonOptions = [
      'Perubahan rencana atau jadwal perjalanan',
      'Salah memilih tanggal, jam, atau lokasi sewa',
      'Ingin mengganti unit mobil atau moda sewa',
      'Menemukan alternatif transportasi lain',
      'Alasan lainnya',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isOtherSelected = selectedReason == 'Alasan lainnya';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primaryNavy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPaid
                                    ? 'Ajukan Pembatalan & Refund'
                                    : (isCod ? 'Batalkan Reservasi COD' : 'Batalkan Pesanan'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kode Reservasi: ${booking.id}',
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
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 14),

                    // Ketentuan Pembatalan COD vs Refund Online
                    if (isCod) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: AppColors.primaryNavy),
                                SizedBox(width: 6),
                                Text(
                                  'Ketentuan Pembatalan COD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Karena metode pembayaran adalah Tunai di Tempat (COD) dan pembayaran sewa belum diserahkan, reservasi ini dibatalkan tanpa penalti dan tanpa pengembalian dana (Refund Rp 0). Anda tidak perlu mengisi data rekening bank.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (isPaid) ...[
                      // Transparansi Kebijakan Refund 85% jika sudah bayar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: AppColors.primaryTeal),
                                SizedBox(width: 6),
                                Text(
                                  'Ketentuan Pengembalian Dana',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Pengembalian dana dipotong penalti kompensasi operasional sebesar 15% dari total pembayaran yang masuk.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pembayaran:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
                                Text('Rp ${_formatRupiah(booking.totalCost)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Penalti Kompensasi (15%):', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontFamily: 'Inter')),
                                Text('-Rp ${_formatRupiah(penaltyAmount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626), fontFamily: 'Inter')),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estimasi Dana Dikembalikan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534), fontFamily: 'Inter')),
                                Text('Rp ${_formatRupiah(refundAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF166534), fontFamily: 'Inter')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Rekening Tujuan Pengembalian Dana',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: bankController,
                        decoration: InputDecoration(
                          labelText: 'Nama Bank / E-Wallet',
                          hintText: 'Contoh: Bank BRI / BCA / Bank Papua',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: accNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nomor Rekening',
                          hintText: 'Masukkan nomor rekening tujuan',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: accNameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Pemilik Rekening',
                          hintText: 'Sesuai buku tabungan / identitas',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Pilih Alasan Pembatalan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...reasonOptions.map((reason) {
                      final isSelected = selectedReason == reason;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedReason = reason;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryNavy
                                        : AppColors.textSecondary.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    if (isOtherSelected) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: customReasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan alasan spesifik pembatalan Anda...',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderSubtle),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Tetap Lanjutkan',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final finalReason = isOtherSelected && customReasonController.text.trim().isNotEmpty
                                  ? customReasonController.text.trim()
                                  : selectedReason;

                              if (isPaid) {
                                if (bankController.text.trim().isEmpty ||
                                    accNumberController.text.trim().isEmpty ||
                                    accNameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lengkapi informasi rekening pengembalian dana terlebih dahulu.'),
                                      backgroundColor: Color(0xFFDC2626),
                                    ),
                                  );
                                  return;
                                }
                              }

                              Navigator.pop(sheetContext);

                              final controller = context.read<BookingController>();
                              controller.cancelBooking(
                                bookingId: booking.id,
                                reason: finalReason,
                                bankName: isPaid ? bankController.text.trim() : null,
                                accountNumber: isPaid ? accNumberController.text.trim() : null,
                                accountHolderName: isPaid ? accNameController.text.trim() : null,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  content: Text(
                                    isPaid
                                        ? 'Pengajuan pembatalan & refund berhasil dikirim.'
                                        : (isCod
                                            ? 'Reservasi COD ${booking.id} berhasil dibatalkan tanpa penalti.'
                                            : 'Pesanan ${booking.id} berhasil dibatalkan.'),
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              isPaid ? 'Konfirmasi Refund' : 'Ya, Batalkan',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingModel booking) {
    final isCancelled = booking.status == BookingStatus.dibatalkan;
    final isWaitingPayment = booking.status == BookingStatus.menungguPembayaran;
    final isPaid = booking.status == BookingStatus.pembayaranSelesai ||
        booking.status == BookingStatus.verifikasiKantor ||
        booking.status == BookingStatus.mobilSiapDigunakan;

    if (isCancelled) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final controller = context.read<BookingController>();
                controller.selectVehicle(booking.vehicle);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DateTimeScreen(vehicle: booking.vehicle),
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: const Text(
                'Pesan Ulang Mobil Ini',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (isWaitingPayment) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentMethodPickerSheet(context, booking),
              icon: const Icon(Icons.payment_rounded, size: 18, color: Colors.white),
              label: Text(
                'Bayar Sekarang • Rp ${_formatRupiah(booking.totalCost)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ] else if (isPaid) ...[
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
              icon: const Icon(Icons.support_agent_rounded, size: 19, color: Colors.white),
              label: const Text(
                'Koordinasi Penjemputan via Chat CS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'E-Ticket resmi telah aktif. Diskusikan rincian penjemputan dengan tim lapangan.',
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
          child: isWaitingPayment || isPaid
              ? OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                )
              : ElevatedButton(
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
        if (booking.status != BookingStatus.selesai) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showCancellationBottomSheet(context, booking),
              icon: Icon(
                isPaid ? Icons.undo_rounded : Icons.close_rounded,
                size: 15,
                color: const Color(0xFF64748B),
              ),
              label: Text(
                isPaid ? 'Ajukan Pembatalan & Refund' : 'Batalkan Pesanan Ini',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  fontFamily: 'Inter',
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
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
        return const Color(0xFFF1F5F9);
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
        return const Color(0xFF475569);
    }
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
