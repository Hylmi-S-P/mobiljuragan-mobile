import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        'Plat Nomor: ${vehicle.plateNumber}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildVehicleImageCard(),
                  const SizedBox(height: 16),
                  _buildSpecsGrid(),
                  const SizedBox(height: 16),
                  _buildTariffInfoBox(bookingController),
                  const SizedBox(height: 12),
                  _buildRequirementNoteBox(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildStickyCTA(context),
        ],
      ),
    );
  }

  Widget _buildVehicleImageCard() {
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
          vehicle.detailImageUrl ?? vehicle.imageUrl,
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

  Widget _buildSpecsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SpecCardItem(
                label: 'Kapasitas Kursi',
                value: vehicle.seatCapacity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SpecCardItem(
                label: 'Tipe Transmisi',
                value: vehicle.transmission,
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
                value: vehicle.bodyType,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SpecCardItem(
                label: 'Status Unit',
                value: 'Tersedia',
                valueColor: AppColors.badgeGreenText,
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
                'Tarif Sewa Terhitung (Sistem Resmi)',
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

  Widget _buildStickyCTA(BuildContext context) {
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
            onPressed: () {
              context.read<BookingController>().selectVehicle(vehicle);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RentalOptionsScreen(vehicle: vehicle),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Lanjut ke Opsi Rental',
              style: TextStyle(
                fontSize: AppTypography.sizeTitle,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
