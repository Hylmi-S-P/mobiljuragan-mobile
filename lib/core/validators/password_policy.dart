/// Kebijakan kata sandi pelanggan — sisi aplikasi.
///
/// Salinan aturan server di `mobiljuragan-backend/src/lib/passwordPolicy.ts`.
/// Kalau salah satu diubah, ubah keduanya. Rujukan: dokumen
/// `docs/analisis-akun-tertimpa-otp.md` §6.5.
///
/// Aturan dibatasi pada bentuk kata sandi saja: panjang minimum, huruf besar,
/// huruf kecil, angka, dan simbol. Penilaian "kata sandi terlalu umum" atau
/// "memuat nama sendiri" tidak dipakai karena menolak kata sandi yang sah tanpa
/// alasan yang bisa diprediksi pengguna.
///
/// Fungsi di sini **hanya untuk umpan balik cepat** (checklist hidup). Server
/// tetap memvalidasi ulang; keputusan akhir selalu milik server.
library;

/// Panjang minimum yang diminta produk.
const int panjangMinimalKataSandi = 8;

/// Batas atas dalam byte UTF-8.
///
/// Bukan aturan gaya, melainkan batas teknis: bcrypt hanya memakai 72 byte
/// pertama, jadi kata sandi yang lebih panjang dipotong dan dua kata sandi
/// berbeda bisa dianggap sama.
const int batasByteKataSandi = 72;

/// Urutan aturan mengikuti tampilan checklist.
enum AturanKataSandi {
  panjangMinimal,
  hurufBesar,
  hurufKecil,
  angka,
  simbol,
  batasByte,
}

/// Aturan yang ditampilkan sebagai checklist di layar.
const List<AturanKataSandi> aturanTampil = [
  AturanKataSandi.panjangMinimal,
  AturanKataSandi.hurufBesar,
  AturanKataSandi.hurufKecil,
  AturanKataSandi.angka,
  AturanKataSandi.simbol,
];

/// Label pendek tiap aturan; sama buninya dengan pesan server.
String labelAturan(AturanKataSandi aturan) {
  switch (aturan) {
    case AturanKataSandi.panjangMinimal:
      return 'Minimal $panjangMinimalKataSandi karakter';
    case AturanKataSandi.hurufBesar:
      return 'Ada huruf besar';
    case AturanKataSandi.hurufKecil:
      return 'Ada huruf kecil';
    case AturanKataSandi.angka:
      return 'Ada angka';
    case AturanKataSandi.simbol:
      return 'Ada simbol';
    case AturanKataSandi.batasByte:
      return 'Maksimal $batasByteKataSandi byte';
  }
}

/// Apa pun yang bukan huruf atau angka dihitung sebagai simbol.
final RegExp _polaSimbol = RegExp(r'[^A-Za-z0-9]');

/// Panjang dalam byte UTF-8, karena emoji/aksara non-Latin lebih dari 1 byte.
int panjangByte(String nilai) {
  var total = 0;
  for (final rune in nilai.runes) {
    if (rune <= 0x7F) {
      total += 1;
    } else if (rune <= 0x7FF) {
      total += 2;
    } else if (rune <= 0xFFFF) {
      total += 3;
    } else {
      total += 4;
    }
  }
  return total;
}

/// Memeriksa kata sandi dan mengembalikan aturan yang **gagal**.
///
/// Daftar kosong berarti lolos. Dipakai checklist dan tombol lanjut.
Set<AturanKataSandi> periksaKataSandi(String kataSandi) {
  final gagal = <AturanKataSandi>{};

  if (kataSandi.length < panjangMinimalKataSandi) {
    gagal.add(AturanKataSandi.panjangMinimal);
  }
  if (!RegExp(r'[A-Z]').hasMatch(kataSandi)) gagal.add(AturanKataSandi.hurufBesar);
  if (!RegExp(r'[a-z]').hasMatch(kataSandi)) gagal.add(AturanKataSandi.hurufKecil);
  if (!RegExp(r'[0-9]').hasMatch(kataSandi)) gagal.add(AturanKataSandi.angka);
  if (!_polaSimbol.hasMatch(kataSandi)) gagal.add(AturanKataSandi.simbol);

  if (panjangByte(kataSandi) > batasByteKataSandi) {
    gagal.add(AturanKataSandi.batasByte);
  }

  return gagal;
}

/// True bila kata sandi lolos seluruh aturan.
bool kataSandiValid(String kataSandi) => periksaKataSandi(kataSandi).isEmpty;

/// Pesan galat pertama yang layak ditampilkan setelah pengguna menekan tombol.
///
/// Aturan yang tampil sebagai checklist tidak diulang di sini agar tidak
/// berbunyi dua kali di layar.
String pesanKataSandiTidakValid(String kataSandi) {
  final gagal = periksaKataSandi(kataSandi);

  if (gagal.contains(AturanKataSandi.batasByte)) {
    return labelAturan(AturanKataSandi.batasByte);
  }

  return 'Kata sandi belum memenuhi semua syarat di atas.';
}
