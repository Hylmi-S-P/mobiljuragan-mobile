import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/core/validators/password_policy.dart';

/// Uji kebijakan kata sandi sisi aplikasi.
///
/// Aturan yang diuji di sini harus sama dengan
/// `mobiljuragan-backend/src/lib/passwordPolicy.ts`. Kalau salah satu berubah,
/// ubah keduanya — kalau tidak, pengguna akan melihat checklist "semua hijau"
/// tetapi ditolak server.
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
  });

  group('Batas panjang', () {
    test('lebih dari 72 byte ditolak karena bcrypt memotong di situ', () {
      final panjang = '${'A' * 60}a1!${'b' * 20}';
      expect(panjang.length, greaterThan(72));
      expect(periksaKataSandi(panjang), contains(AturanKataSandi.batasByte));
    });

    test('panjang dihitung dalam byte, bukan karakter', () {
      // 70 emoji = 280 byte walau hanya 70 karakter.
      final emoji = 'A1!${'😀' * 30}';
      expect(emoji.length, lessThan(72));
      expect(periksaKataSandi(emoji), contains(AturanKataSandi.batasByte));
    });
  });

  group('Kata sandi yang menyalin identitas', () {
    test('memuat nama depan ditolak', () {
      expect(
        periksaKataSandi('Yahya123!', namaLengkap: 'Yahya Pratama'),
        contains(AturanKataSandi.mengandungIdentitas),
      );
    });

    test('memuat nomor telepon ditolak', () {
      expect(
        periksaKataSandi('Harun081248002910!', nomorTelepon: '081248002910'),
        contains(AturanKataSandi.mengandungIdentitas),
      );
    });

    test('nomor tanpa awalan 0 atau 62 tetap terdeteksi', () {
      expect(
        periksaKataSandi('Rahasia81248002910!', nomorTelepon: '+62 812-4800-2910'),
        contains(AturanKataSandi.mengandungIdentitas),
      );
    });

    test('nama pendek dua huruf tidak dijadikan larangan', () {
      // "Al" ada di dalam "Rahasia" secara kebetulan; jangan menolak karena itu.
      expect(
        periksaKataSandi('Rahasia1!', namaLengkap: 'Al'),
        isEmpty,
      );
    });
  });

  group('Kata sandi umum', () {
    test('kata sandi bocoran populer ditolak', () {
      expect(
        periksaKataSandi('Password123!'),
        contains(AturanKataSandi.terlaluUmum),
      );
    });

    test('deret berurutan ditolak', () {
      expect(
        periksaKataSandi('Rahasia1234!'),
        contains(AturanKataSandi.terlaluUmum),
      );
    });

    test('kata sandi normal tidak dianggap umum', () {
      expect(periksaKataSandi('KucingOren9#'), isEmpty);
    });
  });

  group('Checklist', () {
    test('hanya aturan yang diminta produk yang ditampilkan', () {
      expect(aturanTampil, [
        AturanKataSandi.panjangMinimal,
        AturanKataSandi.hurufBesar,
        AturanKataSandi.hurufKecil,
        AturanKataSandi.angka,
        AturanKataSandi.simbol,
      ]);
      expect(aturanTampil, isNot(contains(AturanKataSandi.terlaluUmum)));
      expect(aturanTampil, isNot(contains(AturanKataSandi.batasByte)));
    });

    test('label tiap aturan terbaca manusia', () {
      expect(labelAturan(AturanKataSandi.panjangMinimal), contains('8'));
      expect(labelAturan(AturanKataSandi.angka), 'Ada angka');
      expect(labelAturan(AturanKataSandi.simbol), 'Ada simbol');
    });

    test('pesan galat memilih aturan tersembunyi lebih dulu', () {
      // Kata sandi ini lolos panjang/kompleksitas tetapi menyalin nomor sendiri.
      final pesan = pesanKataSandiTidakValid(
        'Rahasia081248002910!',
        nomorTelepon: '081248002910',
      );
      expect(pesan, labelAturan(AturanKataSandi.mengandungIdentitas));
    });
  });
}
