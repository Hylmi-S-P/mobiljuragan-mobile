import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/local/secure/secure_storage_service.dart';
import 'package:mobiljuragan_mobile/data/remote/booking_api_service.dart';
import 'package:mobiljuragan_mobile/data/repositories/booking_repository.dart';

/// Penyimpanan kredensial yang bisa diubah di tengah pengujian, meniru
/// aplikasi yang dibuka sebelum sesi terbaca lalu menerima login sesudahnya.
class _PenyimpananBisaBerubah extends SecureStorageService {
  _PenyimpananBisaBerubah(this.userId);

  String? userId;

  @override
  Future<String?> getUserId() async => userId;
}

/// API palsu yang tidak bisa dihubungi, meniru perangkat tanpa jaringan.
///
/// Dipakai supaya sinkronisasi tidak menyentuh cache: yang diuji adalah
/// perilaku langganan Drift, bukan pembaruan dari server.
class _ApiTerputus extends BookingApiService {
  @override
  Future<List<dynamic>> fetchBookings() async {
    throw Exception('jaringan tidak tersedia');
  }
}

/// Riwayat pesanan harus tetap tampil setelah sesi terbaca.
///
/// Regresi yang dicegah: langganan Drift dipasang sekali saat aplikasi dibuka,
/// ketika pemilik cache masih null. DAO menyaring baris dengan `userId` yang
/// ditangkap saat langganan dibuat, sehingga langganan itu terus memakai filter
/// tamu. Setiap tulisan ke Drift sesudahnya — termasuk hasil polling status —
/// memancarkan daftar kosong dan menghapus riwayat yang baru dimuat: pesanan
/// yang sudah dikonfirmasi admin tetap terlihat "belum ada pesanan" sampai
/// aplikasi ditutup paksa.
void main() {
  late AppDatabase database;
  late _PenyimpananBisaBerubah penyimpanan;
  late BookingRepository repository;
  late BookingController controller;

  final now = DateTime.now().toUtc().millisecondsSinceEpoch;

  BookingsCompanion barisPesanan(String id, {String? userId}) {
    return BookingsCompanion(
      id: Value(id),
      userId: Value(userId),
      vehicleId: const Value('avanza-g-putih-ps1692b'),
      startDate: Value(now),
      startTime: const Value('09.00 WIT'),
      durationDays: const Value(2),
      pickupLocation: const Value('Kantor MobilJuragan'),
      status: const Value('menungguPembayaran'),
      dailyRate: const Value(400000),
      serviceFee: const Value(0),
      paymentBank: const Value('BRI'),
      paymentAccountNumber: const Value('123'),
      createdAt: Value(now),
      lastFetched: Value(now),
    );
  }

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    penyimpanan = _PenyimpananBisaBerubah(null);
    repository = BookingRepository(
      database.bookingDao,
      _ApiTerputus(),
      penyimpanan,
    );
    controller = BookingController(repository: repository);
    // Beri kesempatan `_init` menyelesaikan pembacaan awal.
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.dispose();
    // Beri kesempatan pembatalan langganan selesai sebelum basis data ditutup.
    await Future<void>.delayed(Duration.zero);
    await database.close();
  });

  test('riwayat tidak terhapus saat Drift menulis setelah sesi terbaca',
      () async {
    await database.bookingDao
        .insertOrUpdateBooking(barisPesanan('MJ-A1', userId: 'user-A'));

    penyimpanan.userId = 'user-A';
    await controller.syncIfSessionChanged('user-A');

    expect(
      controller.bookingHistory.map((b) => b.id),
      contains('MJ-A1'),
    );

    /* Tulis apa pun ke Drift: sebelum perbaikan, langganan lama memakai filter
       tamu sehingga pemancaran berikutnya mengosongkan riwayat. */
    await database.bookingDao
        .insertOrUpdateBooking(barisPesanan('MJ-A2', userId: 'user-A'));
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.bookingHistory.map((b) => b.id).toSet(),
      containsAll(<String>{'MJ-A1', 'MJ-A2'}),
    );
    expect(controller.activeBooking?.id, isNotNull);
  });

  test('riwayat akun lain tidak ikut tampil setelah ganti sesi', () async {
    await database.bookingDao
        .insertOrUpdateBooking(barisPesanan('MJ-A1', userId: 'user-A'));

    penyimpanan.userId = 'user-A';
    await controller.syncIfSessionChanged('user-A');
    expect(
      controller.bookingHistory.map((b) => b.id),
      contains('MJ-A1'),
    );

    penyimpanan.userId = 'user-B';
    await controller.syncIfSessionChanged('user-B');
    expect(
      controller.bookingHistory.map((b) => b.id),
      isNot(contains('MJ-A1')),
    );
  });
}
