import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Nada semantik status di seluruh aplikasi MobilJuragan.
enum StatusTone { neutral, info, warning, danger, success }

class _StatusPalette {
  final Color bg;
  final Color fg;
  final Color border;

  const _StatusPalette(this.bg, this.fg, this.border);
}

_StatusPalette _paletteFor(StatusTone tone) {
  switch (tone) {
    case StatusTone.info:
      return const _StatusPalette(
        AppColors.statusInfoBg,
        AppColors.statusInfoFg,
        AppColors.statusInfoBorder,
      );
    case StatusTone.warning:
      return const _StatusPalette(
        AppColors.statusWarningBg,
        AppColors.statusWarningFg,
        AppColors.statusWarningBorder,
      );
    case StatusTone.danger:
      return const _StatusPalette(
        AppColors.statusDangerBg,
        AppColors.statusDangerFg,
        AppColors.statusDangerBorder,
      );
    case StatusTone.success:
      return const _StatusPalette(
        AppColors.statusSuccessBg,
        AppColors.statusSuccessFg,
        AppColors.statusSuccessBorder,
      );
    case StatusTone.neutral:
      return const _StatusPalette(
        AppColors.statusNeutralBg,
        AppColors.statusNeutralFg,
        AppColors.statusNeutralBorder,
      );
  }
}

/// Badge status bertoken dengan kontras WCAG AA dan dukungan ikon opsional.
class StatusBadge extends StatelessWidget {
  final StatusTone tone;
  final String label;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.tone,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = _paletteFor(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: p.fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w700,
                color: p.fg,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner status untuk pemberitahuan pesanan, dokumen, ketersediaan, dan refund.
class OrderStateBanner extends StatelessWidget {
  final StatusTone tone;
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const OrderStateBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = _paletteFor(tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: p.fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w700,
                    color: p.fg,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w400,
                    color: p.fg,
                    height: 1.45,
                    fontFamily: 'Inter',
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
