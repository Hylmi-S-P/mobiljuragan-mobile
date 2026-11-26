import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

/// Cache disk ringan khusus foto armada publik (`/api/v1/media/...`).
///
/// Berkas pribadi (KTP, SIM A, surat pernyataan, bukti pembayaran) yang memakai
/// parameter bertanda tangan (`sig`, `exp`, `token`) TIDAK PERNAH ditulis ke
/// cache disk agar jejak privasi pelanggan tetap bersih.
class PublicMediaDiskCache {
  static const int _maksBerkas = 60;
  static const Duration _timeoutUnduh = Duration(seconds: 12);

  static final Map<String, Future<File?>> _unduhBerjalan = {};
  static Directory? _folderCache;

  /// Memastikan hanya URL media publik tanpa parameter akses privat yang di-cache.
  static bool bolehDiCache(String alamat) {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    final uri = Uri.tryParse(alamat);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (!uri.path.contains('/api/v1/media/')) return false;
    final qp = uri.queryParameters;
    if (qp.containsKey('sig') || qp.containsKey('exp') || qp.containsKey('token')) {
      return false;
    }
    return true;
  }

  static Future<Directory> _siapkanFolder() async {
    final cached = _folderCache;
    if (cached != null) return cached;
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}${Platform.pathSeparator}fleet_media_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _folderCache = dir;
    return dir;
  }

  /// Hash FNV-1a 64-bit dua arah (tanpa ketergantungan paket tambahan) agar
  /// nama berkas aman di seluruh sistem berkas dan unik per URL.
  static String _namaBerkasUntuk(String url) {
    var h1 = 0xcbf29ce484222325;
    var h2 = 0x84222325cbf29ce4;
    const prime = 0x100000001b3;
    for (final unit in url.codeUnits) {
      h1 ^= unit;
      h1 = (h1 * prime) & 0xFFFFFFFFFFFFFFFF;
      h2 = ((h2 * 31) ^ unit) & 0xFFFFFFFFFFFFFFFF;
    }
    final hex1 = h1.toRadixString(16).padLeft(16, '0');
    final hex2 = h2.toRadixString(16).padLeft(16, '0');
    return 'img_${hex1}_${hex2}_${url.length}.cache';
  }

  /// Mengambil berkas dari cache bila sudah ada, atau mengunduhnya satu kali
  /// (dengan deduplikasi permintaan paralel untuk URL yang sama).
  static Future<File?> ambilAtauUnduh(String alamat) {
    if (!bolehDiCache(alamat)) return Future<File?>.value(null);

    final aktif = _unduhBerjalan[alamat];
    if (aktif != null) return aktif;

    final tugas = _jalankanAmbilAtauUnduh(alamat).whenComplete(() {
      _unduhBerjalan.remove(alamat);
    });
    _unduhBerjalan[alamat] = tugas;
    return tugas;
  }

  static Future<File?> _jalankanAmbilAtauUnduh(String alamat) async {
    try {
      final dir = await _siapkanFolder();
      final berkas = File('${dir.path}${Platform.pathSeparator}${_namaBerkasUntuk(alamat)}');
      if (await berkas.exists() && await berkas.length() > 0) {
        return berkas;
      }

      final uri = Uri.parse(alamat);
      final respons = await ApiClient.sharedHttpClient.get(uri).timeout(_timeoutUnduh);
      if (respons.statusCode != 200 || respons.bodyBytes.isEmpty) {
        return null;
      }

      final sementara = File('${berkas.path}.tmp.${DateTime.now().microsecondsSinceEpoch}');
      await sementara.writeAsBytes(respons.bodyBytes, flush: false);
      if (await berkas.exists()) {
        await sementara.delete();
        return berkas;
      }
      final hasil = await sementara.rename(berkas.path);
      unawaited(_pangkasJikaBerlebih(dir));
      return hasil;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _pangkasJikaBerlebih(Directory dir) async {
    try {
      final entries = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.cache'))
          .cast<File>()
          .toList();
      if (entries.length <= _maksBerkas) return;

      final berurutan = <({File berkas, DateTime diubah})>[];
      for (final f in entries) {
        try {
          berurutan.add((berkas: f, diubah: await f.lastModified()));
        } catch (_) {}
      }
      berurutan.sort((a, b) => a.diubah.compareTo(b.diubah));
      final hapusCount = berurutan.length - _maksBerkas;
      for (var i = 0; i < hapusCount; i++) {
        try {
          await berurutan[i].berkas.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
