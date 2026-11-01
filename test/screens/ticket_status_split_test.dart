import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/models/support_ticket_model.dart';

/// Dibangun lewat `fromJson` seperti jalur aslinya: status dari server masih
/// berupa enum (`RESOLVED`, `CLOSED`) dan baru diterjemahkan model.
SupportTicketModel _tiket(String statusServer) => SupportTicketModel.fromJson({
      'id': 't-${statusServer.toLowerCase()}',
      'ticketNumber': 'TKT-20261101-0001',
      'title': 'Uji',
      'category': 'VEHICLE_ISSUE',
      'description': 'Deskripsi',
      'status': statusServer,
      'createdAt': '2026-11-01T08:00:00.000Z',
    });

void main() {
  group('Pembagian tiket aktif vs riwayat', () {
    test('RESOLVED dan CLOSED sama-sama berakhir bagi pelanggan', () {
      /* Server menyimpan dua status akhir: RESOLVED (dijawab, menunggu
         konfirmasi, ditutup otomatis setelah 24 jam) lalu CLOSED (final).
         Sejak wave 09 keduanya menolak pesan, jadi keduanya tidak boleh muncul
         di daftar aktif dan tidak boleh memakai label berbeda. */
      final selesai = _tiket('RESOLVED');
      final ditutup = _tiket('CLOSED');

      expect(selesai.isFinished, isTrue);
      expect(ditutup.isFinished, isTrue);

      expect(selesai.status, 'Selesai');
      expect(ditutup.status, 'Ditutup');
      // Satu label untuk pelanggan, walau status internalnya berbeda.
      expect(selesai.statusPelanggan, 'Selesai');
      expect(ditutup.statusPelanggan, 'Selesai');
    });

    test('tiket yang masih menerima pesan tetap dianggap aktif', () {
      for (final entry in {'OPEN': 'Menunggu', 'IN_PROGRESS': 'Diproses'}.entries) {
        final tiket = _tiket(entry.key);
        expect(tiket.isFinished, isFalse, reason: entry.key);
        expect(tiket.statusPelanggan, entry.value);
      }
    });
  });
}
