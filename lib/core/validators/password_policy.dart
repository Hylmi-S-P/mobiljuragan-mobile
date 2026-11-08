/// Kebijakan kata sandi pelanggan — sisi aplikasi.
///
/// Salinan aturan server di `mobiljuragan-backend/src/lib/passwordPolicy.ts`.
/// Kalau salah satu diubah, ubah keduanya. Rujukan: dokumen
/// `docs/analisis-akun-tertimpa-otp.md` §6.5.
///
/// Fungsi di sini **hanya untuk umpan balik cepat** (checklist hidup). Server
/// tetap memvalidasi ulang; keputusan akhir selalu milik server.
library;

/// Panjang minimum yang diminta produk.
const int panjangMinimalKataSandi = 8;

/// Batas atas dalam byte UTF-8.
///
/// bcrypt hanya memakai 72 byte pertama, jadi kata sandi yang lebih panjang dari
/// ini dipotong dan dua kata sandi berbeda bisa dianggap sama.
const int batasByteKataSandi = 72;

/// Urutan aturan mengikuti tampilan checklist.
enum AturanKataSandi {
  panjangMinimal,
  hurufBesar,
  hurufKecil,
  angka,
  simbol,
  batasByte,
  mengandungIdentitas,
  terlaluUmum,
}

/// Aturan yang ditampilkan sebagai checklist di layar.
const List<AturanKataSandi> aturanTampil = [
  AturanKataSandi.panjangMinimal,
  AturanKataSandi.hurufBesar,
  AturanKataSandi.hurufKecil,
  AturanKataSandi.angka,
  AturanKataSandi.simbol,
];

/// Label pendek tiap aturan; sama bunyinya dengan pesan server.
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
    case AturanKataSandi.mengandungIdentitas:
      return 'Jangan memakai nama atau nomor sendiri';
    case AturanKataSandi.terlaluUmum:
      return 'Kata sandi terlalu umum';
  }
}

/// Kata sandi yang paling sering muncul di daftar bocoran (sama dengan server).
const Set<String> _kataSandiUmum = {
  'password',
  'password1',
  'password123',
  'password1234',
  'passw0rd',
  'p@ssw0rd',
  'qwerty',
  'qwerty123',
  'qwertyuiop',
  '12345678',
  '123456789',
  '1234567890',
  'iloveyou',
  'admin123',
  'administrator',
  'letmein123',
  'welcome1',
  'welcome123',
  'abc12345',
  'abcd1234',
  'monkey123',
  'dragon123',
  'sunshine1',
  'princess1',
  'football1',
  'baseball1',
  'superman1',
  'batman123',
  'mobiljuragan',
  'juragan123',
  'merauke123',
};

const List<String> _deretMudah = [
  '1234',
  '2345',
  '3456',
  '4567',
  '5678',
  '6789',
  'abcd',
  'bcde',
  'qwer',
  'asdf',
];

final RegExp _polaSimbol = RegExp(r'[^A-Za-z0-9]');

String _digitSaja(String nilai) => nilai.replaceAll(RegExp(r'\D'), '');

String _normalisasiTeks(String nilai) =>
    nilai.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

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
Set<AturanKataSandi> periksaKataSandi(
  String kataSandi, {
  String? namaLengkap,
  String? nomorTelepon,
}) {
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

  final polos = _normalisasiTeks(kataSandi);
  final kandidatIdentitas = <String>[];

  if (namaLengkap != null) {
    for (final bagian in namaLengkap.split(RegExp(r'\s+'))) {
      final bersih = _normalisasiTeks(bagian);
      if (bersih.length >= 3) kandidatIdentitas.add(bersih);
    }
  }

  if (nomorTelepon != null) {
    final digit = _digitSaja(nomorTelepon);
    if (digit.length >= 6) {
      kandidatIdentitas.add(digit);
      kandidatIdentitas.add(digit.replaceFirst(RegExp(r'^62'), '').replaceFirst(RegExp(r'^0'), ''));
      kandidatIdentitas.add(digit.replaceFirst(RegExp(r'^62'), ''));
    }
  }

  final digitSandi = _digitSaja(kataSandi);
  final mengandungIdentitas = kandidatIdentitas.any(
    (kandidat) =>
        kandidat.length >= 4 &&
        (polos.contains(kandidat) || digitSandi.contains(kandidat)),
  );
  if (mengandungIdentitas) gagal.add(AturanKataSandi.mengandungIdentitas);

  final kecil = kataSandi.toLowerCase();
  final terlaluUmum = _kataSandiUmum.contains(kecil) ||
      _kataSandiUmum.contains(polos) ||
      _deretMudah.any(kecil.contains);
  if (terlaluUmum) gagal.add(AturanKataSandi.terlaluUmum);

  return gagal;
}

/// True bila kata sandi lolos seluruh aturan (termasuk yang tidak tampil).
bool kataSandiValid(
  String kataSandi, {
  String? namaLengkap,
  String? nomorTelepon,
}) {
  return periksaKataSandi(
    kataSandi,
    namaLengkap: namaLengkap,
    nomorTelepon: nomorTelepon,
  ).isEmpty;
}

/// Pesan galat pertama yang layak ditampilkan setelah pengguna menekan tombol.
///
/// Aturan yang tampil sebagai checklist tidak diulang di sini agar tidak
/// berbunyi dua kali di layar.
String pesanKataSandiTidakValid(
  String kataSandi, {
  String? namaLengkap,
  String? nomorTelepon,
}) {
  final gagal = periksaKataSandi(
    kataSandi,
    namaLengkap: namaLengkap,
    nomorTelepon: nomorTelepon,
  );

  for (final aturan in [
    AturanKataSandi.mengandungIdentitas,
    AturanKataSandi.terlaluUmum,
    AturanKataSandi.batasByte,
  ]) {
    if (gagal.contains(aturan)) return labelAturan(aturan);
  }

  return 'Kata sandi belum memenuhi semua syarat di atas.';
}
