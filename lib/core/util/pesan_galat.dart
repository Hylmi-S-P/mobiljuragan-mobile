import 'dart:math';

/// Penyusun pesan galat yang aman ditampilkan ke pengguna.
///
/// Sebelum ini beberapa layar menuliskan exception mentah ke SnackBar
/// (`'Gagal mengirim bukti: $e'`). Teks semacam itu membocorkan nama kelas,
/// jalur berkas, bahkan potongan respons server, dan bagi pengguna sama sekali
/// tidak membantu. Di sisi lain, dukungan teknis tetap butuh cara menelusuri
/// kejadian tersebut. Karena itu setiap galat kini dipasangkan dengan **kode
/// referensi** pendek: pesan tetap ramah, sementara kode itu bisa disebutkan
/// pengguna saat melapor sehingga baris log yang dicari jelas.
class PesanGalat {
  const PesanGalat._();

  static const String _abjad = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _acak = Random();

  /// Membuat kode referensi pendek, mis. `MJ-7K2QF`.
  ///
  /// Huruf yang mirip (`I`, `O`, `0`, `1`) sengaja tidak dipakai supaya kode
  /// tidak salah dibaca saat disampaikan lewat telepon atau tangkapan layar.
  static String kodeReferensi() {
    final buffer = StringBuffer('MJ-');
    for (var i = 0; i < 5; i++) {
      buffer.write(_abjad[_acak.nextInt(_abjad.length)]);
    }
    return buffer.toString();
  }

  /// Menyusun pesan ramah beserta kode referensinya.
  ///
  /// [awalan] adalah kalimat yang menjelaskan apa yang gagal, misalnya
  /// `'Gagal mengirim bukti pembayaran'`. [galat] tidak pernah ikut ditampilkan;
  /// nilainya hanya dipakai pemanggil untuk pencatatan saat pengembangan.
  static String ramah(String awalan, {Object? galat}) {
    final kode = kodeReferensi();
    return '$awalan. Silakan coba lagi. Bila masih gagal, sebutkan kode $kode.';
  }

  /// Varian untuk kegagalan yang pesannya sudah berasal dari server.
  ///
  /// Pesan server biasanya sudah berbahasa Indonesia dan layak dibaca (mis.
  /// "Tarif belum final"). Nilai ini tetap ditambah kode referensi agar laporan
  /// pengguna bisa dicocokkan dengan log.
  static String dariServer(String pesanServer) {
    final kode = kodeReferensi();
    return '$pesanServer (kode $kode)';
  }
}
