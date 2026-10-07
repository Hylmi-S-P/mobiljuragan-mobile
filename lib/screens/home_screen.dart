import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import 'order_status_screen.dart';
import 'profile_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_selection_screen.dart';
import '../theme/app_typography.dart';

/// Halaman utama aplikasi pelanggan MobilJuragan
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPesan;

  const HomeScreen({super.key, this.onNavigateToPesan});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedOptionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final featuredVehicle = VehicleModel.sampleVehicles.first;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 18),
              _buildFeaturedCard(featuredVehicle),
              const SizedBox(height: 22),
              _buildReservationStatusSection(),
              const SizedBox(height: 16),
              _buildAssuranceBanner(),
              const SizedBox(height: 22),
              _buildPrimaryCTA(),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Tarif transparan • Konfirmasi instan via admin operasional',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLoggedIn ? AppColors.primaryTeal : AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: isLoggedIn ? null : Border.all(color: AppColors.borderSubtle, width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: isLoggedIn ? AppColors.textWhite : AppColors.textSecondary,
                  fontSize: AppTypography.sizeTitle,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ),
      ],
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
            // Wrap: badge plat nomor turun ke baris berikutnya saat ukuran teks
            // sistem diperbesar, bukan meluber keluar kartu.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TERPOPULER DI MERAUKE',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.badgeNavyBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vehicle.plateNumber,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
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
                child: Image.asset(
                  vehicle.heroImageUrl ?? vehicle.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.directions_car,
                        color: AppColors.textSecondary,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildOptionChip(index: 0, label: 'Lepas Kunci'),
                const SizedBox(width: 8),
                _buildOptionChip(index: 1, label: 'Dengan Sopir'),
                const SizedBox(width: 8),
                _buildOptionChip(index: 2, label: 'Antar Bandara'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip({required int index, required String label}) {
    final bool isSelected = _selectedOptionIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOptionIndex = index;
          });
          final booking = context.read<BookingController>();
          booking.toggleDriver(index == 1);
          if (index == 2) {
            booking.setPickupLocation('Bandara Mopah Merauke', -8.5202, 140.4180);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTeal : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryTeal : AppColors.borderSubtle,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
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
            InkWell(
              onTap: () {
                if (hasActive) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderStatusScreen(booking: activeOrder),
                    ),
                  );
                } else if (widget.onNavigateToPesan != null) {
                  widget.onNavigateToPesan!();
                }
              },
              child: Text(
                hasActive ? 'Detail Status ›' : 'Pesan Baru ›',
                style: const TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            if (hasActive) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderStatusScreen(booking: activeOrder),
                ),
              );
            } else if (widget.onNavigateToPesan != null) {
              widget.onNavigateToPesan!();
            }
          },
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
                        : AppColors.primaryTeal)
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
                        ? (activeOrder.status == BookingStatus.mobilSiapDigunakan
                            ? const Color(0xFFDCFCE7)
                            : AppColors.badgeNavyBg)
                        : AppColors.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      hasActive
                          ? (activeOrder.status == BookingStatus.mobilSiapDigunakan
                              ? Icons.key
                              : Icons.directions_car)
                          : Icons.receipt_long,
                      color: hasActive
                          ? (activeOrder.status == BookingStatus.mobilSiapDigunakan
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
                            color: activeOrder.status == BookingStatus.mobilSiapDigunakan
                                ? const Color(0xFF15803D)
                                : AppColors.primaryTeal,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasActive)
                  _buildReservationStatusBadge(activeOrder.status)
                else
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getReservationSubtitleHint(BookingModel order) {
    switch (order.status) {
      case BookingStatus.menungguTarifFinal:
        return 'Admin sedang menghitung rincian tarif final';
      case BookingStatus.menungguPembayaran:
        return 'Rincian tarif terbit, silakan selesaikan pembayaran di aplikasi';
      case BookingStatus.pembayaranSelesai:
        return 'Pembayaran terkonfirmasi, armada disiapkan';
      case BookingStatus.mobilSiapDigunakan:
        return 'Kunci siap diserahterimakan di ${order.pickupLocation}';
      default:
        return 'Jadwal sewa unit terkonfirmasi';
    }
  }

  Widget _buildReservationStatusBadge(BookingStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case BookingStatus.mobilSiapDigunakan:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'SIAP PAKAI';
        break;
      case BookingStatus.menungguPembayaran:
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFB91C1C);
        label = 'MENUNGGU BAYAR';
        break;
      case BookingStatus.menungguTarifFinal:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'HITUNG TARIF';
        break;
      case BookingStatus.pembayaranSelesai:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = 'LUNAS';
        break;
      default:
        bg = AppColors.tealLight;
        text = AppColors.primaryTeal;
        label = 'AKTIF';
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

  Widget _buildAssuranceBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.check, color: AppColors.primaryTeal, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Armada Bersih, Terawat & Sopir Ramah',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gratis antar-jemput Bandara Mopah & Hotel Kota',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w400,
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

  Widget _buildPrimaryCTA() {
    return SizedBox(
      width: double.infinity,
      height: 48,
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
                style: TextStyle(
                  fontSize: AppTypography.sizeTitle,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
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
