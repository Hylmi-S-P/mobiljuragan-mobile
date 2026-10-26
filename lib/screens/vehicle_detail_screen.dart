import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/spec_card_item.dart';
import 'rental_options_screen.dart';
import '../theme/app_typography.dart';

/// Layar detail spesifikasi armada kendaraan
class VehicleDetailScreen extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final bookingController = context.watch<BookingController>();
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: currentVehicle.isAvailable
                                    ? AppColors.badgeGreenBg
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: currentVehicle.isAvailable
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFFDE68A),
                                        width: 0.8,
                                      ),
                              ),
                              child: Text(
                                currentVehicle.isAvailable
                                    ? 'Tersedia'
                                    : (currentVehicle.isBooked ? 'Tersewa' : currentVehicle.availabilityTag),
                                style: TextStyle(
                                  fontSize: AppTypography.sizeCaption,
                                  fontWeight: FontWeight.w600,
                                  color: currentVehicle.isAvailable
                                      ? AppColors.badgeGreenText
                                      : const Color(0xFF92400E),
                                  fontFamily: 'Inter',
                                ),
                              ),
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
                                  ? const Color(0xFFFEF3C7)
                                  : AppColors.cardWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentVehicle.isFavorite
                                    ? const Color(0xFFF59E0B)
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Icon(
                              currentVehicle.isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              color: currentVehicle.isFavorite
                                  ? const Color(0xFFD97706)
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
                    _buildOccupiedWarningBanner(currentVehicle),
                    const SizedBox(height: 16),
                  ],
                  _buildVehicleImageCard(currentVehicle),
                  const SizedBox(height: 16),
                  _buildSpecsGrid(currentVehicle),
                  const SizedBox(height: 16),
                  _buildTariffInfoBox(bookingController),
                  const SizedBox(height: 12),
                  _buildRequirementNoteBox(),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          currentVehicle.detailImageUrl ?? currentVehicle.imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.directions_car,
                color: AppColors.textSecondary,
                size: 64,
              ),
            );
          },
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
                    : (currentVehicle.isBooked ? 'Tersewa' : currentVehicle.availabilityTag),
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

  Widget _buildTariffInfoBox(BookingController bookingController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap, bukan Row: saat ukuran teks sistem diperbesar, nominal tarif
          // turun ke baris berikutnya alih-alih bertabrakan dengan labelnya.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              const Text(
                'Tarif Sewa Terhitung',
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'Rp ${vehicle.pricePerDay ~/ 1000}.000 / hari',
                style: const TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tarif resmi terhubung langsung dengan sistem reservasi MobilJuragan Merauke.',
            style: TextStyle(
              fontSize: AppTypography.sizeCaption,
              fontWeight: FontWeight.w400,
              color: Color(0xFF3B82F6),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: const Text(
        'Pastikan tipe mobil dan plat nomor sesuai kebutuhan sebelum menentukan opsi rental.',
        style: TextStyle(
          fontSize: AppTypography.sizeCaption,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildOccupiedWarningBanner(VehicleModel currentVehicle) {
    final bool isBooked = currentVehicle.isBooked;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB45309),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBooked ? 'Armada Sedang Tersewa' : 'Armada Sedang Tidak Tersedia',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBooked
                      ? 'Unit ini telah dipesan dan disewa oleh pelanggan lain. Anda tetap dapat mempelajari spesifikasi armada di bawah ini, namun reservasi unit ini sementara dikunci.'
                      : 'Unit ini sementara tidak dapat dipesan. Silakan pilih armada lain yang tersedia pada katalog.',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF78350F),
                    fontFamily: 'Inter',
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCTA(BuildContext context, VehicleModel currentVehicle) {
    final bool canProceed = currentVehicle.isAvailable;

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
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              canProceed ? 'Lanjut ke Opsi Rental' : 'Armada Sedang Tidak Tersedia',
              style: TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: canProceed ? AppColors.textWhite : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
