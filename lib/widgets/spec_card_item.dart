import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Kartu spesifikasi kendaraan untuk grid 2x2 di layar Detail Kendaraan
class SpecCardItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const SpecCardItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.sizeCaption,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
            // Dua baris: nilai panjang seperti "5 Penumpang (Double Cabin)"
            // tetap terbaca utuh, tidak dipotong di tengah kata.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
