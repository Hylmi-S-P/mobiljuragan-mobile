import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../core/constants/status_labels.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/order_state_banner.dart';
import '../widgets/spec_card_item.dart';
import 'rental_options_screen.dart';
import '../theme/app_typography.dart';
import '../widgets/gambar_kendaraan.dart';

/// Layar detail spesifikasi armada kendaraan
class VehicleDetailScreen extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleController = context.watch<VehicleController>();
    final currentVehicle = vehicleController.getById(vehicle.id) ?? vehicle;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Detail Kendaraan',
        stepSubtitle: 'Langkah 1 dari 4',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentVehicle.name,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeHeading,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Plat Nomor: ${currentVehicle.plateNumber} • ${currentVehicle.category}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusBadge(
                                  tone: currentVehicle.isAvailable
                                      ? StatusTone.success
                                      : StatusTone.warning,
                                  label: currentVehicle.isAvailable
                                      ? 'Tersedia'
                                      : vehicleAvailabilityLabel(currentVehicle.availability),
                                ),
                                Text(
                                  'Rp ${_formatRupiah(currentVehicle.pricePerDay)} / hari',
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeAmount,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: currentVehicle.isFavorite ? 'Hapus favorit' : 'Tambah favorit',
                        child: InkWell(
                          onTap: () => vehicleController.toggleFavorite(currentVehicle.id),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: currentVehicle.isFavorite
                                  ? AppColors.accentSoft
                                  : AppColors.cardWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentVehicle.isFavorite
                                    ? AppColors.accentMuted
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Icon(
                              currentVehicle.isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              color: currentVehicle.isFavorite
                                  ? AppColors.primaryNavy
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!currentVehicle.isAvailable) ...[
                    _buildOccupiedWarningBanner(context, currentVehicle),
                    const SizedBox(height: 16),
                  ],
                  _buildVehicleImageCard(currentVehicle),
                  const SizedBox(height: 16),
                  _buildSpecsGrid(currentVehicle),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildStickyCTA(context, currentVehicle),
        ],
      ),
    );
  }

  Widget _buildVehicleImageCard(VehicleModel currentVehicle) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: GambarKendaraan(
          sumber: currentVehicle.detailImageUrl ?? currentVehicle.imageUrl,
          fit: BoxFit.contain,
          cadangan: const Center(
            child: Icon(
              Icons.directions_car,
              color: AppColors.textSecondary,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsGrid(VehicleModel currentVehicle) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SpecCardItem(
                label: 'Kapasitas Kursi',
                value: currentVehicle.seatCapacity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SpecCardItem(
                label: 'Tipe Transmisi',
                value: currentVehicle.transmission,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SpecCardItem(
                label: 'Kategori Bodi',
                value: currentVehicle.bodyType,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SpecCardItem(
                label: 'Status Unit',
                value: currentVehicle.isAvailable
                    ? 'Tersedia'
                    : vehicleAvailabilityLabel(currentVehicle.availability),
                valueColor: currentVehicle.isAvailable
                    ? AppColors.badgeGreenText
                    : const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOccupiedWarningBanner(BuildContext context, VehicleModel currentVehicle) {
    final bool isBooked = currentVehicle.isBooked;
    final bool isInService = currentVehicle.isInService;

    final String bannerTitle = isBooked
        ? 'Armada Sedang Disewa'
        : isInService
            ? 'Armada Dalam Pemeriksaan Pasca-Sewa'
            : 'Armada Sedang Tidak Tersedia';

    final String bannerMessage = isBooked
        ? 'Unit ini telah dipesan dan disewa oleh pelanggan lain. Anda tetap dapat mempelajari spesifikasi armada di bawah ini, namun reservasi unit ini sementara dikunci.'
        : isInService
            ? 'Unit ini baru kembali dari penyewaan dan sedang menjalani pemeriksaan kelayakan maksimal 6 jam di garasi sebelum dapat dipesan kembali.'
            : 'Unit ini sementara tidak dapat dipesan. Silakan pilih armada lain yang tersedia pada katalog.';

    return OrderStateBanner(
      tone: StatusTone.warning,
      icon: Icons.info_outline_rounded,
      title: bannerTitle,
      message: bannerMessage,
    );
  }

  Widget _buildStickyCTA(BuildContext context, VehicleModel currentVehicle) {
    final bool canProceed = currentVehicle.isAvailable;
    final String disabledLabel = currentVehicle.isInService
        ? 'Sedang Dalam Pemeriksaan'
        : 'Armada Sedang Tidak Tersedia';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
          child: ElevatedButton(
            onPressed: canProceed
                ? () {
                    context.read<BookingController>().selectVehicle(currentVehicle);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RentalOptionsScreen(vehicle: currentVehicle),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: AppColors.textWhite,
              disabledBackgroundColor: AppColors.borderSubtle,
              disabledForegroundColor: AppColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              elevation: 0,
            ),
            child: Text(
              canProceed ? 'Lanjut ke Opsi Rental' : disabledLabel,
              style: TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: canProceed ? AppColors.textWhite : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
