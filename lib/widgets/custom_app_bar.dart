import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// App Bar khusus bertema Navy dengan tombol kembali dan teks langkah stepper
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? stepSubtitle;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.stepSubtitle,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
  });

  /// Tinggi dasar header pada skala teks normal (1.0).
  static const double _baseHeight = 64;

  /// Batas tinggi agar header tidak memakan layar saat teks diperbesar ekstrem.
  static const double _maxHeight = 120;

  /// Tinggi header mengikuti skala font perangkat. Tanpa ini judul dan subjudul
  /// langkah terpotong pada perangkat yang memakai ukuran teks sistem > 1.0.
  static double _resolveHeight() {
    double scale = 1;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      scale = MediaQueryData.fromView(view).textScaler.scale(1);
    }
    return (_baseHeight * scale).clamp(_baseHeight, _maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryNavy,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              if (showBackButton && (onBackPressed != null || Navigator.canPop(context)))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textWhite, size: 18),
                  onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
                  tooltip: 'Kembali',
                )
              else
                const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: AppTypography.sizeHeading,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (stepSubtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        stepSubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textWhite.withValues(alpha: 0.75),
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_resolveHeight());
}
