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

  group('validasiJadwalSewa & batas jadwal', () {
    test('menolak tanggal sebelum hari ini', () {
      final now = DateTime(2026, 11, 20, 8, 0);
      final err = validasiJadwalSewa(
        tanggal: DateTime(2026, 11, 19),
        labelJam: '09.00 WIT',
        now: now,
      );
      expect(err, isNotNull);
    });

    test('hari ini butuh jeda minimal 2 jam dari sekarang', () {
      final now = DateTime(2026, 11, 20, 8, 15, 20);
      expect(
        validasiJadwalSewa(
          tanggal: DateTime(2026, 11, 20),
          labelJam: '10.15 WIT',
          now: now,
        ),
        isNotNull,
      );
      expect(
        validasiJadwalSewa(
          tanggal: DateTime(2026, 11, 20),
          labelJam: '10.16 WIT',
          now: now,
        ),
        isNull,
      );
    });

    test('setelah jam 20.00 hari ini bergeser paling awal ke besok', () {
      final now = DateTime(2026, 11, 20, 20, 5);
      expect(tanggalMulaiPalingAwal(now), DateTime(2026, 11, 21));
    });

    test('jam operasional maksimal tepat 22.00 WIT dan tolak 22.01 WIT', () {
      expect(adalahJamOperasional(22, 0), isTrue);
      expect(adalahJamOperasional(22, 1), isFalse);
      expect(adalahJamOperasional(5, 59), isFalse);
      expect(adalahJamOperasional(6, 0), isTrue);
    });

    test('menolak tanggal mulai lebih dari 60 hari ke depan', () {
      final now = DateTime(2026, 11, 20, 8, 0);
      expect(
        validasiJadwalSewa(
          tanggal: DateTime(2026, 11, 20).add(const Duration(days: 60)),
          labelJam: '09.00 WIT',
          now: now,
        ),
        isNull,
      );
      expect(
        validasiJadwalSewa(
          tanggal: DateTime(2026, 11, 20).add(const Duration(days: 61)),
          labelJam: '09.00 WIT',
          now: now,
        ),
        isNotNull,
      );
    });
  });
}
