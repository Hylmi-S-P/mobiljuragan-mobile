import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';

/// Menampilkan foto kendaraan dari server maupun dari aset bawaan aplikasi.
///
/// Dipakai menggantikan `Image.asset` langsung. Bedanya:
/// - kalau [sumber] berupa path server relatif (`/api/v1/media/...`), alamatnya
///   digabung dengan backend lebih dulu;
/// - kalau berupa URL http(s), dimuat lewat jaringan;
/// - kalau berupa path aset (`assets/...`), dibaca dari bundel.
///
/// [cadangan] ditampilkan kalau gambarnya gagal dimuat, biasanya ikon mobil.
class GambarKendaraan extends StatelessWidget {
  const GambarKendaraan({
    super.key,
    required this.sumber,
    this.fit = BoxFit.cover,
    this.cadangan,
  });

  /// Path aset, path server, atau URL penuh. Boleh null.
  final String? sumber;
  final BoxFit fit;
  final Widget? cadangan;

  @override
  Widget build(BuildContext context) {
    final alamat = _alamatGambar(sumber);
    final gagal =
        cadangan ??
        const Center(
          child: Icon(Icons.directions_car, color: Colors.grey, size: 32),
        );

    if (alamat == null || alamat.isEmpty) return gagal;

    if (alamat.startsWith('http://') || alamat.startsWith('https://')) {
      return Image.network(
        alamat,
        fit: fit,
        errorBuilder: (_, _, _) => gagal,
        loadingBuilder: (context, anak, progres) {
          if (progres == null) return anak;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return Image.asset(alamat, fit: fit, errorBuilder: (_, _, _) => gagal);
  }
}

/// Mengubah nilai dari model menjadi alamat yang bisa dimuat.
///
/// Path aset dibiarkan apa adanya. Path server yang diawali `/` digabung dengan
/// origin backend, karena `/api/v1/media/...` tidak punya host.
String? _alamatGambar(String? sumber) {
  if (sumber == null) return null;
  final bersih = sumber.trim();
  if (bersih.isEmpty) return null;
  if (bersih.startsWith('assets/')) return bersih;
  return ApiConstants.alamatMedia(bersih);
}
