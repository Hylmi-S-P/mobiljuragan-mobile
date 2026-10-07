import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Kartu pilihan kendaraan di katalog dengan state seleksi aktif teal
class VehicleCardItem extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleCardItem({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryTeal : AppColors.borderSubtle,
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Info Kolom Kiri
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
                      const SizedBox(height: 4),
                      Text(
                        'Plat ${vehicle.plateNumber} • ${vehicle.seatCapacity}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tersedia',
                        style: TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatRupiah(vehicle.pricePerDay)} / hari',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Thumbnail Gambar Mobil
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 110,
                    height: 76,
                    color: AppColors.surfaceLight,
                    child: Image.asset(
                      vehicle.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.directions_car,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
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
