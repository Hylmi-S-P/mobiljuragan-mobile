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
  final Widget? titleWidget;

  const CustomAppBar({
    super.key,
    required this.title,
    this.stepSubtitle,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.titleWidget,
  });

  /// Tinggi dasar header pada skala teks normal (1.0).
  static const double _baseHeightSingle = 64;
  static const double _baseHeightWithSubtitle = 76;

  /// Batas tinggi agar header tidak memakan layar saat teks diperbesar ekstrem.
  static const double _maxHeight = 120;

  /// Tinggi header mengikuti skala font perangkat. Tanpa ini judul dan subjudul
  /// langkah terpotong pada perangkat yang memakai ukuran teks sistem > 1.0.
  double _resolveHeight() {
    final base = (stepSubtitle != null || titleWidget != null)
        ? _baseHeightWithSubtitle
        : _baseHeightSingle;
    double scale = 1;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      scale = MediaQueryData.fromView(view).textScaler.scale(1);
    }
    return (base * scale).clamp(base, _maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = showBackButton && (onBackPressed != null || Navigator.canPop(context));
    final resolvedMinHeight = (stepSubtitle != null || titleWidget != null)
        ? _baseHeightWithSubtitle
        : _baseHeightSingle;

    return Container(
      color: AppColors.primaryNavy,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: resolvedMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                if (canGoBack)
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textWhite, size: 18),
                    onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
                    tooltip: 'Kembali',
                  )
                else
                  const SizedBox(width: 16),
                Expanded(
                  child: titleWidget ??
                      Column(
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
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: AppTypography.sizeBody,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ],
                      ),
                ),
                if (actions != null) ...actions! else if (!canGoBack) const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_resolveHeight());
}
