import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Kartu pilihan kendaraan di katalog dengan state seleksi aktif dan tombol favorit interaktif
class VehicleCardItem extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  const VehicleCardItem({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
    this.onToggleFavorite,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBodyLarge,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          // Tombol Bookmark / Favorit Interaktif (Target sentuh minimal 44px)
                          if (onToggleFavorite != null)
                            Semantics(
                              button: true,
                              label: vehicle.isFavorite
                                  ? 'Hapus ${vehicle.name} dari favorit'
                                  : 'Tambahkan ${vehicle.name} ke favorit',
                              child: InkWell(
                                onTap: onToggleFavorite,
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    vehicle.isFavorite
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    color: vehicle.isFavorite
                                        ? const Color(0xFFD97706) // Amber hangat
                                        : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.category} • ${vehicle.seatCapacity}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: vehicle.isAvailable
                                  ? AppColors.badgeGreenBg
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                              border: vehicle.isAvailable
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFFDE68A),
                                      width: 0.8,
                                    ),
                            ),
                            child: Text(
                              vehicle.isAvailable
                                  ? 'Tersedia'
                                  : (vehicle.isBooked ? 'Sedang Disewa' : vehicle.availabilityTag),
                              style: TextStyle(
                                fontSize: AppTypography.sizeMicro,
                                fontWeight: FontWeight.w600,
                                color: vehicle.isAvailable
                                    ? AppColors.badgeGreenText
                                    : const Color(0xFF92400E),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                const SizedBox(width: 10),
                // Thumbnail Gambar Mobil
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 106,
                    height: 74,
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


