import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan berkas unduhan ke penyimpanan perangkat lalu membuka lembar bagikan.
///
/// Sebelumnya tombol unduh hanya menampilkan notifikasi "berhasil diunduh"
/// padahal isi berkasnya dibuang begitu saja. Pelanggan tidak pernah mendapat
/// file untuk dicetak, sehingga alur tanda tangan basah tidak mungkin berjalan.
///
/// Berkas ditulis ke folder sementara aplikasi, bukan folder unduhan publik.
/// Alasannya: sejak Android 10 penulisan ke folder publik memerlukan izin
/// tambahan, sedangkan berkas ini hanya perlu dibuka sekali untuk dicetak.
/// Lembar bagikan dipakai supaya pelanggan bisa memilih aplikasi cetak atau
/// menyimpan sendiri ke Drive/WhatsApp.
class BerkasUnduhan {
  const BerkasUnduhan._();

  /// Menyimpan [isi] sebagai [namaBerkas] lalu membuka lembar bagikan.
  ///
  /// [mime] harus sesuai jenis berkas sebenarnya. Dokumen resmi bisa berupa PDF
  /// atau Word tergantung apa yang diunggah admin, dan aplikasi penerima memilih
  /// cara membukanya dari tipe ini. Menuliskan `application/pdf` untuk berkas
  /// Word membuat penerima gagal membukanya.
  ///
  /// Mengembalikan path berkas yang tertulis. Melempar galat bila penulisan
  /// gagal, supaya pemanggil bisa menampilkan pesan yang jujur kepada pengguna.
  static Future<String> simpanDanBagikan({
    required Uint8List isi,
    required String namaBerkas,
    String mime = 'application/pdf',
    String? judul,
    String? teks,
  }) async {
    final folder = await getTemporaryDirectory();
    final berkas = File('${folder.path}/$namaBerkas');

    await berkas.writeAsBytes(isi, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(berkas.path, mimeType: mime)],
        subject: judul,
        text: teks,
      ),
    );

    return berkas.path;
  }

  /// Menghapus seluruh berkas unduhan milik sesi yang berakhir.
  ///
  /// Dokumen yang pernah diunduh bisa memuat data pribadi: tanda terima
  /// pembayaran, surat pernyataan lepas kunci, hingga salinan dokumen identitas.
  /// Berkas itu tidak boleh tetap ada di perangkat setelah pelanggan keluar,
  /// karena akun berikutnya di perangkat yang sama bisa membukanya lewat
  /// aplikasi pengelola berkas.
  ///
  /// Folder sementara dipakai bersama seluruh sesi, jadi seluruh isinya
  /// dikosongkan. Folder ini memang hanya berisi berkas sekali pakai: setiap
  /// unduhan ditulis ulang dari server saat dibutuhkan. Subfolder tidak diikuti
  /// karena [simpanDanBagikan] tidak pernah membuatnya.
  ///
  /// Cache gambar Flutter juga dibersihkan di sini. Gambar yang sudah
  /// ter-decode tetap tinggal di memori walau berkas sumbernya dihapus, sehingga
  /// tanpa pembersihan ini foto kendaraan dan lampiran dokumen masih bisa
  /// tampil sesaat setelah akun berganti.
  ///
  /// Kegagalan penghapusan satu berkas tidak menghentikan berkas lain; jumlah
  /// berkas yang gagal dihapus dikembalikan agar pemanggil bisa mencatatnya.
  static Future<int> wipeAll() async {
    var gagal = 0;

    try {
      final folder = await getTemporaryDirectory();
      final isi = await folder.list(followLinks: false).toList();
      for (final entri in isi) {
        try {
          await entri.delete(recursive: true);
        } catch (_) {
          gagal++;
        }
      }
    } catch (_) {
      // Folder sementara tidak tersedia (mis. platform tanpa path_provider):
      // tidak ada yang bisa dibersihkan, bukan kegagalan yang perlu dilaporkan.
    }

    await wipeCacheGambarPicker();

    try {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (_) {
      gagal++;
    }

    return gagal;
  }

  /// Membersihkan salinan gambar hasil `image_picker` di direktori cache.
  ///
  /// Plugin `image_picker` menyalin berkas pilihan pengguna ke direktori cache
  /// aplikasi (satu subfolder per UUID) dan mencatat lokasinya di
  /// SharedPreferences milik plugin. Salinan itu tidak ikut terhapus saat
  /// aplikasi menutup layar pemilih, sehingga foto dokumen identitas bisa
  /// tertinggal di perangkat. Keduanya dibersihkan di sini.
  static Future<void> wipeCacheGambarPicker() async {
    try {
      final folderCache = await getApplicationCacheDirectory();
      final isi = await folderCache.list(followLinks: false).toList();
      for (final entri in isi) {
        /* Hanya subfolder bergaya UUID yang dibuat plugin image_picker. Berkas
           lain di direktori cache dipakai pustaka Flutter sendiri (mis. cache
           shader) dan dibiarkan supaya aplikasi tidak membangun ulang semuanya
           setiap kali ada pelanggan keluar. */
        if (entri is! Directory) continue;
        final nama = entri.uri.pathSegments.lastWhere(
          (segmen) => segmen.isNotEmpty,
          orElse: () => '',
        );
        if (!_polaUuid.hasMatch(nama)) continue;
        try {
          await entri.delete(recursive: true);
        } catch (_) {
          // Abaikan: satu subfolder yang gagal dihapus tidak menghalangi sisanya.
        }
      }
    } catch (_) {
      // Direktori cache tidak tersedia: tidak ada yang perlu dibersihkan.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final kunci in prefs.getKeys().toList()) {
        if (kunci.startsWith('flutter_image_picker_')) {
          await prefs.remove(kunci);
        }
      }
    } catch (_) {
      // Preferensi plugin tidak tersedia: bukan kegagalan yang perlu dilaporkan.
    }
  }

  /// Pola nama subfolder UUID milik plugin `image_picker`.
  static final RegExp _polaUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
