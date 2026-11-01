import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  /// Mengembalikan path berkas yang tertulis. Melempar galat bila penulisan
  /// gagal, supaya pemanggil bisa menampilkan pesan yang jujur kepada pengguna.
  static Future<String> simpanDanBagikan({
    required Uint8List isi,
    required String namaBerkas,
    String? judul,
    String? teks,
  }) async {
    final folder = await getTemporaryDirectory();
    final berkas = File('${folder.path}/$namaBerkas');

    await berkas.writeAsBytes(isi, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(berkas.path, mimeType: 'application/pdf')],
        subject: judul,
        text: teks,
      ),
    );

    return berkas.path;
  }
}
