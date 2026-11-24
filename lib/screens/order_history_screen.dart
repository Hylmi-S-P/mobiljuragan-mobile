import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../core/util/format_tanggal.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/daftar_geser_horizontal.dart';
import '../widgets/order_empty_state.dart';
import '../widgets/order_state_banner.dart';
import 'date_time_screen.dart';
import 'order_status_screen.dart';
import '../theme/app_typography.dart';
import '../widgets/gambar_kendaraan.dart';
import '../widgets/refund_account_form.dart';

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
  String _completedFilter = 'Semua';

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
      body: RefreshIndicator(
        onRefresh: () => bookingController.refreshFromRemote(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: 16,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
      children: activeBookings
          .map((booking) => _buildBookingCard(booking, isActive: true))
          .toList(),
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

    const filterOptions = ['Semua', 'Sewa Selesai', 'Refund', 'Dibatalkan'];
    final filtered = completedBookings.where((booking) {
      switch (_completedFilter) {
        case 'Sewa Selesai':
          return booking.status == BookingStatus.selesai;
        case 'Refund':
          return booking.status == BookingStatus.dibatalkan &&
              ((booking.refundStatus?.isNotEmpty ?? false) ||
                  (booking.cancellationRefundAmount != null &&
                      booking.cancellationRefundAmount! > 0));
        case 'Dibatalkan':
          return booking.status == BookingStatus.dibatalkan;
        default:
          return true;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DaftarGeserHorizontal(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: filterOptions.map((label) {
              final selected = _completedFilter == label;
              return Padding(
                padding: EdgeInsets.only(
                  right: label == filterOptions.last ? 0 : 8,
                ),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _completedFilter = label),
                  selectedColor: AppColors.primaryNavy,
                  backgroundColor: AppColors.cardWhite,
                  side: BorderSide(
                    color: selected
                        ? AppColors.primaryNavy
                        : AppColors.borderMedium,
                  ),
                  labelStyle: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Text(
                  'Belum ada riwayat pada kategori ini.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _completedFilter = 'Semua'),
                  child: const Text(
                    'Tampilkan Semua',
                    style: AppTypography.bodyBold,
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map(
            (booking) => _buildBookingCard(booking, isActive: false),
          ),
      ],
    );
  }

  /// Kartu Pesanan Reusable (Frame 08: Card Pesanan Berjalan & Riwayat Selesai)
  Widget _buildBookingCard(BookingModel booking, {required bool isActive}) {
    final vehicle = booking.vehicle;
    final startDate = booking.startDate;
    final endDate = booking.endDate;

    final dateRange = formatRentangSewa(startDate, endDate);
    final timeStr =
        (booking.startTime.isNotEmpty && booking.startTime != '00.00 WIT')
        ? ' • Pukul ${booking.startTime}'
        : '';
    final scheduleText = '$dateRange • ${booking.durationDays} Hari$timeStr';
    final refundBadge = !isActive ? _buildRefundSecondaryBadge(booking) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderStatusScreen(booking: booking),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildStatusBadge(booking),
                          ?refundBadge,
                        ],
                      ),
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
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 12),

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
                        child: GambarKendaraan(
                          sumber: vehicle.imageUrl,
                          fit: BoxFit.contain,
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

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scheduleText,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.primaryTeal,
                      ),
                    ),
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
                if (booking.isDocumentRejected) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusDangerBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.statusDangerBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: AppColors.statusDangerFg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.documentRejectionReason != null &&
                                    booking.documentRejectionReason!.isNotEmpty
                                ? 'Catatan Staf: "${booking.documentRejectionReason}"'
                                : 'Catatan Staf: "Dokumen belum memenuhi syarat. Hubungi kantor untuk detailnya."',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusDangerFg,
                              fontFamily: 'Inter',
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (booking.status == BookingStatus.dibatalkan) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Alasan: ${_alasanBatalUntukKartu(booking)}',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (booking.cancellationRefundAmount != null &&
                      booking.cancellationRefundAmount! > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      _labelNominalRefundKartu(booking),
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: booking.danaTerverifikasi
                            ? AppColors.statusSuccessFg
                            : AppColors.statusWarningFg,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                  if (booking.refundStatus != null ||
                      (booking.cancellationBank?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    kotakRekeningRefund(booking),
                    const SizedBox(height: 8),
                    barisStatusRefund(context, booking),
                  ],
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelTotalHarga(booking),
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
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
                        if (booking.status == BookingStatus.menungguPembayaran)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderStatusScreen(booking: booking),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.control,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Bayar Sekarang',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyBold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderStatusScreen(booking: booking),
                                ),
                              );
                            },
                            iconAlignment: IconAlignment.end,
                            icon: Icon(
                              booking.isDocumentRejected
                                  ? Icons.upload_file_outlined
                                  : Icons.chevron_right,
                              size: 16,
                              color: booking.isDocumentRejected
                                  ? AppColors.statusDangerFg
                                  : AppColors.primaryTeal,
                            ),
                            label: Text(
                              booking.isDocumentRejected
                                  ? 'Unggah Revisi'
                                  : 'Lihat Detail',
                              style: TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: FontWeight.w700,
                                color: booking.isDocumentRejected
                                    ? AppColors.statusDangerFg
                                    : AppColors.primaryTeal,
                                fontFamily: 'Inter',
                              ),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                      ] else ...[
                        OutlinedButton(
                          onPressed: () {
                            final bookingCtrl =
                                context.read<BookingController>();
                            bookingCtrl.selectVehicle(vehicle);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DateTimeScreen(vehicle: vehicle),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            foregroundColor: AppColors.primaryNavy,
                            side: const BorderSide(
                              color: AppColors.primaryNavy,
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.control,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Sewa Lagi',
                            style: AppTypography.bodyBold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _alasanBatalUntukKartu(BookingModel booking) {
    final reason = booking.cancellationReason?.trim();
    if (reason != null && reason.isNotEmpty) return reason;
    if (booking.isRejectedByAdmin) {
      return 'Pengajuan sewa tidak dapat disetujui admin kantor.';
    }
    final actor = booking.cancelledBy?.toUpperCase();
    if (actor == 'ADMIN') return 'Dibatalkan oleh admin kantor.';
    if (actor == 'SYSTEM') {
      return 'Dibatalkan otomatis karena batas waktu terlewati.';
    }
    return 'Dibatalkan oleh pelanggan.';
  }

  String _labelNominalRefundKartu(BookingModel booking) {
    final nominal = _formatRupiah(booking.cancellationRefundAmount!);
    if (!booking.danaTerverifikasi) {
      return 'Estimasi Pengembalian: Rp $nominal (menunggu verifikasi dana)';
    }
    if (booking.refundStatus?.toUpperCase() == 'SELESAI') {
      return 'Dana Dikembalikan: Rp $nominal';
    }
    return 'Pengembalian Dana: Rp $nominal';
  }

  String _labelTotalHarga(BookingModel booking) {
    if (booking.paymentStatus?.toUpperCase() == 'PAID' ||
        booking.status == BookingStatus.selesai) {
      return 'Total Dibayar';
    }
    return booking.isFinalTariffConfirmed
        ? 'Total Pembayaran'
        : 'Estimasi Total Biaya';
  }

  Widget? _buildRefundSecondaryBadge(BookingModel booking) {
    if (booking.status != BookingStatus.dibatalkan ||
        booking.refundStatus == null) {
      return null;
    }
    final status = booking.refundStatus!.toUpperCase();
    if (!booking.danaTerverifikasi) {
      return const StatusBadge(
        label: 'Verifikasi Dana',
        tone: StatusTone.warning,
        icon: Icons.hourglass_top_rounded,
      );
    }
    if (status == 'SELESAI') {
      return const StatusBadge(
        label: 'Refund Selesai',
        tone: StatusTone.success,
        icon: Icons.check_circle_outline_rounded,
      );
    }
    if (status == 'DIPROSES') {
      return const StatusBadge(
        label: 'Refund Diproses',
        tone: StatusTone.info,
        icon: Icons.sync_rounded,
      );
    }
    final adaRekening =
        (booking.cancellationBank?.trim().isNotEmpty ?? false) &&
        (booking.cancellationAccountNumber?.trim().isNotEmpty ?? false);
    if (!adaRekening) {
      return const StatusBadge(
        label: 'Perlu Isi Rekening',
        tone: StatusTone.warning,
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    return const StatusBadge(
      label: 'Menunggu Refund',
      tone: StatusTone.info,
      icon: Icons.schedule_rounded,
    );
  }

  Widget _buildStatusBadge(BookingModel booking) {
    if (booking.isDocumentRejected) {
      return const StatusBadge(
        label: 'Perlu Revisi Dokumen',
        tone: StatusTone.danger,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (booking.isPaymentRejected) {
      return const StatusBadge(
        label: 'Bukti Bayar Ditolak',
        tone: StatusTone.danger,
        icon: Icons.error_outline_rounded,
      );
    }

    switch (booking.status) {
      case BookingStatus.permintaanDiterima:
        return const StatusBadge(
          label: 'Menunggu Konfirmasi',
          tone: StatusTone.neutral,
          icon: Icons.hourglass_empty_rounded,
        );
      case BookingStatus.pemeriksaanArmada:
        return const StatusBadge(
          label: 'Pemeriksaan Armada',
          tone: StatusTone.neutral,
          icon: Icons.fact_check_outlined,
        );
      case BookingStatus.menungguTarifFinal:
        return const StatusBadge(
          label: 'Hitung Tarif Final',
          tone: StatusTone.warning,
          icon: Icons.calculate_outlined,
        );
      case BookingStatus.menungguPembayaran:
        if (booking.paymentStatus?.toUpperCase() == 'PENDING_VERIFICATION') {
          return const StatusBadge(
            label: 'Verifikasi Pembayaran',
            tone: StatusTone.info,
            icon: Icons.hourglass_top_rounded,
          );
        }
        return const StatusBadge(
          label: 'Menunggu Pembayaran',
          tone: StatusTone.warning,
          icon: Icons.schedule_rounded,
        );
      case BookingStatus.pembayaranSelesai:
        return const StatusBadge(
          label: 'Siap Serah Terima',
          tone: StatusTone.success,
          icon: Icons.verified_outlined,
        );
      case BookingStatus.verifikasiKantor:
        return const StatusBadge(
          label: 'Verifikasi Kantor',
          tone: StatusTone.info,
          icon: Icons.business_outlined,
        );
      case BookingStatus.mobilSiapDigunakan:
        return const StatusBadge(
          label: 'Mobil Siap Digunakan',
          tone: StatusTone.success,
          icon: Icons.directions_car_outlined,
        );
      case BookingStatus.selesai:
        return const StatusBadge(
          label: 'Selesai',
          tone: StatusTone.neutral,
          icon: Icons.task_alt,
        );
      case BookingStatus.dibatalkan:
        if (booking.isRejectedByAdmin) {
          return const StatusBadge(
            label: 'Ditolak Admin',
            tone: StatusTone.danger,
            icon: Icons.block_rounded,
          );
        }
        final actor = booking.cancelledBy?.toUpperCase();
        if (actor == 'ADMIN') {
          return const StatusBadge(
            label: 'Dibatalkan Admin',
            tone: StatusTone.danger,
            icon: Icons.cancel_outlined,
          );
        }
        if (actor == 'SYSTEM') {
          return const StatusBadge(
            label: 'Dibatalkan Otomatis',
            tone: StatusTone.neutral,
            icon: Icons.timer_off_outlined,
          );
        }
        return StatusBadge(
          label: actor == 'CUSTOMER' || actor == 'PELANGGAN'
              ? 'Dibatalkan Anda'
              : 'Dibatalkan',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined,
        );
    }
  }

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
