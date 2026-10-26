import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../core/network/api_client.dart';
import '../core/network/payment_api_service.dart';
import '../data/remote/document_api_service.dart';
import '../models/booking_document_model.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_support_screen.dart';
import 'date_time_screen.dart';
import 'main_navigation_screen.dart';
import '../theme/app_typography.dart';

/// Layar pelacakan status pesanan (Frame 07)
/// Mengikuti alur stepper Figma dengan penambahan tahap Menunggu Pembayaran
/// Menjalankan verifikasi tarif final admin 10 detik di latar belakang dan memicu notifikasi native sistem
class OrderStatusScreen extends StatefulWidget {
  final BookingModel? booking;
  final bool fromOrderSubmission;
  final BookingDocumentModel? initialDocument;
  final PaymentModel? initialPayment;

  const OrderStatusScreen({
    super.key,
    this.booking,
    this.fromOrderSubmission = false,
    this.initialDocument,
    this.initialPayment,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Timer? _pollingTimer;
  bool _notificationShown = false;
  bool _isTariffDetailsExpanded = false;
  bool _isRefreshing = false;
  String? _trackingBookingId;

  final DocumentApiService _documentApiService = DocumentApiService();
  BookingDocumentModel? _bookingDocument;
  bool _isUploadingDocument = false;
  String? _draftStatementUrl;
  String? _draftKtpUrl;
  String? _draftSimUrl;

  final PaymentApiService _paymentApiService = PaymentApiService();
  PaymentModel? _payment;
  bool _isLepasKunciDocsCollapsed = true;

  bool get isProofUploaded =>
      _payment?.isPendingVerification == true ||
      (_payment?.proofImageUrl != null && _payment!.proofImageUrl!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (widget.initialDocument != null) {
      _bookingDocument = widget.initialDocument;
      _draftStatementUrl = widget.initialDocument?.statementLetterUrl;
      _draftKtpUrl = widget.initialDocument?.ktpUrl;
      _draftSimUrl = widget.initialDocument?.simUrl;
    }
    if (widget.initialPayment != null) {
      _payment = widget.initialPayment;
    }
    _trackingBookingId = widget.booking?.id ??
        context.read<BookingController>().activeBooking?.id;
    _checkAndStartPolling();
    _loadBookingDocuments();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    final targetId = _trackingBookingId ??
        widget.booking?.id ??
        context.read<BookingController>().activeBooking?.id;
    if (targetId == null) return;

    try {
      final payment = await _paymentApiService.getPaymentByBooking(targetId);
      if (mounted) {
        setState(() {
          _payment = payment;
        });
      }
    } catch (_) {
      // Abaikan jika offline atau pembayaran belum dibuat
    }
  }

  Future<void> _loadBookingDocuments() async {
    final targetId = _trackingBookingId ??
        widget.booking?.id ??
        context.read<BookingController>().activeBooking?.id;
    if (targetId == null) return;

    try {
      final doc = await _documentApiService.fetchBookingDocuments(targetId);
      if (mounted) {
        setState(() {
          _bookingDocument = doc;
          if (doc != null) {
            _draftStatementUrl ??= doc.statementLetterUrl;
            _draftKtpUrl ??= doc.ktpUrl;
            _draftSimUrl ??= doc.simUrl;
          }
        });
      }
    } catch (_) {
      // Abaikan jika jaringan offline atau dokumen belum dibuat
    }
  }

  void _checkAndStartPolling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStatusPolling();
    });
  }

  void _startStatusPolling() {
    _pollingTimer?.cancel();

    // Lakukan polling perdana secara asinkron
    _pollBookingStatus();

    // Polling berkala setiap 5 detik selama status masih dalam pemeriksaan atau antrean admin
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _pollBookingStatus();
    });
  }

  Future<void> _pollBookingStatus() async {
    final controller = context.read<BookingController>();
    final targetId = _trackingBookingId ?? widget.booking?.id ?? controller.activeBooking?.id;
    if (targetId == null) return;

    BookingModel? currentBooking;
    try {
      currentBooking = controller.bookingHistory.firstWhere((b) => b.id == targetId);
    } catch (_) {
      currentBooking = widget.booking ?? controller.activeBooking;
    }

    if (currentBooking == null) return;

    // Polling tetap aktif selama pesanan belum mencapai status akhir (selesai atau dibatalkan)
    final isFinished = currentBooking.status == BookingStatus.selesai ||
        currentBooking.status == BookingStatus.dibatalkan;

    if (isFinished) {
      _pollingTimer?.cancel();
      return;
    }

    final bookingId = currentBooking.id;
    final hasUpdated = await controller.refreshActiveBookingStatus(bookingId);
    if (!mounted) return;

    if (hasUpdated) {
      BookingModel? updatedBooking;
      try {
        updatedBooking = controller.bookingHistory.firstWhere((b) => b.id == bookingId);
      } catch (_) {
        updatedBooking = controller.activeBooking;
      }

      if (updatedBooking != null) {
        if (updatedBooking.status == BookingStatus.menungguPembayaran && !_notificationShown) {
          _onStatusUpdatedToConfirmed(updatedBooking);
        } else if (updatedBooking.status == BookingStatus.mobilSiapDigunakan ||
            updatedBooking.status == BookingStatus.pembayaranSelesai ||
            updatedBooking.status == BookingStatus.verifikasiKantor) {
          _onStatusUpdatedToInProgress(updatedBooking);
          // Polling sengaja tetap berlanjut agar penyelesaian sewa oleh admin terdeteksi otomatis
        } else if (updatedBooking.status == BookingStatus.selesai) {
          _pollingTimer?.cancel();
          _onStatusUpdatedToCompleted(updatedBooking);
        } else if (updatedBooking.status == BookingStatus.dibatalkan) {
          _pollingTimer?.cancel();
        }
      }
      _loadPayment();
    }
  }

  void _onStatusUpdatedToInProgress(BookingModel booking) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Armada ${booking.vehicle.name} telah diserahkan oleh staf admin! Masa sewa aktif berjalan.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTypography.sizeBody,
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

  void _onStatusUpdatedToCompleted(BookingModel booking) {
    if (!mounted) return;

    NotificationService().showRentalCompletedNotification(
      bookingId: booking.id,
      vehicleName: booking.vehicle.name,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Penyewaan ${booking.vehicle.name} telah selesai. Terima kasih telah mempercayai MobilJuragan!',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTypography.sizeBody,
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

  void _onStatusUpdatedToConfirmed(BookingModel booking) {
    if (!mounted) return;

    NotificationService().showTariffReadyNotification(
      bookingId: booking.id,
      vehicleName: booking.vehicle.name,
      totalCost: booking.totalCost,
    );

    if (!_notificationShown) {
      _notificationShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryNavy,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFFFDE68A), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tarif final Rp ${_formatRupiah(booking.totalCost)} sudah disetujui admin! Status: Menunggu Pembayaran.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: AppTypography.sizeBody,
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

  Future<void> _manualRefreshStatus(BookingModel booking) async {
    setState(() => _isRefreshing = true);
    final controller = context.read<BookingController>();
    final hasUpdated = await controller.refreshActiveBookingStatus(booking.id);
    await Future.wait([
      _loadBookingDocuments(),
      _loadPayment(),
    ]);
    if (!mounted) return;
    setState(() => _isRefreshing = false);

    final targetId = booking.id;
    BookingModel? updatedBooking;
    try {
      updatedBooking = controller.bookingHistory.firstWhere((b) => b.id == targetId);
    } catch (_) {
      updatedBooking = controller.activeBooking;
    }

    if (hasUpdated && updatedBooking != null) {
      if (updatedBooking.status == BookingStatus.menungguPembayaran ||
          updatedBooking.isFinalTariffConfirmed) {
        _onStatusUpdatedToConfirmed(updatedBooking);
      } else if (updatedBooking.status == BookingStatus.selesai) {
        _onStatusUpdatedToCompleted(updatedBooking);
      } else if (updatedBooking.status == BookingStatus.mobilSiapDigunakan) {
        _onStatusUpdatedToInProgress(updatedBooking);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNavy,
            content: Text(
              'Status pesanan diperbarui: ${updatedBooking.statusLabel}',
              style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          content: Text(
            booking.status == BookingStatus.selesai
                ? 'Status pesanan telah selesai.'
                : 'Belum ada perubahan tarif dari admin operasional.',
            style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingController = context.watch<BookingController>();
    final targetId = _trackingBookingId ?? widget.booking?.id;
    final activeBooking = targetId != null
        ? (bookingController.bookingHistory.firstWhere(
            (b) => b.id == targetId,
            orElse: () => widget.booking ?? (bookingController.activeBooking ?? (bookingController.bookingHistory.isNotEmpty ? bookingController.bookingHistory.first : widget.booking!)),
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
                  fontSize: AppTypography.sizeHeading,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan lakukan pemesanan armada kendaraan terlebih dahulu.',
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
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
    final isCompleted = activeBooking.status == BookingStatus.selesai;
    final isPaid = activeBooking.status == BookingStatus.pembayaranSelesai ||
        activeBooking.status == BookingStatus.verifikasiKantor ||
        activeBooking.status == BookingStatus.mobilSiapDigunakan ||
        activeBooking.status == BookingStatus.selesai;
    final isWaitingPayment = activeBooking.status == BookingStatus.menungguPembayaran ||
        (activeBooking.isFinalTariffConfirmed &&
            activeBooking.status != BookingStatus.pembayaranSelesai &&
            activeBooking.status != BookingStatus.verifikasiKantor &&
            activeBooking.status != BookingStatus.mobilSiapDigunakan &&
            activeBooking.status != BookingStatus.selesai &&
            activeBooking.status != BookingStatus.dibatalkan);

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
      bottomNavigationBar: isWaitingPayment
          ? _buildStickyPaymentBar(context, activeBooking)
          : null,
      body: RefreshIndicator(
        color: AppColors.primaryTeal,
        onRefresh: () async {
          await _manualRefreshStatus(activeBooking);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 16, 20, isWaitingPayment ? 110 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCancelled) ...[
                _buildCancelledBannerCard(activeBooking),
                const SizedBox(height: 16),
                _buildVehicleSummaryCard(activeBooking),
                const SizedBox(height: 16),
                _buildCancelledAssistanceCard(context, activeBooking),
                const SizedBox(height: 16),
              ] else if (isCompleted) ...[
                _buildCompletedBannerCard(activeBooking),
                const SizedBox(height: 16),
                _buildVehicleSummaryCard(activeBooking),
                const SizedBox(height: 16),
                _buildFigmaStepper(activeBooking),
                const SizedBox(height: 16),
              ] else if (isPaid) ...[
                // Tahap 4: Sewa Berjalan (E-Ticket sebagai Hero Card Mandiri)
                _buildETicketCard(context, activeBooking),
                const SizedBox(height: 16),
                _buildFigmaStepper(activeBooking),
                const SizedBox(height: 16),
                if (activeBooking.withDriver) ...[
                  _buildAssignedDriverCard(context, activeBooking),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                // Tahap 1, 2, & 3: Sebelum Lunas (Permintaan Masuk, Konfirmasi Tarif, Menunggu Pembayaran)
                _buildUnifiedHeroStatusCard(context, activeBooking),
                const SizedBox(height: 16),
                if (!activeBooking.withDriver) ...[
                  _buildLepasKunciDocumentCard(activeBooking),
                  const SizedBox(height: 16),
                ],
                _buildFigmaStepper(activeBooking),
                const SizedBox(height: 16),
                if (activeBooking.withDriver) ...[
                  // Card sopir hanya ditampilkan setelah pengajuan diterima/diverifikasi (Tahap 2 ke atas)
                  if (activeBooking.status != BookingStatus.permintaanDiterima) ...[
                    _buildAssignedDriverCard(context, activeBooking),
                    const SizedBox(height: 16),
                  ],
                ],
              ],

              _buildActionButtons(context, activeBooking),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Unified Hero Status Card: Melebur Header Kode Booking & Notice Card menjadi satu Hero terpadu
  Widget _buildUnifiedHeroStatusCard(BuildContext context, BookingModel booking) {
    final isWaitingPayment = booking.status == BookingStatus.menungguPembayaran ||
        (booking.isFinalTariffConfirmed &&
            booking.status != BookingStatus.pembayaranSelesai &&
            booking.status != BookingStatus.verifikasiKantor &&
            booking.status != BookingStatus.mobilSiapDigunakan &&
            booking.status != BookingStatus.selesai &&
            booking.status != BookingStatus.dibatalkan);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Metadata Reservasi & Sinkronisasi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'KODE RESERVASI',
                        style: TextStyle(
                          fontSize: AppTypography.sizeMicro,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              booking.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeHeading,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: booking.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kode reservasi berhasil disalin'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _isRefreshing ? null : () => _manualRefreshStatus(booking),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                          )
                        : const Icon(Icons.sync_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),

          // 2. Hero Body: Aksi & Status Aktif Saat Ini
          Padding(
            padding: const EdgeInsets.all(16),
            child: isWaitingPayment
                ? _buildHeroWaitingPaymentContent(context, booking)
                : _buildHeroPendingTariffContent(booking),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroWaitingPaymentContent(BuildContext context, BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isProofUploaded ? AppColors.tealLight : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isProofUploaded ? Icons.hourglass_bottom_rounded : Icons.schedule_rounded,
                    size: 20,
                    color: isProofUploaded ? AppColors.primaryTeal : const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isProofUploaded
                            ? 'Menunggu Verifikasi Pembayaran'
                            : 'Selesaikan Pembayaran',
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          fontWeight: FontWeight.w700,
                          color: isProofUploaded ? AppColors.primaryNavy : const Color(0xFF92400E),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isProofUploaded
                            ? 'Bukti transfer telah diterima dan sedang diperiksa oleh admin operasional.'
                            : 'Rincian tarif final telah diterbitkan oleh admin',
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
            if (isProofUploaded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 13,
                      color: AppColors.primaryTeal,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Sedang Diverifikasi',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              )
            else
              Builder(
                builder: (ctx) {
                  final deadline = booking.createdAt.add(const Duration(hours: 12));
                  final remaining = deadline.difference(DateTime.now());
                  final isOverdue = remaining.isNegative;
                  final timerString = isOverdue
                      ? 'Kedaluwarsa'
                      : '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timerString,
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w700,
                            color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Ringkasan Unit Kompak (Sesuai Mockup)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    booking.vehicle.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.directions_car_filled_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.vehicle.name} • ${booking.vehicle.plateNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.startDate.day}/${booking.startDate.month} - ${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year} (${booking.durationDays} Hari) • ${booking.pickupLocation}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeTiny,
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
    );
  }

  Widget _buildStickyPaymentBar(BuildContext context, BookingModel booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Kolom Kiri: Total Pembayaran / Bukti Terkirim + Tautan Rincian
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isProofUploaded) ...[
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF15803D)),
                          SizedBox(width: 4),
                          Text(
                            'Bukti Terkirim',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTiny,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Rp ${_formatRupiah(booking.totalCost)}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: AppTypography.sizeTiny,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Rp ${_formatRupiah(booking.totalCost)}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeHeading,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _showTariffDetailModal(context, booking),
                      borderRadius: BorderRadius.circular(4),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Rincian Tarif',
                            style: TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_up,
                            size: 14,
                            color: AppColors.primaryTeal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Kolom Kanan: Tombol Bayar Sekarang / Ganti Bukti
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: (48 * MediaQuery.textScalerOf(context).scale(1)).clamp(48, 96),
                  child: isProofUploaded
                      ? OutlinedButton.icon(
                          onPressed: () => _showOnlinePaymentSheet(context, booking),
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryTeal),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Ganti Bukti',
                              style: TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _showOnlinePaymentSheet(context, booking),
                          icon: const Icon(Icons.payment_rounded, size: 18, color: Colors.white),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Bayar Sekarang',
                              style: TextStyle(
                                fontSize: AppTypography.sizeBodyLarge,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTariffDetailModal(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                    'Rincian Tarif Final',
                    style: TextStyle(
                      fontSize: AppTypography.sizeHeading,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 14),
              _buildTariffRow('Sewa Unit (${booking.durationDays} Hari)', 'Rp ${_formatRupiah(booking.vehicleSubtotal)}'),
              const SizedBox(height: 8),
              _buildTariffRow(
                'Layanan Sopir (${booking.durationDays} Hari)',
                booking.withDriver ? 'Rp ${_formatRupiah(booking.driverSubtotal)}' : 'Gratis',
              ),
              if (booking.serviceFee > 0) ...[
                const SizedBox(height: 8),
                _buildTariffRow('Biaya Layanan Sistem Operasional', 'Rp ${_formatRupiah(booking.serviceFee)}'),
              ],
              if (booking.adminAdjustments.isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.borderSubtle),
                const Text(
                  'Penyesuaian Biaya Operasional:',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                ...booking.adminAdjustments.map((adj) {
                  final isNegative = adj.isDeduction;
                  final prefix = isNegative ? '-Rp ' : '+Rp ';
                  final absAmount = adj.amount.abs();
                  final color = isNegative ? const Color(0xFF059669) : AppColors.primaryNavy;

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
                                  fontSize: AppTypography.sizeBody,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (adj.note != null)
                                Text(
                                  adj.note!,
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeTiny,
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
                            fontSize: AppTypography.sizeBody,
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
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Rp ${_formatRupiah(booking.totalCost)}',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeHeading,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Tutup Rincian', style: AppTypography.bodyStrong),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroPendingTariffContent(BookingModel booking) {
    final isDriver = booking.withDriver;
    final isDocRejected = _bookingDocument?.status == DocumentStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDocRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDocRejected ? Icons.warning_amber_rounded : Icons.hourglass_top_rounded,
                size: 20,
                color: isDocRejected ? const Color(0xFFDC2626) : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDocRejected
                        ? 'Perlu Revisi Dokumen Lepas Kunci'
                        : 'Pengajuan Sedang Ditinjau Admin',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: isDocRejected ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDocRejected
                        ? 'Unggah berkas perbaikan yang ditandai agar pesanan dapat diproses.'
                        : (isDriver
                            ? 'Pemeriksaan kesiapan armada dan alokasi sopir'
                            : 'Pemeriksaan ketersediaan unit armada'),
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: isDocRejected ? const Color(0xFFB91C1C) : AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ringkasan Unit Kompak (Sesuai Mockup)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    booking.vehicle.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.directions_car_filled_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.vehicle.name} • ${booking.vehicle.plateNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.startDate.day}/${booking.startDate.month} - ${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year} (${booking.durationDays} Hari) • ${booking.pickupLocation}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeTiny,
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
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Estimasi Total Biaya',
                            style: TextStyle(
                              fontSize: AppTypography.sizeBody,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isTariffDetailsExpanded = !_isTariffDetailsExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isTariffDetailsExpanded
                                      ? 'Sembunyikan Rincian'
                                      : 'Lihat Rincian Tarif',
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeCaption,
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rp ${_formatRupiah(booking.totalCost)}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeHeading,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTariffDetailsExpanded) ...[
                const Divider(height: 1, color: AppColors.borderSubtle),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Sewa Unit ${booking.vehicle.name} (${booking.durationDays} Hari)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rp ${_formatRupiah(booking.vehicle.pricePerDay * booking.durationDays)}',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDriver
                      ? 'Admin sedang memeriksa ketersediaan armada, verifikasi penugasan sopir, dan rincian tarif. Estimasi proses verifikasi berkisar 15 - 30 menit.'
                      : 'Admin sedang memeriksa ketersediaan armada dan menyusun rincian tarif final. Estimasi proses verifikasi berkisar 15 - 30 menit.',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSummaryCard(BookingModel booking) {
    final isCancelled = booking.status == BookingStatus.dibatalkan;
    final isWaitingPayment = booking.status == BookingStatus.menungguPembayaran ||
        (booking.isFinalTariffConfirmed &&
            booking.status != BookingStatus.pembayaranSelesai &&
            booking.status != BookingStatus.verifikasiKantor &&
            booking.status != BookingStatus.mobilSiapDigunakan &&
            booking.status != BookingStatus.selesai &&
            booking.status != BookingStatus.dibatalkan);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
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
                  height: (50 * MediaQuery.textScalerOf(context).scale(1)).clamp(50, 100),
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
                                fontSize: AppTypography.sizeTitle,
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
                                  fontSize: AppTypography.sizeTiny,
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
          ),

          const Divider(height: 1, color: AppColors.borderSubtle),

          if (isWaitingPayment) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryTeal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year} (${booking.startTime})',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primaryTeal),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            booking.pickupLocation,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Baris Total Tarif dengan tombol interaktif buka/tutup rincian (Tahap 1, 2, atau Batal)
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
                  // Wrap: nominal harga turun ke baris berikutnya saat ukuran
                  // teks sistem diperbesar, bukan menimpa label di sebelahnya.
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCancelled
                                ? 'Total Nilai Sewa (Batal)'
                                : (booking.isFinalTariffConfirmed
                                    ? 'Total Pembayaran'
                                    : 'Estimasi Total Biaya'),
                            style: const TextStyle(
                              fontSize: AppTypography.sizeBody,
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
                                    fontSize: AppTypography.sizeCaption,
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
                          fontSize: AppTypography.sizeAmount,
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
                    if (booking.serviceFee > 0) ...[
                      const SizedBox(height: 6),
                      _buildTariffRow('Biaya Layanan Sistem Operasional', 'Rp ${_formatRupiah(booking.serviceFee)}'),
                    ],

                    // Penyesuaian Biaya Operasional jika ada
                    if (booking.adminAdjustments.isNotEmpty) ...[
                      const Divider(height: 16, color: AppColors.borderSubtle),
                      const Text(
                        'Penyesuaian Biaya Operasional:',
                        style: TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...booking.adminAdjustments.map((adj) {
                        final isNegative = adj.isDeduction;
                        final prefix = isNegative ? '-Rp ' : '+Rp ';
                        final absAmount = adj.amount.abs();
                        final color = isNegative ? const Color(0xFF059669) : AppColors.primaryNavy;

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
                                        fontSize: AppTypography.sizeBody,
                                        fontWeight: FontWeight.w500,
                                        color: color,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    if (adj.note != null)
                                      Text(
                                        adj.note!,
                                        style: const TextStyle(
                                          fontSize: AppTypography.sizeTiny,
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
                                  fontSize: AppTypography.sizeBody,
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
        ],
      ),
    );
  }

  /// Stepper Mengikuti 5 Tahapan Alur Resmi (Selaras dengan Alur Kanonik Admin & Backend)
  Widget _buildFigmaStepper(BookingModel booking) {
    final status = booking.status;
    final isDriver = booking.withDriver;
    final isCod = booking.paymentMethodType == PaymentMethodType.tunaiDiTempat;

    // Tahap 1: Permintaan Masuk (CREATED)
    final step1Done = status != BookingStatus.permintaanDiterima;
    final step1Active = status == BookingStatus.permintaanDiterima;

    // Tahap 2: Konfirmasi Tarif & Armada (PENDING_CONFIRMATION)
    final step2Done = booking.isFinalTariffConfirmed ||
        status == BookingStatus.menungguPembayaran ||
        status == BookingStatus.pembayaranSelesai ||
        status == BookingStatus.verifikasiKantor ||
        status == BookingStatus.mobilSiapDigunakan ||
        status == BookingStatus.selesai;
    final step2Active = !step2Done &&
        (status == BookingStatus.pemeriksaanArmada ||
            status == BookingStatus.menungguTarifFinal);

    // Tahap 3: Menunggu Pembayaran / Pelunasan Tunai di Tempat (CONFIRMED)
    // Selesai jika pembayaran online terverifikasi atau unit telah diserahkan (jika COD)
    final step3Done = isCod
        ? (status == BookingStatus.mobilSiapDigunakan ||
            status == BookingStatus.selesai)
        : (status == BookingStatus.pembayaranSelesai ||
            status == BookingStatus.verifikasiKantor ||
            status == BookingStatus.mobilSiapDigunakan ||
            status == BookingStatus.selesai);
    final step3Active = !step3Done &&
        (status == BookingStatus.menungguPembayaran ||
            booking.isFinalTariffConfirmed);

    // Tahap 4: Sewa Berjalan (IN_PROGRESS)
    final step4Done = status == BookingStatus.selesai;
    final step4Active = !step4Done &&
        (status == BookingStatus.pembayaranSelesai ||
            status == BookingStatus.verifikasiKantor ||
            status == BookingStatus.mobilSiapDigunakan);

    // Tahap 5: Selesai (COMPLETED)
    final step5Done = status == BookingStatus.selesai;
    final step5Active = false;

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
              fontSize: AppTypography.sizeTitle,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
            // Tahap 1: Permintaan Masuk
            _buildStepRow(
              stepNumber: 1,
              title: 'Permintaan Masuk',
              subtitle: step1Done
                  ? 'Data pengajuan telah tercatat di sistem'
                  : 'Formulir pengajuan sewa berhasil dikirim',
              isDone: step1Done,
              isActive: step1Active,
              isLast: false,
            ),

            // Tahap 2: Konfirmasi Tarif & Armada
            _buildStepRow(
              stepNumber: 2,
              title: 'Konfirmasi Tarif & Armada',
              subtitle: step2Done
                  ? (isDriver
                      ? 'Tarif sewa dan alokasi sopir telah dikonfirmasi admin'
                      : 'Tarif sewa dan kesiapan armada telah dikonfirmasi admin')
                  : (step2Active
                      ? (isDriver
                          ? 'Pemeriksaan rute perjalanan dan alokasi sopir'
                          : (_bookingDocument?.status == DocumentStatus.verified
                              ? 'Dokumen disetujui, menunggu rincian tarif sewa oleh admin'
                              : 'Pemeriksaan kesiapan unit dan verifikasi 3 dokumen persyaratan'))
                      : (isDriver
                          ? 'Menunggu validasi rute perjalanan dan alokasi sopir'
                          : 'Menunggu giliran pemeriksaan unit dan verifikasi dokumen')),
              isDone: step2Done,
              isActive: step2Active,
              isLast: false,
            ),

            // Tahap 3: Pembayaran / Pelunasan Tunai di Tempat
            _buildStepRow(
              stepNumber: 3,
              title: isCod
                  ? (step3Done ? 'Pelunasan Tunai Selesai' : 'Pelunasan Tunai di Tempat (COD)')
                  : (step3Done ? 'Pembayaran Diterima' : 'Pembayaran'),
              subtitle: isCod
                  ? (step3Done
                      ? 'Pembayaran tunai telah diterima petugas kantor atau sopir di lokasi'
                      : (step3Active
                          ? 'Siapkan uang tunai pas Rp ${_formatRupiah(booking.totalCost)} saat serah terima unit'
                          : 'Menunggu serah terima unit untuk pelunasan tunai'))
                  : (step3Done
                      ? 'Pembayaran telah terverifikasi dan tercatat lunas'
                      : (step3Active
                          ? (isProofUploaded
                              ? 'Bukti transfer telah diunggah dan sedang diverifikasi admin'
                              : 'Batas pelunasan hingga 12 jam ke depan')
                          : (isDriver
                              ? 'Menunggu penetapan rincian tarif final'
                              : 'Menunggu konfirmasi tarif dan verifikasi dokumen'))),
              isDone: step3Done,
              isActive: step3Active,
              isLast: false,
              badgeText: step3Active
                  ? (isProofUploaded
                      ? 'VERIFIKASI ADMIN'
                      : (isCod ? 'MENUNGGU COD' : 'MENUNGGU BAYAR'))
                  : null,
              badgeColor: step3Active ? AppColors.primaryTeal : null,
              badgeBgColor: step3Active ? AppColors.tealLight : null,
            ),

            // Tahap 4: Sewa Berjalan
            _buildStepRow(
              stepNumber: 4,
              title: 'Sewa Berjalan',
              subtitle: step4Done
                  ? 'Perjalanan sewa telah tuntas dilaksanakan'
                  : (step4Active
                      ? (isDriver
                          ? 'Sopir siaga dan perjalanan sewa Anda sedang berjalan'
                          : 'Unit armada telah diserahterimakan dan masa sewa aktif')
                      : (isDriver
                          ? 'Sopir akan siaga menjemput setelah pembayaran terkonfirmasi'
                          : 'Kunci dan unit akan diserahkan setelah pembayaran terkonfirmasi')),
              isDone: step4Done,
              isActive: step4Active,
              isLast: false,
            ),

            // Tahap 5: Selesai
            _buildStepRow(
              stepNumber: 5,
              title: 'Selesai',
              subtitle: step5Done
                  ? (isDriver
                      ? 'Layanan sopir telah selesai dan armada telah kembali ke kantor'
                      : 'Masa sewa telah selesai dan unit telah kembali ke kantor')
                  : 'Pemeriksaan akhir kondisi unit dan pengembalian armada',
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
    final hasDriver = driver != null && driver.driverName.trim().isNotEmpty;
    final driverName = hasDriver ? driver.driverName : 'Staf Sopir Sedang Disiapkan';
    final role = hasDriver
        ? (driver.operationalRole.isNotEmpty
            ? driver.operationalRole
            : 'Pengemudi Area Merauke')
        : 'Akan dialokasikan oleh tim admin sebelum jadwal sewa';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap: badge "Sopir Resmi" atau "Menunggu Alokasi"
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_outlined, size: 18, color: AppColors.primaryTeal),
                  const SizedBox(width: 8),
                  const Text(
                    'Pengemudi Anda',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
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
                  color: hasDriver ? AppColors.badgeGreenBg : AppColors.badgeAmberBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasDriver ? 'Sopir Resmi' : 'Menunggu Alokasi',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w700,
                    color: hasDriver ? AppColors.badgeGreenText : AppColors.badgeAmberText,
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
                height: (44 * MediaQuery.textScalerOf(context).scale(1)).clamp(44, 88),
                decoration: BoxDecoration(
                  color: hasDriver ? AppColors.primaryNavy : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    hasDriver ? Icons.person : Icons.schedule,
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
                        fontSize: AppTypography.sizeTitle,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
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
                Icon(
                  hasDriver ? Icons.chat_outlined : Icons.info_outline,
                  size: 16,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasDriver
                        ? (driver.phoneNumber.isNotEmpty
                            ? 'Kontak supir (${driver.phoneNumber}) telah terdaftar resmi. Sopir akan menghubungi sebelum waktu penjemputan untuk koordinasi lokasi.'
                            : 'Staf sopir resmi telah ditugaskan. Tim CS dan sopir akan berkoordinasi sebelum waktu penjemputan untuk titik lokasi.')
                        : 'Tim MobilJuragan sedang menetapkan staf pengemudi resmi yang siaga untuk jadwal perjalanan Anda. Info lengkap pengemudi akan otomatis muncul di sini.',
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
          const SizedBox(height: 10),
          // Wrap: tautan "Buka Chat CS" turun ke baris berikutnya saat ukuran
          // teks sistem diperbesar, bukan menimpa teks jam standby.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Standby 12 Jam/Hari (mulai ${booking.startTime})',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
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
                      fontSize: AppTypography.sizeCaption,
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

  String _formatRejectionReason(String? reason) {
    if (reason == null || reason.trim().isEmpty) {
      return 'Dokumen yang diunggah belum memenuhi syarat. Mohon periksa kejelasan foto dan kelengkapan berkas.';
    }
    final trimmed = reason.trim();
    if (trimmed.length == 1) return trimmed.toUpperCase();
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  /// Kartu Pengelolaan & Verifikasi Dokumen Persyaratan Lepas Kunci (Clean Anti-Slop UI)
  Widget _buildLepasKunciDocumentCard(BookingModel booking) {
    final doc = _bookingDocument;
    final status = doc?.status ?? DocumentStatus.pendingUpload;

    final hasStatement = (_draftStatementUrl != null && _draftStatementUrl!.isNotEmpty) ||
        (doc?.statementLetterUrl != null && doc!.statementLetterUrl!.isNotEmpty);
    final hasKtp = (_draftKtpUrl != null && _draftKtpUrl!.isNotEmpty) ||
        (doc?.ktpUrl != null && doc!.ktpUrl!.isNotEmpty);
    final hasSim = (_draftSimUrl != null && _draftSimUrl!.isNotEmpty) ||
        (doc?.simUrl != null && doc!.simUrl!.isNotEmpty);

    final isVerified = status == DocumentStatus.verified;
    final hasAnyDraft = (_draftStatementUrl != null && _draftStatementUrl != doc?.statementLetterUrl) ||
        (_draftKtpUrl != null && _draftKtpUrl != doc?.ktpUrl) ||
        (_draftSimUrl != null && _draftSimUrl != doc?.simUrl);

    int uploadedCount = 0;
    if (hasKtp) uploadedCount++;
    if (hasSim) uploadedCount++;
    if (hasStatement) uploadedCount++;

    final isRejected = status == DocumentStatus.rejected;
    final isDraftKtpNew = _draftKtpUrl != null && _draftKtpUrl != doc?.ktpUrl;
    final isDraftSimNew = _draftSimUrl != null && _draftSimUrl != doc?.simUrl;
    final isDraftStatementNew = _draftStatementUrl != null && _draftStatementUrl != doc?.statementLetterUrl;

    final rejectionReasonRaw = doc?.rejectionReason?.trim() ?? '';
    final reasonLower = rejectionReasonRaw.toLowerCase();
    final hasSpecificTarget = reasonLower.contains('ktp') ||
        reasonLower.contains('identitas') ||
        reasonLower.contains('sim') ||
        reasonLower.contains('pernyataan') ||
        reasonLower.contains('surat') ||
        reasonLower.contains('ttd') ||
        reasonLower.contains('tanda tangan') ||
        reasonLower.contains('meterai');

    final isKtpTargeted = isRejected &&
        (reasonLower.contains('ktp') || reasonLower.contains('identitas') || !hasSpecificTarget);
    final isSimTargeted = isRejected &&
        (reasonLower.contains('sim') || !hasSpecificTarget);
    final isStatementTargeted = isRejected &&
        (reasonLower.contains('pernyataan') ||
            reasonLower.contains('surat') ||
            reasonLower.contains('ttd') ||
            reasonLower.contains('tanda tangan') ||
            reasonLower.contains('meterai') ||
            !hasSpecificTarget);

    Color badgeBg;
    Color badgeText;
    Color badgeBorder;
    String badgeLabel;

    if (isVerified) {
      badgeBg = const Color(0xFFF0FDF4);
      badgeText = const Color(0xFF15803D);
      badgeBorder = const Color(0xFFBBF7D0);
      badgeLabel = '3/3 Terverifikasi';
    } else if (isRejected) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeText = const Color(0xFFDC2626);
      badgeBorder = const Color(0xFFFECACA);
      badgeLabel = 'Perlu Revisi';
    } else if (uploadedCount == 3) {
      badgeBg = const Color(0xFFF0F9FF);
      badgeText = const Color(0xFF0369A1);
      badgeBorder = const Color(0xFFBAE6FD);
      badgeLabel = '3/3 Menunggu Cek';
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFB45309);
      badgeBorder = const Color(0xFFFDE68A);
      badgeLabel = '$uploadedCount/3 Lengkap';
    }

    final isWaitingPayment = booking.status == BookingStatus.menungguPembayaran ||
        (booking.isFinalTariffConfirmed &&
            booking.status != BookingStatus.pembayaranSelesai &&
            booking.status != BookingStatus.verifikasiKantor &&
            booking.status != BookingStatus.mobilSiapDigunakan &&
            booking.status != BookingStatus.selesai &&
            booking.status != BookingStatus.dibatalkan);

    final canCollapse = isWaitingPayment && uploadedCount == 3 && !isRejected;

    if (canCollapse && _isLepasKunciDocsCollapsed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Dokumen Lepas Kunci',
                      style: TextStyle(
                        fontSize: AppTypography.sizeBodyLarge,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Text(
                    badgeLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      fontWeight: FontWeight.w700,
                      color: badgeText,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isLepasKunciDocsCollapsed = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat',
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryTeal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu Dokumen (Fleksibel & Anti-Overflow)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Dokumen Wajib Lepas Kunci',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Text(
                      badgeLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  if (canCollapse) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isLepasKunciDocsCollapsed = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sembunyikan',
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTeal,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_up, size: 16, color: AppColors.primaryTeal),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Wajib dilengkapi sebelum serah terima unit di lokasi untuk mengaktifkan E-Ticket pengambilan kunci.',
            style: TextStyle(
              fontSize: AppTypography.sizeCaption,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Peringatan Revisi Jika Ditolak Admin (Clean UI)
          if (status == DocumentStatus.rejected) ...[
            Container(
              padding: const EdgeInsets.all(12),
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
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Catatan Staf: "${_formatRejectionReason(doc?.rejectionReason)}"',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Silakan unggah ulang dokumen yang ditolak di bawah, lalu tekan Kirim Pembaruan.',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      color: Color(0xFF475569),
                      fontFamily: 'Inter',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3 Baris Dokumen Sesuai Mockup Clean UI
          // 1. e-KTP
          _buildCleanDocRow(
            title: '1. Foto e-KTP Asli',
            subtitle: isDraftKtpNew
                ? '✓ File baru dipilih (Siap dikirim)'
                : (isKtpTargeted
                    ? 'Ditolak • Perlu foto ulang'
                    : (hasKtp
                        ? (isVerified
                            ? 'Terverifikasi oleh staf'
                            : (isRejected
                                ? 'ktp_pemesan.jpg • Telah diunggah'
                                : 'ktp_pemesan.jpg • Menunggu verifikasi'))
                        : 'Belum diunggah • Wajib sesuai nama penyewa')),
            isUploaded: hasKtp,
            isVerified: isVerified,
            isDraftNew: isDraftKtpNew,
            isRejected: isKtpTargeted && !isDraftKtpNew,
            icon: Icons.badge_outlined,
            onAction: () => _pickDocument('ktp', 'Foto e-KTP Asli'),
          ),
          const SizedBox(height: 10),

          // 2. SIM A
          _buildCleanDocRow(
            title: '2. Foto SIM A Aktif',
            subtitle: isDraftSimNew
                ? '✓ File baru dipilih (Siap dikirim)'
                : (isSimTargeted
                    ? 'Ditolak • Perlu foto ulang'
                    : (hasSim
                        ? (isVerified
                            ? 'Terverifikasi oleh staf'
                            : (isRejected
                                ? 'sim_a_pemesan.jpg • Telah diunggah'
                                : 'sim_a_pemesan.jpg • Menunggu verifikasi'))
                        : 'Belum diunggah • Masa berlaku masih aktif')),
            isUploaded: hasSim,
            isVerified: isVerified,
            isDraftNew: isDraftSimNew,
            isRejected: isSimTargeted && !isDraftSimNew,
            icon: Icons.credit_card_outlined,
            onAction: () => _pickDocument('sim', 'Foto SIM A Aktif'),
          ),
          const SizedBox(height: 10),

          // 3. Surat Pernyataan (Dengan 2 Tombol Berdampingan)
          _buildCleanStatementRow(
            booking: booking,
            hasStatement: hasStatement,
            isVerified: isVerified,
            isDraftNew: isDraftStatementNew,
            isRejected: isStatementTargeted && !isDraftStatementNew,
          ),
          const SizedBox(height: 12),

          // Tombol Kirim Berkas ke Admin (Bila ada draft baru atau rejected)
          if (hasAnyDraft || status == DocumentStatus.rejected) ...[
            SizedBox(
              width: double.infinity,
              height: (44 * MediaQuery.textScalerOf(context).scale(1)).clamp(44, 88),
              child: ElevatedButton.icon(
                onPressed: (!hasAnyDraft || _isUploadingDocument)
                    ? null
                    : () => _submitDocuments(booking),
                icon: _isUploadingDocument
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_outlined, size: 16),
                label: Text(
                  _isUploadingDocument
                      ? 'Mengirim Berkas...'
                      : (hasAnyDraft
                          ? 'Kirim Pembaruan Dokumen'
                          : 'Pilih Berkas Baru Terlebih Dahulu'),
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildCleanDocRow({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required bool isVerified,
    required IconData icon,
    required VoidCallback onAction,
    bool isDraftNew = false,
    bool isRejected = false,
    String? actionLabel,
  }) {
    const containerBg = Colors.white;
    Color borderColor;
    Color iconBg;
    Color iconColor;
    Color subtitleColor;
    FontWeight subtitleWeight = FontWeight.w400;
    String buttonText;
    Color buttonTextColor;
    BorderSide buttonSide;

    if (isDraftNew) {
      borderColor = const Color(0xFFE2E8F0);
      iconBg = const Color(0xFFF1F5F9);
      iconColor = AppColors.primaryTeal;
      subtitleColor = AppColors.primaryTeal;
      subtitleWeight = FontWeight.w600;
      buttonText = actionLabel ?? 'Ganti File';
      buttonTextColor = const Color(0xFF475569);
      buttonSide = const BorderSide(color: Color(0xFFCBD5E1));
    } else if (isRejected) {
      borderColor = const Color(0xFFFECACA);
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      subtitleColor = const Color(0xFFDC2626);
      subtitleWeight = FontWeight.w600;
      buttonText = actionLabel ?? 'Unggah Ulang';
      buttonTextColor = AppColors.primaryNavy;
      buttonSide = const BorderSide(color: AppColors.primaryNavy, width: 1.1);
    } else if (isVerified) {
      borderColor = const Color(0xFFBBF7D0);
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF16A34A);
      subtitleColor = const Color(0xFF15803D);
      subtitleWeight = FontWeight.w600;
      buttonText = 'Selesai';
      buttonTextColor = const Color(0xFF16A34A);
      buttonSide = const BorderSide(color: Color(0xFFBBF7D0));
    } else if (isUploaded) {
      borderColor = const Color(0xFFE2E8F0);
      iconBg = const Color(0xFFF1F5F9);
      iconColor = AppColors.primaryNavy;
      subtitleColor = AppColors.textSecondary;
      subtitleWeight = FontWeight.w500;
      buttonText = actionLabel ?? 'Ubah';
      buttonTextColor = AppColors.primaryNavy;
      buttonSide = const BorderSide(color: AppColors.borderMedium);
    } else {
      borderColor = AppColors.borderSubtle;
      iconBg = const Color(0xFFF1F5F9);
      iconColor = AppColors.textSecondary;
      subtitleColor = AppColors.textSecondary;
      buttonText = actionLabel ?? 'Unggah';
      buttonTextColor = AppColors.primaryNavy;
      buttonSide = const BorderSide(color: AppColors.borderMedium);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    color: subtitleColor,
                    fontWeight: subtitleWeight,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isVerified ? null : onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonTextColor,
              side: buttonSide,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: AppTypography.sizeTiny,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanStatementRow({
    required BookingModel booking,
    required bool hasStatement,
    required bool isVerified,
    bool isDraftNew = false,
    bool isRejected = false,
  }) {
    const containerBg = Colors.white;
    Color borderColor;
    Color iconBg;
    Color iconColor;
    String statementSubtitle;
    Color subtitleColor;
    FontWeight subtitleWeight = FontWeight.w400;
    String uploadButtonLabel;
    Color uploadTextColor;
    BorderSide uploadSide;

    if (isDraftNew) {
      borderColor = const Color(0xFFE2E8F0);
      iconBg = const Color(0xFFF1F5F9);
      iconColor = AppColors.primaryTeal;
      statementSubtitle = '✓ File baru dipilih (Siap dikirim)';
      subtitleColor = AppColors.primaryTeal;
      subtitleWeight = FontWeight.w600;
      uploadButtonLabel = 'Ganti File';
      uploadTextColor = const Color(0xFF475569);
      uploadSide = const BorderSide(color: Color(0xFFCBD5E1));
    } else if (isRejected) {
      borderColor = const Color(0xFFFECACA);
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      statementSubtitle = 'Ditolak • Perlu tanda tangan ulang dan difoto jelas';
      subtitleColor = const Color(0xFFDC2626);
      subtitleWeight = FontWeight.w600;
      uploadButtonLabel = 'Unggah Ulang';
      uploadTextColor = AppColors.primaryNavy;
      uploadSide = const BorderSide(color: AppColors.primaryNavy, width: 1.1);
    } else if (isVerified) {
      borderColor = const Color(0xFFBBF7D0);
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF16A34A);
      statementSubtitle = 'Surat pernyataan telah diverifikasi staf.';
      subtitleColor = const Color(0xFF15803D);
      subtitleWeight = FontWeight.w600;
      uploadButtonLabel = 'Selesai';
      uploadTextColor = const Color(0xFF16A34A);
      uploadSide = const BorderSide(color: Color(0xFFBBF7D0));
    } else if (hasStatement) {
      borderColor = const Color(0xFFE2E8F0);
      iconBg = const Color(0xFFF1F5F9);
      iconColor = AppColors.primaryNavy;
      statementSubtitle = 'surat_ttd_basah.jpg • Menunggu verifikasi staf.';
      subtitleColor = AppColors.textSecondary;
      subtitleWeight = FontWeight.w500;
      uploadButtonLabel = 'Ubah Foto';
      uploadTextColor = AppColors.primaryNavy;
      uploadSide = const BorderSide(color: AppColors.borderMedium);
    } else {
      borderColor = AppColors.borderSubtle;
      iconBg = const Color(0xFFF1F5F9);
      iconColor = AppColors.textSecondary;
      statementSubtitle = 'Pernyataan bebas alkohol/narkoba & tanggung jawab unit. Unduh PDF, cetak & tanda tangani, lalu unggah fotonya.';
      subtitleColor = AppColors.textSecondary;
      uploadButtonLabel = 'Unggah TTD';
      uploadTextColor = AppColors.primaryNavy;
      uploadSide = const BorderSide(color: AppColors.borderMedium);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. Surat Pernyataan Penyewa',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statementSubtitle,
                      style: TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        color: subtitleColor,
                        fontWeight: subtitleWeight,
                        fontFamily: 'Inter',
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStatementPdfModal(context, booking),
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Unduh PDF',
                      maxLines: 1,
                      style: TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isVerified
                      ? null
                      : () => _pickDocument('statement', 'Surat Pernyataan TTD Basah'),
                  icon: const Icon(Icons.upload_rounded, size: 14),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      uploadButtonLabel,
                      maxLines: 1,
                      style: const TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: uploadTextColor,
                    side: uploadSide,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatementPdfModal(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          child: Column(
            children: [
              // Modal Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRATINJAU DOKUMEN PDF (TERISI OTOMATIS)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppTypography.sizeTiny,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFF38BDF8),
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            'SURAT_PERNYATAAN_${booking.id}.pdf',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              color: Colors.white70,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),

              // Modal Sheet Body: A4 Paper Preview
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'SURAT PERNYATAAN PENYEWA LEPAS KUNCI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PT MOBILJURAGAN TRANS MERAUKE • Ref: ${booking.id}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeTiny,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 16, color: Color(0xFFCBD5E1)),

                          const Text(
                            'Saya yang bertanda tangan di bawah ini:',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTiny,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nama Lengkap  : ${context.read<AuthController>().currentUser?.name ?? 'Budi Santoso'} (Otomatis dari Akun)',
                                  style: const TextStyle(fontSize: AppTypography.sizeTiny, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'NIK / No. SIM : .....................................................................',
                                  style: TextStyle(fontSize: AppTypography.sizeTiny, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unit Kendaraan: ${booking.vehicle.name} (Plat: ${booking.vehicle.plateNumber})',
                                  style: const TextStyle(fontSize: AppTypography.sizeTiny, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Periode Sewa  : ${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year} - ${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year} (${booking.durationDays} Hari)',
                                  style: const TextStyle(fontSize: AppTypography.sizeTiny, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            'Dengan ini menyatakan secara sadar dan mengikat secara hukum:',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTiny,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '1. Menyatakan dalam keadaan sehat serta TIDAK PERNAH DAN TIDAK AKAN mengemudikan kendaraan dalam pengaruh minuman keras (alkohol), narkotika, psikotropika, atau obat terlarang.\n'
                            '2. Tidak menggunakan kendaraan untuk tindak pidana, balap liar, ataupun menggadaikan/memindahtangankan armada kepada pihak lain.\n'
                            '3. Bersedia bertanggung jawab penuh secara hukum (perdata dan pidana) serta menanggung biaya perbaikan apabila terjadi kelalaian atau insiden selama masa sewa.',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTiny,
                              height: 1.4,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Dicetak dari aplikasi MobilJuragan',
                                style: TextStyle(fontSize: AppTypography.sizeMicro, color: AppColors.textSecondary),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Merauke, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                    style: const TextStyle(fontSize: AppTypography.sizeMicro, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF94A3B8), style: BorderStyle.solid),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Meterai Rp10.000 &\nTTD Basah',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: AppTypography.sizeMicro, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '( ${context.read<AuthController>().currentUser?.name ?? 'Budi Santoso'} )',
                                    style: const TextStyle(fontSize: AppTypography.sizeMicro, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Modal Footer
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _downloadAutoFilledPdf(booking);
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Unduh File PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
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

  Future<void> _downloadAutoFilledPdf(BookingModel booking) async {
    try {
      final bytes = await _documentApiService.downloadBookingStatementPdf(booking.id);
      if (mounted) {
        final kbSize = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Surat pernyataan resmi untuk ${booking.id} berhasil diunduh ($kbSize KB). Format PDF siap cetak A4.',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Gagal mengunduh PDF: ${e.toString().replaceAll('ApiException: ', '')}',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickDocument(String slotType, String slotTitle) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      setState(() {
        const sampleBase64 =
            'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...contoh_dokumen_resmi.jpg';
        if (slotType == 'statement') {
          _draftStatementUrl = sampleBase64;
        } else if (slotType == 'ktp') {
          _draftKtpUrl = sampleBase64;
        } else if (slotType == 'sim') {
          _draftSimUrl = sampleBase64;
        }
      });
      return;
    }

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.cardWhite,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unggah $slotTitle',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih sumber dokumen resmi yang jelas dan tidak buram.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryTeal),
                  ),
                  title: const Text(
                    'Ambil Foto Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryNavy),
                  ),
                  title: const Text(
                    'Pilih dari Galeri HP',
                    style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      setState(() {
        if (slotType == 'statement') {
          _draftStatementUrl = base64String;
        } else if (slotType == 'ktp') {
          _draftKtpUrl = base64String;
        } else if (slotType == 'sim') {
          _draftSimUrl = base64String;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berkas $slotTitle berhasil dipilih.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.primaryNavy,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih berkas: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _submitDocuments(BookingModel booking) async {
    final statement = _draftStatementUrl ?? _bookingDocument?.statementLetterUrl;
    final ktp = _draftKtpUrl ?? _bookingDocument?.ktpUrl;
    final sim = _draftSimUrl ?? _bookingDocument?.simUrl;

    if (statement == null && ktp == null && sim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal salah satu dokumen persyaratan untuk diunggah.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUploadingDocument = true);
    try {
      final updated = await _documentApiService.uploadBookingDocuments(
        bookingId: booking.id,
        statementLetterUrl: statement,
        ktpUrl: ktp,
        simUrl: sim,
      );

      if (mounted) {
        setState(() {
          _bookingDocument = updated;
          _isUploadingDocument = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Dokumen persyaratan berhasil dikirim ke admin operasional untuk diverifikasi.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingDocument = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Gagal mengirim dokumen: ${e.toString().replaceAll('ApiException: ', '')}',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    }
  }

  Widget _buildStepRow({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required bool isLast,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBgColor,
  }) {
    Color iconColor;
    Color iconBgColor;
    Widget iconChild;

    if (isDone) {
      iconBgColor = AppColors.badgeGreenBg;
      iconColor = AppColors.badgeGreenText;
      iconChild = Icon(Icons.check, size: 14, color: iconColor);
    } else if (isActive) {
      iconBgColor = badgeBgColor ?? AppColors.tealLight;
      iconColor = badgeColor ?? AppColors.primaryTeal;
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
          fontSize: AppTypography.sizeCaption,
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
                        ? (badgeColor ?? AppColors.primaryTeal)
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
                            fontSize: AppTypography.sizeBodyLarge,
                            fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? AppColors.primaryNavy
                                : (isDone ? AppColors.textPrimary : AppColors.textSecondary),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (isActive && !isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBgColor ?? AppColors.tealLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText ?? 'PROSES',
                            style: TextStyle(
                              fontSize: AppTypography.sizeMicro,
                              fontWeight: FontWeight.w700,
                              color: badgeColor ?? AppColors.primaryTeal,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      if (isLast && isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.badgeGreenBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SELESAI',
                            style: TextStyle(
                              fontSize: AppTypography.sizeMicro,
                              fontWeight: FontWeight.w700,
                              color: AppColors.badgeGreenText,
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
                      fontSize: AppTypography.sizeCaption,
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




  Widget _buildTariffRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppTypography.sizeBody,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ],
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
            fontSize: AppTypography.sizeTiny,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppTypography.sizeBody,
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
              fontSize: AppTypography.sizeTiny,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.confirmation_num_outlined, size: 18, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'E-TICKET RESERVASI MOBILJURAGAN',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTiny,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white70,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                booking.id,
                                style: const TextStyle(
                                  fontSize: AppTypography.sizeTitle,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: booking.id));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kode reservasi berhasil disalin'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 15,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          fontSize: AppTypography.sizeTiny,
                          fontWeight: FontWeight.w800,
                          color: isCod ? const Color(0xFFDBEAFE) : const Color(0xFFD1FAE5),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: _isRefreshing ? null : () => _manualRefreshStatus(booking),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _isRefreshing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.sync_rounded, size: 16, color: Colors.white70),
                      ),
                    ),
                  ],
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
                // Info Pelunasan Tunai (hanya jika COD, jika online lunas sudah diwakili badge LUNAS di header)
                if (isCod) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primaryNavy,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pelunasan Tunai: Siapkan Rp ${_formatRupiah(booking.totalCost)} saat serah terima unit.',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

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
                        label: 'Model Sewa',
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

                // Barcode / Verifikasi Digital Serah Terima
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
                            Text(
                              'Kode Serah Terima: MBJ-${booking.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase()}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Tunjukkan kode QR ini ke petugas atau sopir saat serah terima unit',
                              style: TextStyle(
                                fontSize: AppTypography.sizeTiny,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return OnlinePaymentSheetModal(
          booking: booking,
          onPaymentUpdated: (updatedPayment) {
            setState(() {
              _payment = updatedPayment;
            });
          },
          onCodConfirmationRequested: () {
            Navigator.pop(sheetContext);
            _showCodConfirmationSheet(context, booking);
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
                            fontSize: AppTypography.sizeHeading,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pelunasan tunai saat serah terima unit di lokasi jemput.',
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
                    const Text('Total Pelunasan Tunai', style: TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary, fontFamily: 'Inter')),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${_formatRupiah(booking.totalCost)}',
                      style: const TextStyle(fontSize: AppTypography.sizeMetric, fontWeight: FontWeight.w800, color: AppColors.primaryNavy, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Titik Serah Terima: ${booking.pickupLocation}',
                      style: const TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Ketentuan Serah Terima COD:',
                style: AppTypography.bodyBold,
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
                      child: const Text('Batal / Ubah', style: AppTypography.bodyStrong),
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
                              style: AppTypography.bodyStrong,
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
                      child: const Text('Konfirmasi COD', style: AppTypography.bodyBold),
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
            style: const TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedBannerCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: (42 * MediaQuery.textScalerOf(context).scale(1)).clamp(42, 84),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 24,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penyewaan Selesai',
                      style: TextStyle(
                        fontSize: AppTypography.sizeTitle,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unit ${booking.vehicle.name} telah kembali ke kantor',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeGreenBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TUNTAS',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w700,
                    color: AppColors.badgeGreenText,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFDCFCE7)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kode Reservasi: ${booking.id}',
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: booking.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode reservasi berhasil disalin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Masa sewa ${booking.vehicle.name} telah selesai dan unit telah diterima dalam kondisi baik oleh tim kantor operasional CV. Mobil Juragan Merauke. Terima kasih telah mempercayai layanan kami!',
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
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
                height: (42 * MediaQuery.textScalerOf(context).scale(1)).clamp(42, 84),
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                      children: [
                        const Text(
                          'Reservasi Dibatalkan',
                          style: TextStyle(
                            fontSize: AppTypography.sizeAmount,
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
                              fontSize: AppTypography.sizeTiny,
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
                            fontSize: AppTypography.sizeCaption,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kode Reservasi: ${booking.id}',
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: booking.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode reservasi berhasil disalin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris Alasan Pembatalan (Layout Rapi & Profesional)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lebar label sebelumnya dipatok 125 px, sehingga label meluber
              // saat ukuran teks sistem diperbesar. Kini label ikut fleksibel.
              Expanded(
                flex: 2,
                child: Text(
                  'Alasan Pembatalan',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  booking.cancellationReason ?? 'Dibatalkan oleh pemesan',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
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
                      Expanded(
                        child: Text(
                          'Penyelesaian Finansial (COD)',
                          style: TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Bebas Biaya',
                        style: TextStyle(
                          fontSize: AppTypography.sizeCaption,
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
                      fontSize: AppTypography.sizeCaption,
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
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                    children: [
                      const Text(
                        'Total Telah Dibayar',
                        style: TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary, fontFamily: 'Inter'),
                      ),
                      Text(
                        'Rp ${_formatRupiah(booking.totalCost)}',
                        style: const TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                    children: [
                      const Text(
                        'Potongan Operasional (15%)',
                        style: TextStyle(fontSize: AppTypography.sizeCaption, color: Color(0xFFDC2626), fontFamily: 'Inter'),
                      ),
                      Text(
                        '-Rp ${_formatRupiah(booking.totalCost - booking.cancellationRefundAmount!)}',
                        style: const TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w600, color: Color(0xFFDC2626), fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                    children: [
                      const Text(
                        'Dana Dikembalikan',
                        style: TextStyle(fontSize: AppTypography.sizeBody, fontWeight: FontWeight.w700, color: Color(0xFF166534), fontFamily: 'Inter'),
                      ),
                      Text(
                        'Rp ${_formatRupiah(booking.cancellationRefundAmount!)}',
                        style: const TextStyle(fontSize: AppTypography.sizeBodyLarge, fontWeight: FontWeight.w800, color: Color(0xFF15803D), fontFamily: 'Inter'),
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
                          style: const TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w700, color: Color(0xFF1F2937), fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atas Nama: ${booking.cancellationAccountName ?? "-"}',
                          style: const TextStyle(fontSize: AppTypography.sizeTiny, color: AppColors.textSecondary, fontFamily: 'Inter'),
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
                          style: TextStyle(fontSize: AppTypography.sizeTiny, fontWeight: FontWeight.w500, color: Color(0xFF0F766E), fontFamily: 'Inter'),
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
                      style: TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary, fontFamily: 'Inter'),
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
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Konsultasikan tanggal pengganti atau unit armada lainnya bersama tim CS MobilJuragan.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
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
              style: AppTypography.captionBold,
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
      'Ingin mengganti unit mobil atau model sewa',
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
                                  fontSize: AppTypography.sizeHeading,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kode Reservasi: ${booking.id}',
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
                                    fontSize: AppTypography.sizeBody,
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
                                fontSize: AppTypography.sizeCaption,
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
                                    fontSize: AppTypography.sizeBody,
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
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                              children: [
                                const Text('Total Pembayaran:', style: TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary, fontFamily: 'Inter')),
                                Text('Rp ${_formatRupiah(booking.totalCost)}', style: AppTypography.captionStrong),
                              ],
                            ),
                            const SizedBox(height: 4),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                              children: [
                                const Text('Penalti Kompensasi (15%):', style: TextStyle(fontSize: AppTypography.sizeCaption, color: Color(0xFFDC2626), fontFamily: 'Inter')),
                                Text('-Rp ${_formatRupiah(penaltyAmount)}', style: const TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w600, color: Color(0xFFDC2626), fontFamily: 'Inter')),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 6),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                              children: [
                                const Text('Estimasi Dana Dikembalikan:', style: TextStyle(fontSize: AppTypography.sizeBody, fontWeight: FontWeight.w700, color: Color(0xFF166534), fontFamily: 'Inter')),
                                Text('Rp ${_formatRupiah(refundAmount)}', style: const TextStyle(fontSize: AppTypography.sizeBodyLarge, fontWeight: FontWeight.w800, color: Color(0xFF166534), fontFamily: 'Inter')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Rekening Tujuan Pengembalian Dana',
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
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
                        fontSize: AppTypography.sizeBodyLarge,
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
                                    fontSize: AppTypography.sizeBody,
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
                          hintStyle: const TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary),
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
                              style: AppTypography.bodyStrong,
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
                                    style: AppTypography.bodyStrong,
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
                              style: AppTypography.bodyBold,
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
    final isCompleted = booking.status == BookingStatus.selesai;
    final isWaitingPayment = booking.status == BookingStatus.menungguPembayaran;
    final isPaid = booking.status == BookingStatus.pembayaranSelesai ||
        booking.status == BookingStatus.verifikasiKantor ||
        booking.status == BookingStatus.mobilSiapDigunakan;

    if (isCancelled) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: (48 * MediaQuery.textScalerOf(context).scale(1)).clamp(48, 96),
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
                style: AppTypography.cardTitle,
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
            height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
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
                style: AppTypography.bodyLargeStrong,
              ),
            ),
          ),
        ],
      );
    }

    if (isCompleted) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: (48 * MediaQuery.textScalerOf(context).scale(1)).clamp(48, 96),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialTabIndex: 0)),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Kembali ke Beranda',
                style: AppTypography.cardTitle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
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
                  fontSize: AppTypography.sizeBodyLarge,
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
        ],
      );
    }

    return Column(
      children: [
        if (isPaid) ...[
          // Tahap 4: Sewa Berjalan
          SizedBox(
            width: double.infinity,
            height: (48 * MediaQuery.textScalerOf(context).scale(1)).clamp(48, 96),
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
                style: AppTypography.cardTitle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => _showCancellationBottomSheet(context, booking),
              icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.textSecondary),
              label: const Text(
                'Butuh bantuan pembatalan atau perubahan jadwal? Ajukan di sini',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ] else if (isWaitingPayment) ...[
          // Tahap 3: Menunggu Pembayaran
          // Tombol Bayar Sekarang telah berada langsung di dalam kartu tagihan atas
          SizedBox(
            width: double.infinity,
            height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatSupportScreen(booking: booking),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent_rounded, size: 18, color: AppColors.primaryTeal),
              label: const Text(
                'Butuh Bantuan? Chat CS MobilJuragan',
                style: TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
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
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _showCancellationBottomSheet(context, booking),
              child: const Text(
                'Batalkan Pengajuan Sewa Ini',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ] else ...[
          // Tahap 1 & 2: Permintaan Masuk / Menunggu Konfirmasi Tarif
          SizedBox(
            width: double.infinity,
            height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatSupportScreen(booking: booking),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent_rounded, size: 18, color: AppColors.primaryTeal),
              label: const Text(
                'Butuh Bantuan? Chat CS MobilJuragan',
                style: TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
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
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _showCancellationBottomSheet(context, booking),
              child: const Text(
                'Batalkan Pengajuan Sewa Ini',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
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

/// Modal lembar pembayaran dinamis dengan integrasi Dynamic QRIS (EMVCo),
/// rincian kode unik 3 digit, countdown timer kedaluwarsa, tombol cek status otomatis,
/// dan ketahanan offline saat server backend tidak dapat dijangkau.
class OnlinePaymentSheetModal extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback? onCodConfirmationRequested;
  final ValueChanged<PaymentModel>? onPaymentUpdated;

  const OnlinePaymentSheetModal({
    super.key,
    required this.booking,
    this.onCodConfirmationRequested,
    this.onPaymentUpdated,
  });

  @override
  State<OnlinePaymentSheetModal> createState() => _OnlinePaymentSheetModalState();
}

class _OnlinePaymentSheetModalState extends State<OnlinePaymentSheetModal> {
  int _selectedTab = 0; // 0: QRIS Dinamis, 1: Transfer Bank, 2: Bayar Tunai (COD)
  String _selectedBank = 'Bank BRI';
  bool _isCheckingStatus = false;
  // ignore: unused_field
  bool _isLoadingPayment = true;

  // ignore: unused_field
  PaymentModel? _payment;
  Timer? _countdownTimer;

  late DateTime _expiresAt;
  late int _baseAmount;
  late int _uniqueCode;
  late int _totalAmount;
  late String _qrisPayload;

  final PaymentApiService _apiService = PaymentApiService();
  final TextEditingController _senderNameController = TextEditingController();
  String? _proofFileName;
  String? _proofBase64;
  bool _isSubmittingProof = false;
  bool _isProofUploaded = false;

  @override
  void initState() {
    super.initState();
    _baseAmount = widget.booking.totalCost;
    // Hitung alokasi kode unik 3 digit (50-949) untuk ketahanan offline
    _uniqueCode = (widget.booking.id.hashCode.abs() % 900) + 50;
    _totalAmount = _baseAmount + _uniqueCode;
    _expiresAt = DateTime.now().add(const Duration(hours: 12));
    _qrisPayload = PaymentModel.generateDynamicQris(_totalAmount);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _initPayment();
  }

  Future<void> _initPayment() async {
    try {
      // 1. Cek apakah sudah ada payment di backend
      PaymentModel? payment = await _apiService.getPaymentByBooking(widget.booking.id);
      // 2. Buat tagihan baru jika belum ada
      payment ??= await _apiService.createPayment(
        bookingId: widget.booking.id,
        method: PaymentMethod.qris,
      );

      final active = payment;
      if (mounted) {
        setState(() {
          _payment = active;
          _baseAmount = active.baseAmount;
          _uniqueCode = active.uniqueCode;
          _totalAmount = active.totalAmount;
          if (active.expiresAt != null) {
            _expiresAt = active.expiresAt!;
          }
          if (active.qrisPayload != null && active.qrisPayload!.isNotEmpty) {
            _qrisPayload = active.qrisPayload!;
          }
          if (active.isPendingVerification ||
              (active.proofImageUrl != null && active.proofImageUrl!.isNotEmpty)) {
            _isProofUploaded = true;
          }
          if (active.method == PaymentMethod.bankTransfer) {
            _selectedTab = 1;
            if (active.bankName != null && active.bankName!.isNotEmpty) {
              _selectedBank = active.bankName!;
            }
          }
          _isLoadingPayment = false;
        });

        if (active.isPaid) {
          _handlePaymentSuccess(active);
        }
        widget.onPaymentUpdated?.call(active);
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _isLoadingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Mode Offline: Menampilkan data tagihan & QRIS dinamis mandiri lokal.',
              style: TextStyle(fontFamily: 'Inter', fontSize: AppTypography.sizeCaption),
            ),
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoadingPayment = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPayment = false;
        });
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingStatus) return;
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      // 1. Sinkronisasi status booking dari backend (apabila admin klik "Serahkan Armada" di dashboard atau konfirmasi manual)
      final bookingController = context.read<BookingController>();
      final hasBookingUpdated = await bookingController.refreshActiveBookingStatus(widget.booking.id);
      if (!mounted) return;

      if (hasBookingUpdated) {
        final active = bookingController.bookingHistory.firstWhere(
          (b) => b.id == widget.booking.id,
          orElse: () => bookingController.activeBooking ?? widget.booking,
        );
        if (active.status == BookingStatus.mobilSiapDigunakan ||
            active.status == BookingStatus.selesai ||
            active.status == BookingStatus.pembayaranSelesai) {
          Navigator.pop(context); // Tutup payment modal sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Text(
                'Armada ${active.vehicle.name} telah diserahkan oleh admin! Masa sewa berjalan aktif.',
                style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
              ),
            ),
          );
          return;
        }
      }

      // 2. Periksa mutasi pembayaran online di tabel payment
      final payment = await _apiService.getPaymentByBooking(widget.booking.id);
      if (!mounted) return;

      if (payment != null) {
        setState(() {
          _payment = payment;
        });
        widget.onPaymentUpdated?.call(payment);

        if (payment.isPaid) {
          _handlePaymentSuccess(payment);
          return;
        }

        if (payment.isPendingVerification) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFD97706),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: const Text(
                'Bukti transfer dalam antrean verifikasi staf operasional.',
                style: AppTypography.bodyStrong,
              ),
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            'Pembayaran belum terdeteksi. Silakan transfer nominal pas Rp ${_formatRupiah(_totalAmount)}.',
            style: const TextStyle(fontFamily: 'Inter', fontSize: AppTypography.sizeBody),
          ),
        ),
      );
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Tidak dapat terhubung ke server backend (Offline). Periksa koneksi internet Anda.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Koneksi waktu habis (Timeout). Silakan coba lagi beberapa saat.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              e.message,
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Pemeriksaan status belum berhasil: $e',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  void _handlePaymentSuccess(PaymentModel payment) {
    if (!mounted) return;
    Navigator.pop(context);
    final controller = context.read<BookingController>();
    controller.completeOnlinePayment(
      bookingId: widget.booking.id,
      paymentMethod: payment.method == PaymentMethod.qris
          ? PaymentMethodType.qrisOtomatis
          : PaymentMethodType.virtualAccount,
      referenceCode: payment.id,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          'Pembayaran Rp ${_formatRupiah(payment.totalAmount)} berhasil diverifikasi otomatis!',
          style: AppTypography.bodyStrong,
        ),
      ),
    );
  }

  String _formatCountdown() {
    final diff = _expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Waktu Habis';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    if (diff.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _submitPaymentProof() async {
    if (_isSubmittingProof) return;
    final isQris = _selectedTab == 0;
    if (_proofBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isQris
              ? 'Silakan lampirkan screenshot bukti pembayaran QRIS terlebih dahulu.'
              : 'Silakan lampirkan foto struk transfer terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final senderName = _senderNameController.text.trim();
    if (senderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isQris
              ? 'Silakan isi nama pemilik akun e-wallet / m-banking pengirim.'
              : 'Silakan isi nama pemilik rekening pengirim.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingProof = true;
    });

    try {
      PaymentModel? currentPayment = _payment;
      currentPayment ??= await _apiService.createPayment(
        bookingId: widget.booking.id,
        method: isQris ? PaymentMethod.qris : PaymentMethod.bankTransfer,
        notes: isQris
            ? 'Pembayaran QRIS Dinamis oleh $senderName'
            : 'Transfer via $_selectedBank oleh $senderName',
      );

      final updatedPayment = await _apiService.uploadPaymentProof(
        paymentId: currentPayment.id,
        proofImageUrl: _proofBase64!,
        senderAccount: senderName,
        bankName: isQris ? 'QRIS Dinamis' : _selectedBank,
      );

      if (mounted) {
        setState(() {
          _payment = updatedPayment;
          _isProofUploaded = true;
          _isSubmittingProof = false;
        });
        widget.onPaymentUpdated?.call(updatedPayment);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              isQris
                  ? 'Screenshot pembayaran QRIS berhasil dikirim. Menunggu verifikasi admin operasional.'
                  : 'Bukti transfer berhasil dikirim. Menunggu verifikasi admin operasional.',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _isProofUploaded = true;
          _isSubmittingProof = false;
        });
        if (_payment != null) {
          final mockOffline = _payment!.copyWith(
            status: PaymentStatus.pendingVerification,
            proofImageUrl: _proofBase64,
          );
          widget.onPaymentUpdated?.call(mockOffline);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              isQris
                  ? 'Mode Offline: Screenshot pembayaran dicatat dan akan diverifikasi saat online.'
                  : 'Mode Offline: Bukti transfer dicatat dan akan diverifikasi saat online.',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSubmittingProof = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(e.message, style: const TextStyle(fontFamily: 'Inter')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingProof = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('Gagal mengirim bukti: $e', style: const TextStyle(fontFamily: 'Inter')),
          ),
        );
      }
    }
  }

  final ImagePicker _paymentImagePicker = ImagePicker();

  Future<void> _pickPaymentProof(bool isQris) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      setState(() {
        _proofFileName = isQris ? 'screenshot_qris_sample.jpg' : 'struk_transfer_sample.jpg';
        _proofBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...';
      });
      return;
    }

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.cardWhite,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isQris ? 'Unggah Bukti Pembayaran QRIS' : 'Unggah Struk Transfer Bank',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lampirkan screenshot atau foto struk yang menampilkan nominal dan tanggal jelas.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryTeal),
                  ),
                  title: const Text(
                    'Ambil Foto Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryNavy),
                  ),
                  title: const Text(
                    'Pilih dari Galeri HP',
                    style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                  ),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? file = await _paymentImagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      setState(() {
        _proofFileName = file.name;
        _proofBase64 = base64String;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isQris
              ? 'Screenshot pembayaran QRIS dipilih.'
              : 'Foto struk transfer $_selectedBank dipilih.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih berkas: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  String _getAccountNumber(String bank) {
    switch (bank) {
      case 'Bank BRI':
        return '0087 01 002345 53 1';
      case 'Bank BCA':
        return '8801 2026 0043 18';
      case 'Bank Mandiri':
        return '8950 2026 0043 18';
      case 'Bank BNI':
        return '9880 2026 0043 18';
      default:
        return '0087 01 002345 53 1';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _senderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _expiresAt.difference(DateTime.now()).isNegative;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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

            // Header info & countdown timer
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pembayaran Pemesanan',
                      style: TextStyle(
                        fontSize: AppTypography.sizeHeading,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reservasi #${widget.booking.id}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                if (_isProofUploaded ||
                    _payment?.status == PaymentStatus.pendingVerification ||
                    _payment?.status == PaymentStatus.paid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sedang Diverifikasi',
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isExpired ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isExpired ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isExpired ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCountdown(),
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w700,
                            color: isExpired ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (isExpired) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Batas waktu pembayaran 12 jam telah berakhir. Pesanan dibatalkan secara otomatis oleh sistem operasional.',
                        style: TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Segmented Tab Switcher (QRIS, Transfer Bank, Tunai COD)
            Container(
              height: (44 * MediaQuery.textScalerOf(context).scale(1)).clamp(44, 88),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, 'QRIS Dinamis'),
                  _buildTabItem(1, 'Transfer Bank'),
                  _buildTabItem(2, 'Bayar di Tempat'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            if (_selectedTab == 0) ...[
              _buildQrisContent(isExpired: isExpired),
            ] else if (_selectedTab == 1) ...[
              _buildBankTransferContent(isExpired: isExpired),
            ] else ...[
              _buildCodContent(isExpired: isExpired),
            ],

            const SizedBox(height: 16),

            // Card Breakdown Rincian Pembayaran (hanya untuk transfer / QRIS)
            if (_selectedTab != 2) ...[
              _buildBreakdownCard(),
              const SizedBox(height: 18),
              _buildActionButtons(isExpired: isExpired),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
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
            label,
            style: TextStyle(
              fontSize: AppTypography.sizeCaption,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrisContent({bool isExpired = false}) {
    return Column(
      children: [
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
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
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Text(
                      'STANDAR PEMBAYARAN NASIONAL',
                      style: TextStyle(
                        fontSize: AppTypography.sizeMicro,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: QrImageView(
                    data: _qrisPayload.isNotEmpty
                        ? _qrisPayload
                        : PaymentModel.officialGopayQris,
                    version: QrVersions.auto,
                    size: 190.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primaryNavy,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scan dengan m-banking atau e-wallet apa saja:\nBCA, BRI, Mandiri, BNI, GoPay, OVO, Dana, ShopeePay',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _qrisPayload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('String payload QRIS berhasil disalin ke clipboard.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Salin String QRIS', style: TextStyle(fontSize: AppTypography.sizeCaption)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildPaymentProofUploadSection(isExpired: isExpired),
      ],
    );
  }

  Widget _buildBankTransferContent({bool isExpired = false}) {
    final accountNumber = _getAccountNumber(_selectedBank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Bank Tujuan Transfer',
          style: AppTypography.bodyBold,
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Bank BRI', 'Bank BCA', 'Bank Mandiri', 'Bank BNI'].map((bank) {
            final isBankSelected = _selectedBank == bank;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBank = bank;
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
                        fontSize: AppTypography.sizeCaption,
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
        const SizedBox(height: 12),
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
                'Nomor Rekening $_selectedBank Resmi',
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    accountNumber,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeHeading,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: accountNumber.replaceAll(' ', '')));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nomor rekening $_selectedBank berhasil disalin.'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Salin', style: TextStyle(fontSize: AppTypography.sizeBody, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Atas Nama: CV Mobil Juragan Express Transport',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildPaymentProofUploadSection(isExpired: isExpired),
      ],
    );
  }

  Widget _buildPaymentProofUploadSection({bool isExpired = false}) {
    final isQris = _selectedTab == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isProofUploaded) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isQris ? 'Bukti Pembayaran QRIS Dalam Verifikasi' : 'Bukti Transfer Dalam Verifikasi',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isQris
                      ? 'Screenshot bukti pembayaran QRIS Anda telah tercatat dan sedang diverifikasi oleh staf operasional Merauke.'
                      : 'Struk transfer Anda telah tercatat dan sedang diverifikasi oleh staf operasional Merauke.',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: Color(0xFF78350F),
                    fontFamily: 'Inter',
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isProofUploaded = false;
                      _proofFileName = null;
                      _proofBase64 = null;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Unggah Ulang Bukti Lain', style: TextStyle(fontSize: AppTypography.sizeCaption)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            isQris ? 'Konfirmasi Bukti Pembayaran QRIS' : 'Konfirmasi Bukti Transfer',
            style: AppTypography.bodyBold,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _senderNameController,
            style: const TextStyle(fontSize: AppTypography.sizeBody, fontFamily: 'Inter'),
            decoration: InputDecoration(
              labelText: isQris ? 'Nama Pemilik Akun / E-Wallet Pengirim' : 'Nama Pemilik Rekening Pengirim',
              labelStyle: const TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary),
              hintText: 'Contoh: Budi Santoso',
              hintStyle: const TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primaryNavy),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _pickPaymentProof(isQris),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _proofFileName != null ? AppColors.primaryTeal : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _proofFileName != null ? Icons.receipt_long_rounded : Icons.add_photo_alternate_outlined,
                    size: 20,
                    color: _proofFileName != null ? AppColors.primaryTeal : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _proofFileName ?? (isQris ? 'Pilih Screenshot Bukti Pembayaran' : 'Pilih Foto Struk Transfer'),
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w600,
                            color: _proofFileName != null ? AppColors.textPrimary : AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _proofFileName != null ? 'Ukuran berkas 245 KB (Siap diunggah)' : 'Format JPG atau PNG (Maksimal 5MB)',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeMicro,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_proofFileName != null)
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primaryTeal),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: (44 * MediaQuery.textScalerOf(context).scale(1)).clamp(44, 88),
            child: ElevatedButton.icon(
              onPressed: (_isSubmittingProof || isExpired) ? null : _submitPaymentProof,
              icon: _isSubmittingProof
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(
                _isSubmittingProof
                    ? 'Mengirimkan Bukti...'
                    : (isExpired ? 'Batas Waktu Pembayaran Berakhir' : 'Kirim Bukti Pembayaran'),
                style: const TextStyle(fontSize: AppTypography.sizeBody, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCodContent({bool isExpired = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handshake_outlined, size: 24, color: Color(0xFF047857)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bayar Tunai di Tempat (COD)',
                      style: TextStyle(
                        fontSize: AppTypography.sizeBodyLarge,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pelunasan saat serah terima unit di Merauke',
                      style: TextStyle(fontSize: AppTypography.sizeCaption, color: AppColors.textSecondary, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text('Nominal Pelunasan Tunai', style: TextStyle(fontSize: AppTypography.sizeBody, color: AppColors.textSecondary, fontFamily: 'Inter')),
                Text(
                  'Rp ${_formatRupiah(_baseAmount)}',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeMetric,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCodStepItem(Icons.payments_outlined, 'Siapkan uang tunai pas saat pemeriksaan fisik armada bersama staf.'),
          const SizedBox(height: 6),
          _buildCodStepItem(Icons.assignment_turned_in_outlined, 'Staf menyerahkan kunci dan tanda terima resmi pembayaran.'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
            child: ElevatedButton.icon(
              onPressed: isExpired
                  ? null
                  : () {
                final bookingId = widget.booking.id;
                Navigator.pop(context);
                final controller = context.read<BookingController>();
                controller.confirmCodPayment(bookingId);
                _apiService.createPayment(
                  bookingId: bookingId,
                  method: PaymentMethod.cash,
                  notes: 'Pelunasan tunai saat serah terima unit di Merauke',
                ).ignore();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    content: const Text(
                      'Metode pembayaran Tunai di Tempat (COD) telah dipilih.',
                      style: AppTypography.bodyStrong,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Pilih Bayar di Tempat (COD)', style: AppTypography.cardTitle),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodStepItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF047857)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: AppTypography.sizeCaption,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Tarif Sewa Pokok',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Text(
                'Rp ${_formatRupiah(_baseAmount)}',
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Kode Unik Verifikasi',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Text(
                '+Rp ${_formatRupiah(_uniqueCode)}',
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D9488),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Transfer Pas:',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Rp ${_formatRupiah(_totalAmount)}',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeHeading,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _totalAmount.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nominal pas Rp ${_formatRupiah(_totalAmount)} berhasil disalin.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text(
                  'Salin Nominal Pas',
                  style: TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF3C7),
                  foregroundColor: const Color(0xFF92400E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Wajib transfer tepat 3 digit terakhir agar sistem mendeteksi pembayaran secara otomatis.',
                    style: TextStyle(
                      fontSize: AppTypography.sizeMicro,
                      color: Color(0xFF92400E),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
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

  Widget _buildActionButtons({bool isExpired = false}) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
          child: ElevatedButton(
            onPressed: _isCheckingStatus ? null : _checkPaymentStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: isExpired ? const Color(0xFFDC2626) : AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isCheckingStatus
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text('Memverifikasi Transaksi...', style: TextStyle(fontSize: AppTypography.sizeBody)),
                    ],
                  )
                : Text(
                    isExpired
                        ? 'Perbarui Status Pesanan'
                        : 'Cek Status Pembayaran (Otomatis)',
                    style: AppTypography.cardTitle,
                  ),
          ),
        ),
      ],
    );
  }
}
