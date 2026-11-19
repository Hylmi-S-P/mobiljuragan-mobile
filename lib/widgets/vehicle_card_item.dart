import 'package:flutter/material.dart';
import '../core/constants/status_labels.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'gambar_kendaraan.dart';
import 'order_state_banner.dart';

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
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
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
                                        ? AppColors.primaryNavy
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
                      StatusBadge(
                        tone: vehicle.isAvailable ? StatusTone.success : StatusTone.warning,
                        label: vehicle.isAvailable
                            ? 'Tersedia'
                            : vehicleAvailabilityLabel(vehicle.availability),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Rp ${_formatRupiah(vehicle.pricePerDay)}',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeBodyLarge,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const Text(
                            ' / hari',
                            style: TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
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
                    child: GambarKendaraan(
                      sumber: vehicle.imageUrl,
                      fit: BoxFit.cover,
                      cadangan: Center(
                        child: Icon(
                          Icons.directions_car,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          size: 32,
                        ),
                      ),
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


