import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/repositories/booking_repository.dart';

/// Riwayat pesanan harus terikat pada satu akun.
///
/// Regresi yang dicegah: cache Drift dibagi ke semua akun, sehingga setelah
/// logout/login akun lain masih melihat riwayat pemilik sebelumnya.
void main() {
  late AppDatabase database;
  late BookingRepository repository;

  final now = DateTime.now().toUtc().millisecondsSinceEpoch;

  BookingsCompanion bookingRow(String id, {String? userId}) {
    return BookingsCompanion(
      id: Value(id),
      userId: Value(userId),
      vehicleId: const Value('avanza-g-putih-ps1692b'),
      startDate: Value(now),
      startTime: const Value('09.00 WIT'),
      durationDays: const Value(1),
      pickupLocation: const Value('Kantor MobilJuragan'),
      status: const Value('permintaanDiterima'),
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
    repository = BookingRepository(database.bookingDao);
    await database.bookingDao.upsertBookingsBatch([
      bookingRow('book-a1', userId: 'user-A'),
      bookingRow('book-a2', userId: 'user-A'),
      bookingRow('book-b1', userId: 'user-B'),
      // Baris lama sebelum ada kolom userId (mis. data contoh tamu).
      bookingRow('book-legacy'),
    ]);
  });

  tearDown(() async {
    await database.close();
  });

  test('membaca riwayat hanya milik akun aktif', () async {
    repository.setActiveUserForTest('user-A');

    final milikA = await repository.getAllBookings();
    expect(milikA.map((b) => b.id).toSet(), {'book-a1', 'book-a2'});

    repository.setActiveUserForTest('user-B');
    final milikB = await repository.getAllBookings();
    expect(milikB.map((b) => b.id), ['book-b1']);
  });

  test('stream riwayat tidak membocorkan pesanan akun lain', () async {
    repository.setActiveUserForTest('user-A');

    final daftar = await repository.watchAllBookings().first;
    expect(daftar.map((b) => b.id).toSet(), {'book-a1', 'book-a2'});
  });

  test('purge membuang cache akun lain dan baris tanpa pemilik', () async {
    repository.setActiveUserForTest('user-A');
    await repository.purgeOtherAccounts();

    final tersisa = await database.bookingDao.getAllBookings();
    expect(tersisa.map((row) => row.id).toSet(), {'book-a1', 'book-a2'});
  });

  test('logout menghapus seluruh cache pesanan', () async {
    await repository.clearLocalBookings();

    final tersisa = await database.bookingDao.countBookings();
    expect(tersisa, 0);
  });

  test('setelah logout lalu masuk akun lain, riwayat akun lama tidak muncul', () async {
    repository.setActiveUserForTest('user-A');
    expect((await repository.getAllBookings()).length, 2);

    // Logout: cache dibuang seluruhnya (server tetap sumber kebenaran).
    await repository.clearLocalBookings();
    repository.setActiveUserForTest('user-B');

    final riwayatB = await repository.getAllBookings();
    expect(riwayatB, isEmpty);
  });

  test('akun baru tidak mewarisi baris akun lama meski purge belum jalan', () async {
    repository.setActiveUserForTest('user-B');

    final riwayatB = await repository.getAllBookings();
    expect(riwayatB.map((b) => b.id), ['book-b1']);
  });
}
