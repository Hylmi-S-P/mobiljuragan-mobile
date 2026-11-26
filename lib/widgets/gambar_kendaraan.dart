import 'dart:io';

import 'package:flutter/material.dart';

import '../core/cache/public_media_disk_cache.dart';
import '../core/constants/api_constants.dart';

/// Menampilkan foto kendaraan dari server maupun dari aset bawaan aplikasi.
///
/// Dipakai menggantikan `Image.asset` langsung. Bedanya:
/// - kalau [sumber] berupa path server relatif (`/api/v1/media/...`), alamatnya
///   digabung dengan backend lebih dulu;
/// - foto armada publik di-cache di folder sementara agar tidak selalu
///   mengunduh ulang saat menggulir katalog;
/// - bila [lebarLogis] diberikan, dekode gambar dibatasi dengan `cacheWidth`
///   untuk menghemat RAM GPU sambil tetap menjaga rasio aspek asli;
/// - kalau berupa path aset (`assets/...`), dibaca dari bundel.
///
/// [cadangan] ditampilkan kalau gambarnya gagal dimuat, biasanya ikon mobil.
class GambarKendaraan extends StatelessWidget {
  const GambarKendaraan({
    super.key,
    required this.sumber,
    this.fit = BoxFit.cover,
    this.cadangan,
    this.lebarLogis,
    this.tinggiLogis,
  });

  /// Path aset, path server, atau URL penuh. Boleh null.
  final String? sumber;
  final BoxFit fit;
  final Widget? cadangan;
  final double? lebarLogis;
  final double? tinggiLogis;

  @override
  Widget build(BuildContext context) {
    final alamat = _alamatGambar(sumber);
    final gagal =
        cadangan ??
        const Center(
          child: Icon(Icons.directions_car, color: Colors.grey, size: 32),
        );

    if (alamat == null || alamat.isEmpty) return gagal;

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final int? targetCacheWidth = lebarLogis != null
        ? (lebarLogis! * dpr).round().clamp(32, 1200)
        : (tinggiLogis != null
              ? (tinggiLogis! * dpr * 1.5).round().clamp(32, 1200)
              : null);

    if (alamat.startsWith('http://') || alamat.startsWith('https://')) {
      if (PublicMediaDiskCache.bolehDiCache(alamat)) {
        return _GambarJaringanTercache(
          alamat: alamat,
          fit: fit,
          cacheWidth: targetCacheWidth,
          gagal: gagal,
        );
      }
      return Image.network(
        alamat,
        fit: fit,
        cacheWidth: targetCacheWidth,
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

    return Image.asset(
      alamat,
      fit: fit,
      cacheWidth: targetCacheWidth,
      errorBuilder: (_, _, _) => gagal,
    );
  }
}

class _GambarJaringanTercache extends StatefulWidget {
  const _GambarJaringanTercache({
    required this.alamat,
    required this.fit,
    required this.cacheWidth,
    required this.gagal,
  });

  final String alamat;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget gagal;

  @override
  State<_GambarJaringanTercache> createState() =>
      _GambarJaringanTercacheState();
}

class _GambarJaringanTercacheState extends State<_GambarJaringanTercache> {
  File? _berkasLokal;
  bool _selesaiCek = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void didUpdateWidget(covariant _GambarJaringanTercache oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alamat != widget.alamat) {
      _berkasLokal = null;
      _selesaiCek = false;
      _muat();
    }
  }

  Future<void> _muat() async {
    final targetAlamat = widget.alamat;
    final berkas = await PublicMediaDiskCache.ambilAtauUnduh(targetAlamat);
    if (!mounted || widget.alamat != targetAlamat) return;
    setState(() {
      _berkasLokal = berkas;
      _selesaiCek = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final berkas = _berkasLokal;
    if (berkas != null) {
      return Image.file(
        berkas,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: (_, _, _) => widget.gagal,
      );
    }
    if (!_selesaiCek) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Image.network(
      widget.alamat,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      errorBuilder: (_, _, _) => widget.gagal,
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
}

/// Mengubah nilai dari model menjadi alamat yang bisa dimuat.
///
/// Path aset lama (.png) dinormalisasi ke (.webp) supaya baris Drift cache dari
/// versi aplikasi sebelumnya tetap tampil sebelum sinkronisasi berikutnya.
String? _alamatGambar(String? sumber) {
  if (sumber == null) return null;
  final bersih = sumber.trim();
  if (bersih.isEmpty) return null;
  if (bersih.startsWith('assets/images/') && bersih.toLowerCase().endsWith('.png')) {
    return '${bersih.substring(0, bersih.length - 4)}.webp';
  }
  if (bersih.startsWith('assets/')) return bersih;
  return ApiConstants.alamatMedia(bersih);
}
