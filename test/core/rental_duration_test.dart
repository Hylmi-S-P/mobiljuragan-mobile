import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/core/util/rental_duration.dart';

void main() {
  group('hitungHariSewa', () {
    test('membulatkan sisa jam ke atas seperti aturan server', () {
      final mulai = DateTime(2026, 11, 20, 9, 0);
      final selesai = DateTime(2026, 11, 22, 12, 0);

      // 51 jam: server menghitung 3 hari, bukan 2 hari seperti pembulatan ke bawah.
      expect(hitungHariSewa(mulai, selesai), 3);
    });

    test('rentang tepat kelipatan hari tidak bertambah', () {
      final mulai = DateTime(2026, 11, 20, 9, 0);
      final selesai = DateTime(2026, 11, 22, 9, 0);

      expect(hitungHariSewa(mulai, selesai), 2);
    });

    test('rentang nol atau negatif tetap dihitung satu hari', () {
      final mulai = DateTime(2026, 11, 20, 9, 0);

      expect(hitungHariSewa(mulai, mulai), 1);
      expect(hitungHariSewa(mulai, mulai.subtract(const Duration(hours: 3))), 1);
    });
  });

  group('gabungTanggalDanJam', () {
    test('memakai jam dari label WIT', () {
      final hasil = gabungTanggalDanJam(DateTime(2026, 11, 20), '09.30 WIT');

      expect(hasil, DateTime(2026, 11, 20, 9, 30));
    });

    test('menerima label dengan titik dua', () {
      final hasil = gabungTanggalDanJam(DateTime(2026, 11, 20), '18:05');

      expect(hasil, DateTime(2026, 11, 20, 18, 5));
    });

    test('label tak terbaca dibiarkan apa adanya, bukan ditebak', () {
      final tanggal = DateTime(2026, 11, 20);

      expect(gabungTanggalDanJam(tanggal, 'segera'), tanggal);
    });
  });
}
