import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Chip hitungan mundur batas waktu pembayaran.
///
/// Sebelumnya angka ini dihitung di dalam `build` milik layar status pesanan,
/// sehingga detiknya hanya berubah ketika ada hal lain yang memicu `setState` —
/// dalam praktiknya setiap 30 detik saat polling. Akibatnya hitungan tampak
/// beku, padahal batas waktunya benar-benar berjalan.
///
/// Widget ini memegang ticker sendiri: satu detik sekali ia menghitung ulang
/// label, dan hanya memanggil `setState` ketika teksnya benar-benar berubah.
/// Layar induk tidak ikut dibangun ulang.
class PaymentCountdownChip extends StatefulWidget {
  const PaymentCountdownChip({
    super.key,
    required this.expiresAt,
    this.nowProvider = DateTime.now,
  });

  /// Batas waktu dari server. `null` berarti tagihan belum diterbitkan.
  final DateTime? expiresAt;

  /// Sumber waktu. Bisa diganti di test supaya angka bisa diperiksa tanpa
  /// menunggu jam dinding berjalan.
  final DateTime Function() nowProvider;

  @override
  State<PaymentCountdownChip> createState() => _PaymentCountdownChipState();
}

class _PaymentCountdownChipState extends State<PaymentCountdownChip>
    with WidgetsBindingObserver {
  Timer? _ticker;
  late String _label;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _label = _hitungLabel();
    _mulaiTicker();
  }

  @override
  void didUpdateWidget(covariant PaymentCountdownChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tagihan baru (atau batas waktu baru dari server) harus langsung terlihat,
    // tanpa menunggu detik berikutnya.
    if (oldWidget.expiresAt != widget.expiresAt) {
      _label = _hitungLabel();
      _mulaiTicker();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /* Perangkat yang tidur menghentikan ticker. Saat aplikasi kembali ke depan,
       label dihitung ulang dari jam dinding — bukan dilanjutkan dari angka
       terakhir — supaya tidak menampilkan sisa waktu yang sudah lewat. */
    if (state == AppLifecycleState.resumed) {
      _label = _hitungLabel();
      _mulaiTicker();
    } else {
      _ticker?.cancel();
    }
  }

  void _mulaiTicker() {
    _ticker?.cancel();
    if (widget.expiresAt == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final label = _hitungLabel();
      if (label == _label) return;
      setState(() => _label = label);
    });
  }

  String _hitungLabel() {
    final expiresAt = widget.expiresAt;
    if (expiresAt == null) return 'Menunggu tagihan';

    final sisa = expiresAt.difference(widget.nowProvider());
    if (sisa.isNegative) return 'Kedaluwarsa';

    final jam = sisa.inHours.toString().padLeft(2, '0');
    final menit = (sisa.inMinutes % 60).toString().padLeft(2, '0');
    final detik = (sisa.inSeconds % 60).toString().padLeft(2, '0');
    return '$jam:$menit:$detik';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kedaluwarsa = _label == 'Kedaluwarsa';
    final warnaTeks = kedaluwarsa ? const Color(0xFFDC2626) : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kedaluwarsa ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: warnaTeks),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: AppTypography.sizeCaption,
              fontWeight: FontWeight.w700,
              color: warnaTeks,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
