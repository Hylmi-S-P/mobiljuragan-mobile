import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'order_status_screen.dart';
import 'profile_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_selection_screen.dart';
import '../theme/app_typography.dart';
import '../widgets/gambar_kendaraan.dart';

/// Halaman utama aplikasi pelanggan MobilJuragan
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPesan;

  const HomeScreen({super.key, this.onNavigateToPesan});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final vehicleController = context.watch<VehicleController>();
    final featuredVehicle = vehicleController.vehicles.isNotEmpty
        ? vehicleController.vehicles.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 18),
              if (featuredVehicle != null)
                _buildFeaturedCard(featuredVehicle)
              else
                _buildKartuKosong(),
              const SizedBox(height: 22),
              _buildReservationStatusSection(),
              const SizedBox(height: 16),
              _buildPrimaryCTA(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final auth = context.watch<AuthController>();
    final isLoggedIn = auth.isLoggedIn && auth.currentUser != null;
    final initials = isLoggedIn ? (auth.currentUser!.avatarInitials) : 'MJ';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Expanded: teks lokasi menyusut dengan ellipsis saat ukuran teks
        // sistem diperbesar, bukan mendorong avatar keluar layar.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MobilJuragan',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Merauke, Papua Selatan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.sizeHeading,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLoggedIn
                      ? AppColors.primaryNavy
                      : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: isLoggedIn
                      ? null
                      : Border.all(color: AppColors.borderSubtle, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isLoggedIn
                          ? AppColors.textWhite
                          : AppColors.textSecondary,
                      fontSize: AppTypography.sizeTitle,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /*
   * Ditampilkan saat katalog masih kosong.
   *
   * Sebelumnya bagian ini selalu terisi karena ada sembilan unit contoh di
   * dalam kode. Sekarang, kalau admin belum menambahkan armada, pelanggan
   * melihat keterangan yang jujur dan tombol muat ulang.
   */
  Widget _buildKartuKosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Armada belum tersedia',
            style: TextStyle(
              fontSize: AppTypography.sizeHeading,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Daftar kendaraan akan tampil di sini setelah admin menambahkan unit ke katalog.',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.read<VehicleController>().refreshCatalog(force: true);
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Muat ulang katalog'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(VehicleModel vehicle) {
    return InkWell(
      onTap: () {
        context.read<BookingController>().selectVehicle(vehicle);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VehicleDetailScreen(vehicle: vehicle),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'TERPOPULER DI MOBILJURAGAN',
                style: TextStyle(
                  fontSize: AppTypography.sizeTiny,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.name,
              style: const TextStyle(
                fontSize: AppTypography.sizeHeading,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${vehicle.bodyType} • ${vehicle.seatCapacity} • ${vehicle.transmission}',
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 130,
                width: double.infinity,
                color: AppColors.surfaceLight,
                child: GambarKendaraan(
                  sumber: vehicle.heroImageUrl ?? vehicle.imageUrl,
                  fit: BoxFit.contain,
                  lebarLogis: 320,
                  tinggiLogis: 130,
                  cadangan: const Center(
                    child: Icon(
                      Icons.directions_car,
                      color: AppColors.textSecondary,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationStatusSection() {
    final booking = context.watch<BookingController>();
    final activeOrder = booking.activeBooking;
    final hasActive = booking.hasActiveBooking && activeOrder != null;
    final vehicle = activeOrder?.vehicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Reservasi',
          style: TextStyle(
            fontSize: AppTypography.sizeTitle,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: hasActive
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderStatusScreen(booking: activeOrder),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasActive
                    ? (activeOrder.status == BookingStatus.mobilSiapDigunakan
                          ? const Color(0xFF16A34A)
                          : AppColors.primaryNavy)
                    : AppColors.borderSubtle,
                width: hasActive ? 1.5 : 1,
              ),
              boxShadow: hasActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasActive
                        ? (activeOrder.status ==
                                  BookingStatus.mobilSiapDigunakan
                              ? const Color(0xFFDCFCE7)
                              : AppColors.badgeNavyBg)
                        : AppColors.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      hasActive
                          ? (activeOrder.status ==
                                    BookingStatus.mobilSiapDigunakan
                                ? Icons.key
                                : Icons.directions_car)
                          : Icons.receipt_long,
                      color: hasActive
                          ? (activeOrder.status ==
                                    BookingStatus.mobilSiapDigunakan
                                ? const Color(0xFF15803D)
                                : AppColors.textWhite)
                          : AppColors.primaryTeal,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasActive
                            ? (vehicle?.name ?? 'Sewa Aktif Berjalan')
                            : 'Belum ada sewa aktif',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasActive
                            ? 'Kode: ${activeOrder.id} • ${activeOrder.durationDays} Hari (${activeOrder.modeLabel})'
                            : 'Pilih armada siap pakai di Merauke',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (hasActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getReservationSubtitleHint(activeOrder),
                          style: TextStyle(
                            fontSize: AppTypography.sizeTiny,
                            fontWeight: FontWeight.w500,
                            color:
                                activeOrder.status ==
                                    BookingStatus.mobilSiapDigunakan
                                ? const Color(0xFF15803D)
                                : AppColors.primaryNavy,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasActive) _buildReservationStatusBadge(activeOrder),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getReservationSubtitleHint(BookingModel order) {
    final payStatus = order.paymentStatus?.toUpperCase();
    switch (order.status) {
      case BookingStatus.permintaanDiterima:
        return 'Pengajuan sewa sedang ditinjau admin';
      case BookingStatus.pemeriksaanArmada:
        return 'Armada sedang diperiksa sebelum serah terima';
      case BookingStatus.menungguTarifFinal:
        return 'Admin sedang menghitung rincian tarif final';
      case BookingStatus.menungguPembayaran:
        if (payStatus == 'PENDING_VERIFICATION') {
          return 'Bukti pembayaran sedang diverifikasi admin';
        }
        if (payStatus == 'FAILED') {
          return 'Bukti pembayaran ditolak, silakan unggah ulang';
        }
        return 'Rincian tarif terbit, silakan selesaikan pembayaran di aplikasi';
      case BookingStatus.pembayaranSelesai:
      case BookingStatus.verifikasiKantor:
        return 'Pembayaran terkonfirmasi, armada disiapkan';
      case BookingStatus.mobilSiapDigunakan:
        /* Mode dengan sopir tidak menyerahkan kunci, jadi kalimatnya dibedakan:
           "kunci siap diserahterimakan" hanya benar untuk lepas kunci. */
        return order.withDriver
            ? 'Sopir siap menjemput Anda di ${order.pickupLocation}'
            : 'Kunci siap diserahterimakan di ${order.pickupLocation}';
      case BookingStatus.selesai:
        return 'Masa sewa telah selesai';
      case BookingStatus.dibatalkan:
        return 'Pengajuan sewa telah dibatalkan';
    }
  }

  Widget _buildReservationStatusBadge(BookingModel order) {
    final payStatus = order.paymentStatus?.toUpperCase();
    Color bg;
    Color text;
    String label;

    switch (order.status) {
      case BookingStatus.permintaanDiterima:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'MENUNGGU';
        break;
      case BookingStatus.pemeriksaanArmada:
        bg = AppColors.tealLight;
        text = AppColors.primaryTeal;
        label = 'DISIAPKAN';
        break;
      case BookingStatus.mobilSiapDigunakan:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'SIAP PAKAI';
        break;
      case BookingStatus.menungguPembayaran:
        if (payStatus == 'PENDING_VERIFICATION') {
          bg = AppColors.tealLight;
          text = AppColors.primaryTeal;
          label = 'VERIFIKASI BAYAR';
        } else if (payStatus == 'FAILED') {
          bg = const Color(0xFFFEF2F2);
          text = const Color(0xFFB91C1C);
          label = 'BUKTI DITOLAK';
        } else {
          bg = AppColors.badgeAmberBg;
          text = AppColors.badgeAmberText;
          label = 'MENUNGGU BAYAR';
        }
        break;
      case BookingStatus.menungguTarifFinal:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'HITUNG TARIF';
        break;
      case BookingStatus.pembayaranSelesai:
      case BookingStatus.verifikasiKantor:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = 'LUNAS';
        break;
      case BookingStatus.selesai:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        label = 'SELESAI';
        break;
      case BookingStatus.dibatalkan:
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFB91C1C);
        label = 'BATAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeTiny,
          fontWeight: FontWeight.w700,
          color: text,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildPrimaryCTA() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
      child: ElevatedButton(
        onPressed: () {
          if (widget.onNavigateToPesan != null) {
            widget.onNavigateToPesan!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VehicleSelectionScreen(),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flexible: label menyusut dengan ellipsis agar tidak meluber
            // saat ukuran teks sistem diperbesar.
            Flexible(
              child: Text(
                'Pesan Mobil Sekarang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
