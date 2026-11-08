import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/core/validators/password_policy.dart';

/// Uji kebijakan kata sandi sisi aplikasi.
///
/// Aturan yang diuji di sini harus sama dengan
/// `mobiljuragan-backend/src/lib/passwordPolicy.ts`. Kalau salah satu berubah,
/// ubah keduanya — kalau tidak, pengguna akan melihat checklist "semua hijau"
/// tetapi ditolak server.
///
/// Kebijakan sengaja dibatasi pada **bentuk** kata sandi: panjang dan komposisi
/// karakter. Penilaian seperti "terlalu umum" atau "memuat nama sendiri" tidak
/// dipakai, dan test di bawah menjaga agar tidak diam-diam kembali masuk.
void main() {
  group('Aturan dasar', () {
    test('kata sandi lemah gagal pada beberapa aturan sekaligus', () {
      final gagal = periksaKataSandi('abcdefgh');
      expect(gagal, contains(AturanKataSandi.hurufBesar));
      expect(gagal, contains(AturanKataSandi.angka));
      expect(gagal, contains(AturanKataSandi.simbol));
      expect(gagal, isNot(contains(AturanKataSandi.panjangMinimal)));
      expect(gagal, isNot(contains(AturanKataSandi.hurufKecil)));
    });

    test('kata sandi 7 karakter ditolak karena panjang', () {
      expect(
        periksaKataSandi('Rahasia1!'.substring(0, 7)),
        contains(AturanKataSandi.panjangMinimal),
      );
    });

    test('kata sandi yang memenuhi semua aturan diterima', () {
      expect(periksaKataSandi('Rahasia1!'), isEmpty);
      expect(kataSandiValid('Rahasia1!'), isTrue);
    });

    test('spasi dihitung sebagai simbol', () {
      expect(kataSandiValid('Rahasia 1'), isTrue);
    });

    test('tepat 8 karakter dengan semua unsur diterima', () {
      expect(kataSandiValid('Rahasia1'), isFalse, reason: 'tanpa simbol');
      expect(kataSandiValid('Rahas1!a'), isTrue);
    });
  });

  group('Batas teknis panjang', () {
    test('lebih dari 72 byte ditolak karena bcrypt memotong di situ', () {
      final panjang = '${'A' * 60}a1!${'b' * 20}';
      expect(panjang.length, greaterThan(72));
      expect(periksaKataSandi(panjang), contains(AturanKataSandi.batasByte));
    });

    test('panjang dihitung dalam byte, bukan karakter', () {
      // 30 emoji = 120 byte walau hanya ~34 karakter.
      final emoji = 'A1!${'😀' * 30}';
      expect(emoji.length, lessThan(72));
      expect(periksaKataSandi(emoji), contains(AturanKataSandi.batasByte));
    });
  });

  group('Aturan yang sengaja TIDAK dipakai', () {
    test('kata sandi yang menyalin nama pemilik tetap diterima', () {
      // Sebelumnya ditolak oleh aturan "mengandung identitas".
      expect(kataSandiValid('Yahya123!'), isTrue);
      expect(kataSandiValid('YahyaPratama1!'), isTrue);
    });

    test('kata sandi yang memuat nomor telepon tetap diterima', () {
      expect(kataSandiValid('Harun081248002910!'), isTrue);
    });

    test('kata sandi umum tetap diterima selama bentuknya memenuhi aturan', () {
      // Sebelumnya ditolak oleh daftar kata sandi umum dan deret berurutan.
      expect(kataSandiValid('Password123!'), isTrue);
      expect(kataSandiValid('Rahasia1234!'), isTrue);
      expect(kataSandiValid('Qwerty123!'), isTrue);
    });

    test('aturan tersembunyi benar-benar tidak ada lagi', () {
      expect(AturanKataSandi.values, [
        AturanKataSandi.panjangMinimal,
        AturanKataSandi.hurufBesar,
        AturanKataSandi.hurufKecil,
        AturanKataSandi.angka,
        AturanKataSandi.simbol,
        AturanKataSandi.batasByte,
      ]);
    });
  });

  group('Checklist', () {
    test('lima aturan bentuk ditampilkan, batas byte tidak', () {
      expect(aturanTampil, [
        AturanKataSandi.panjangMinimal,
        AturanKataSandi.hurufBesar,
        AturanKataSandi.hurufKecil,
        AturanKataSandi.angka,
        AturanKataSandi.simbol,
      ]);
      expect(aturanTampil, isNot(contains(AturanKataSandi.batasByte)));
    });

    test('label tiap aturan terbaca manusia', () {
      expect(labelAturan(AturanKataSandi.panjangMinimal), contains('8'));
      expect(labelAturan(AturanKataSandi.angka), 'Ada angka');
      expect(labelAturan(AturanKataSandi.simbol), 'Ada simbol');
      expect(labelAturan(AturanKataSandi.hurufBesar), 'Ada huruf besar');
      expect(labelAturan(AturanKataSandi.hurufKecil), 'Ada huruf kecil');
    });

    test('pesan galat menyebut batas byte bila itu penyebabnya', () {
      final panjang = '${'A' * 80}a1!';
      expect(
        pesanKataSandiTidakValid(panjang),
        labelAturan(AturanKataSandi.batasByte),
      );
    });

    test('pesan galat umum dipakai untuk kegagalan bentuk', () {
      expect(
        pesanKataSandiTidakValid('abcdefgh'),
        'Kata sandi belum memenuhi semua syarat di atas.',
      );
    });
  });
}
