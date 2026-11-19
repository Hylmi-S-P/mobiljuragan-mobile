import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'order_state_banner.dart';
import 'standard_bottom_sheet.dart';

/// Lima keadaan visual komponen unggah berkas terpadu.
enum DocumentUploadState {
  empty,
  previewSelected,
  waitingVerification,
  rejected,
  approved,
}

/// Baris unggah dokumen ringkas yang seragam untuk KTP, SIM A, Surat
/// Pernyataan, revisi berkas, dan bukti pembayaran.
///
/// Mempertahankan tinggi ringkas satu baris, sambil menampilkan thumbnail
/// pratinjau 44×44 px yang dapat diketuk untuk melihat berkas ukuran penuh.
class UnifiedDocumentUploader extends StatelessWidget {
  final String title;
  final String subtitle;
  final DocumentUploadState state;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback? onRemove;
  final Widget? secondaryAction;
  final String? rejectionReason;
  final Uint8List? previewBytes;
  final String? previewImageUrl;

  const UnifiedDocumentUploader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.icon,
    this.onAction,
    this.actionLabel,
    this.onRemove,
    this.secondaryAction,
    this.rejectionReason,
    this.previewBytes,
    this.previewImageUrl,
  });

  bool get _hasPreview =>
      previewBytes != null || (previewImageUrl != null && previewImageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.containerBg,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: style.borderColor, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 260;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildLeadingBox(context, style),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: style.subtitleWeight,
                            color: style.subtitleColor,
                            height: 1.35,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    _buildTrailingControl(style),
                  ],
                ],
              ),
              if (isCompact &&
                  !(onAction == null && secondaryAction != null)) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildTrailingControl(style),
                ),
              ],
              if (state == DocumentUploadState.rejected &&
                  rejectionReason != null &&
                  rejectionReason!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Catatan staf: ${rejectionReason!.trim()}',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusDangerFg,
                    height: 1.4,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
              if (secondaryAction != null) ...[
                const SizedBox(height: 8),
                secondaryAction!,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeadingBox(BuildContext context, _UploaderStyle style) {
    final thumb = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: style.iconBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasPreview ? AppColors.accent : AppColors.borderSubtle,
          width: _hasPreview ? 1.2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildThumbContent(style),
    );

    if (!_hasPreview) return thumb;

    return Semantics(
      button: true,
      label: 'Lihat pratinjau $title',
      child: InkWell(
        onTap: () => _showFullPreview(context),
        borderRadius: BorderRadius.circular(8),
        child: thumb,
      ),
    );
  }

  Widget _buildThumbContent(_UploaderStyle style) {
    if (previewBytes != null) {
      return Image.memory(
        previewBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(icon, size: 20, color: style.iconColor),
      );
    }
    if (previewImageUrl != null && previewImageUrl!.isNotEmpty) {
      return Image.network(
        previewImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, _, _) => Icon(icon, size: 20, color: style.iconColor),
      );
    }
    return Icon(icon, size: 20, color: style.iconColor);
  }

  Widget _buildTrailingControl(_UploaderStyle style) {
    if (state == DocumentUploadState.approved && onAction == null) {
      return const StatusBadge(
        tone: StatusTone.success,
        label: 'Selesai',
        icon: Icons.check_circle_outline_rounded,
      );
    }

    if (onAction == null && secondaryAction != null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRemove != null && state == DocumentUploadState.previewSelected)
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: 'Hapus berkas',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
          ),
        Flexible(
          child: OutlinedButton(
            onPressed: state == DocumentUploadState.approved ? null : onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: style.buttonFg,
              side: style.buttonSide,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
            ),
            child: Text(
              actionLabel ?? style.defaultButtonText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeBody,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullPreview(BuildContext context) {
    StandardBottomSheet.show(
      context: context,
      title: 'Pratinjau $title',
      subtitle: subtitle,
      icon: Icons.image_outlined,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180, maxHeight: 380),
          color: AppColors.surfaceLight,
          child: previewBytes != null
              ? Image.memory(
                  previewBytes!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const _PreviewErrorPlaceholder(),
                )
              : Image.network(
                  previewImageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, _, _) => const _PreviewErrorPlaceholder(),
                ),
        ),
      ),
    );
  }

  _UploaderStyle _resolveStyle() {
    switch (state) {
      case DocumentUploadState.previewSelected:
        return const _UploaderStyle(
          containerBg: AppColors.accentSoft,
          borderColor: AppColors.accent,
          iconBg: AppColors.cardWhite,
          iconColor: AppColors.accent,
          subtitleColor: AppColors.accent,
          subtitleWeight: FontWeight.w600,
          defaultButtonText: 'Ganti',
          buttonFg: AppColors.primaryNavy,
          buttonSide: BorderSide(color: AppColors.borderMedium),
        );
      case DocumentUploadState.waitingVerification:
        return const _UploaderStyle(
          containerBg: AppColors.cardWhite,
          borderColor: AppColors.borderSubtle,
          iconBg: AppColors.surfaceLight,
          iconColor: AppColors.primaryNavy,
          subtitleColor: AppColors.textSecondary,
          subtitleWeight: FontWeight.w500,
          defaultButtonText: 'Ubah',
          buttonFg: AppColors.primaryNavy,
          buttonSide: BorderSide(color: AppColors.borderMedium),
        );
      case DocumentUploadState.rejected:
        return const _UploaderStyle(
          containerBg: AppColors.statusDangerBg,
          borderColor: AppColors.statusDangerBorder,
          iconBg: AppColors.cardWhite,
          iconColor: AppColors.statusDangerFg,
          subtitleColor: AppColors.statusDangerFg,
          subtitleWeight: FontWeight.w600,
          defaultButtonText: 'Unggah Ulang',
          buttonFg: AppColors.primaryNavy,
          buttonSide: BorderSide(color: AppColors.primaryNavy, width: 1.2),
        );
      case DocumentUploadState.approved:
        return const _UploaderStyle(
          containerBg: Color(0xFFF0FDF4),
          borderColor: AppColors.statusSuccessBorder,
          iconBg: AppColors.statusSuccessBg,
          iconColor: AppColors.statusSuccessFg,
          subtitleColor: AppColors.statusSuccessFg,
          subtitleWeight: FontWeight.w600,
          defaultButtonText: 'Selesai',
          buttonFg: AppColors.statusSuccessFg,
          buttonSide: BorderSide(color: AppColors.statusSuccessBorder),
        );
      case DocumentUploadState.empty:
        return const _UploaderStyle(
          containerBg: AppColors.cardWhite,
          borderColor: AppColors.borderSubtle,
          iconBg: AppColors.surfaceLight,
          iconColor: AppColors.textSecondary,
          subtitleColor: AppColors.textSecondary,
          subtitleWeight: FontWeight.w400,
          defaultButtonText: 'Unggah',
          buttonFg: AppColors.primaryNavy,
          buttonSide: BorderSide(color: AppColors.borderMedium),
        );
    }
  }
}

class _PreviewErrorPlaceholder extends StatelessWidget {
  const _PreviewErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Pratinjau gambar tidak dapat dimuat. Tarik layar untuk menyegarkan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTypography.sizeBody,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _UploaderStyle {
  final Color containerBg;
  final Color borderColor;
  final Color iconBg;
  final Color iconColor;
  final Color subtitleColor;
  final FontWeight subtitleWeight;
  final String defaultButtonText;
  final Color buttonFg;
  final BorderSide buttonSide;

  const _UploaderStyle({
    required this.containerBg,
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.subtitleColor,
    required this.subtitleWeight,
    required this.defaultButtonText,
    required this.buttonFg,
    required this.buttonSide,
  });
}
