import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Komponen Empty State untuk Riwayat Pesanan (Frame 08b)
/// Ditampilkan saat pengguna belum memiliki pesanan aktif maupun riwayat selesai
class OrderEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final String ctaText;
  final VoidCallback onCtaPressed;

  const OrderEmptyState({
    super.key,
    this.title = 'Belum Ada Riwayat Pemesanan',
    this.description =
        'Anda belum memiliki jadwal rental aktif maupun riwayat sewa sebelumnya. Semua pesanan armada MobilJuragan di Merauke akan tersimpan otomatis di sini.',
    this.ctaText = 'Pesan Mobil Sekarang',
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long_outlined,
                size: 30,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrustPointItem(text: 'Armada prima siap antar di Bandara Mopah'),
                SizedBox(height: 6),
                _TrustPointItem(text: 'Pilihan lepas kunci atau dengan sopir resmi'),
                SizedBox(height: 6),
                _TrustPointItem(text: 'Tarif transparan dengan konfirmasi instan'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mulai perjalanan pertama Anda bersama kami di Merauke.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onCtaPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                ctaText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustPointItem extends StatelessWidget {
  final String text;

  const _TrustPointItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTeal,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
