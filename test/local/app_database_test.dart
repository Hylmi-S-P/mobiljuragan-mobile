import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/local/database/daos/vehicle_dao.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late AppDatabase database;

  setUp(() {
    // Inisialisasi database in-memory untuk pengujian cepat & terisolasi
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Drift Local Structured Storage Tests', () {
    test('Batch Atomic Upsert in Database Transaction menulis multi-baris secara utuh', () async {
      final nowMillis = DateTime.now().toUtc().millisecondsSinceEpoch;

      final companions = [
        VehiclesCompanion(
          id: const Value('avanza-test'),
          name: const Value('Avanza Test Unit'),
          plateNumber: const Value('PA1234AA'),
          category: const Value('MPV'),
          seatCapacity: const Value('7 Penumpang'),
          transmission: const Value('Manual'),
          bodyType: const Value('MPV'),
          condition: const Value('Bagus'),
          availabilityTag: const Value('Tersedia'),
          isPopular: const Value(true),
          pricePerDay: const Value(400000),
          imageUrl: const Value('assets/images/avanza_card.webp'),
          isFavorite: const Value(false),
          lastFetched: Value(nowMillis),
        ),
        VehiclesCompanion(
          id: const Value('fortuner-test'),
          name: const Value('Fortuner Test Unit'),
          plateNumber: const Value('PA5678BB'),
          category: const Value('SUV'),
          seatCapacity: const Value('7 Penumpang'),
          transmission: const Value('Matic'),
          bodyType: const Value('SUV'),
          condition: const Value('Prima'),
          availabilityTag: const Value('Tersedia'),
          isPopular: const Value(false),
          pricePerDay: const Value(900000),
          imageUrl: const Value('assets/images/fortuner_card.webp'),
          isFavorite: const Value(true),
          lastFetched: Value(nowMillis),
        ),
      ];

      // Jalankan atomic write batch
      await database.vehicleDao.upsertVehiclesBatch(companions);

      final count = await database.vehicleDao.countVehicles();
      expect(count, equals(2));

      final avanza = await database.vehicleDao.getVehicleById(
        'avanza-test',
        userId: null,
      );
      expect(avanza, isNotNull);
      expect(avanza!.vehicle.name, equals('Avanza Test Unit'));
      expect(avanza.vehicle.lastFetched, equals(nowMillis));
      expect(avanza.isFavorite, isFalse);
    });

    test('Stream reaktif (.watch()) mengeluarkan data baru seketika saat toggleFavorite', () async {
      final nowMillis = DateTime.now().toUtc().millisecondsSinceEpoch;

      await database.vehicleDao.upsertVehiclesBatch([
        VehiclesCompanion(
          id: const Value('hilux-test'),
          name: const Value('Hilux Test Unit'),
          plateNumber: const Value('PA9999CC'),
          category: const Value('Pickup'),
          seatCapacity: const Value('5 Penumpang'),
          transmission: const Value('Manual'),
          bodyType: const Value('Pickup'),
          condition: const Value('Tangguh'),
          availabilityTag: const Value('Tersedia'),
          isPopular: const Value(false),
          pricePerDay: const Value(850000),
          imageUrl: const Value('assets/images/hilux_card.webp'),
          isFavorite: const Value(false),
          lastFetched: Value(nowMillis),
        ),
      ]);

      // Dengarkan stream watchFavoriteVehicles
      final favoriteStream = database.vehicleDao.watchFavoriteVehicles(
        userId: null,
      );

      expect(
        favoriteStream,
        emitsInOrder([
          isEmpty, // Awalnya belum ada yang favorit
          predicate<List<VehicleWithFavorite>>(
            (list) =>
                list.length == 1 &&
                list.first.vehicle.id == 'hilux-test' &&
                list.first.isFavorite,
          ),
        ]),
      );

      // Beri sedikit jeda mikro lalu panggil toggleFavorite
      await Future.delayed(const Duration(milliseconds: 50));
      final newStatus = await database.vehicleDao.toggleFavorite(
        'hilux-test',
        userId: null,
      );
      expect(newStatus, isTrue);
    });

    test('BookingDao atomic insert & status update', () async {
      final nowMillis = DateTime.now().toUtc().millisecondsSinceEpoch;

      final bookingEntry = BookingsCompanion(
        id: const Value('MKQ-TEST-001'),
        vehicleId: const Value('avanza-test'),
        startDate: Value(nowMillis),
        startTime: const Value('09.00 WIT'),
        durationDays: const Value(3),
        withDriver: const Value(false),
        pickupLocation: const Value('Bandara Mopah'),
        status: const Value('permintaanDiterima'),
        dailyRate: const Value(400000),
        serviceFee: const Value(25000),
        paymentBank: const Value('Bank BRI Merauke'),
        paymentAccountNumber: const Value('0087-01-002345-53-1'),
        isFinalTariffConfirmed: const Value(false),
        createdAt: Value(nowMillis),
        lastFetched: Value(nowMillis),
      );

      await database.bookingDao.insertOrUpdateBooking(bookingEntry);

      final count = await database.bookingDao.countBookings();
      expect(count, equals(1));

      // Update status
      await database.bookingDao.updateBookingStatus(
        'MKQ-TEST-001',
        'selesai',
        userId: null,
      );
      final all = await database.bookingDao.getAllBookings();
      expect(all.first.status, equals('selesai'));
    });

    test('Skema v9 mendaftarkan seluruh indeks performa di sqlite_master', () async {
      final rows = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name IN ('idx_vehicles_category', 'idx_favorites_user_vehicle', 'idx_bookings_user_created')",
      ).get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll(<String>{
          'idx_vehicles_category',
          'idx_favorites_user_vehicle',
          'idx_bookings_user_created',
        }),
      );
    });

    test('Migrasi v8 -> v9 membuat ketiga indeks tanpa merusak data lama', () async {
      final raw = sqlite.sqlite3.openInMemory();
      raw.execute('''
        CREATE TABLE vehicles (id TEXT PRIMARY KEY, category TEXT);
        CREATE TABLE favorites (user_id TEXT, vehicle_id TEXT, PRIMARY KEY (user_id, vehicle_id));
        CREATE TABLE bookings (id TEXT PRIMARY KEY, user_id TEXT, created_at INTEGER);
        PRAGMA user_version = 8;
      ''');
      final upgraded = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(upgraded.close);

      final rows = await upgraded.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name IN ('idx_vehicles_category', 'idx_favorites_user_vehicle', 'idx_bookings_user_created')",
      ).get();
      expect(rows.length, equals(3));
    });

    test('gantiSeluruhArmada menghapus armada usang & favorit yatim lalu upsert batch', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await database.vehicleDao.upsertVehiclesBatch([
        VehiclesCompanion.insert(
          id: 'v-lama',
          name: 'Lama',
          plateNumber: 'PA1',
          category: 'MPV',
          seatCapacity: '7',
          transmission: 'Manual',
          bodyType: 'MPV',
          condition: 'Baik',
          availabilityTag: 'Tersedia',
          pricePerDay: 400000,
          imageUrl: 'assets/images/avanza_card.webp',
          lastFetched: now,
        ),
      ]);
      await database.vehicleDao.toggleFavorite('v-lama', userId: 'u-1');

      await database.vehicleDao.gantiSeluruhArmada([
        VehiclesCompanion.insert(
          id: 'v-baru',
          name: 'Baru',
          plateNumber: 'PA2',
          category: 'SUV',
          seatCapacity: '7',
          transmission: 'Matic',
          bodyType: 'SUV',
          condition: 'Prima',
          availabilityTag: 'Tersedia',
          pricePerDay: 900000,
          imageUrl: 'assets/images/fortuner_card.webp',
          lastFetched: now,
        ),
      ]);

      final semua = await database.vehicleDao.getAllVehicles();
      expect(semua.map((v) => v.id).toList(), equals(['v-baru']));
      final fav = await database.vehicleDao.watchFavoriteVehicles(userId: 'u-1').first;
      expect(fav, isEmpty);
    });

    test('syncOwnedBookingsAtomically membersihkan akun lain dan pesanan usang dalam 1 transaksi', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      BookingsCompanion row(String id, String? uid) => BookingsCompanion.insert(
            id: id,
            userId: Value(uid),
            vehicleId: 'v-1',
            startDate: now,
            startTime: '09.00 WIT',
            durationDays: 1,
            pickupLocation: 'Bandara',
            status: 'menungguPembayaran',
            dailyRate: 400000,
            serviceFee: 0,
            paymentBank: 'BRI',
            paymentAccountNumber: '123',
            createdAt: now,
            lastFetched: now,
          );

      await database.bookingDao.upsertBookingsBatch([
        row('b-other', 'user-X'),
        row('b-stale', 'user-A'),
        row('b-keep', 'user-A'),
      ]);

      await database.bookingDao.syncOwnedBookingsAtomically(
        owner: 'user-A',
        entries: [row('b-keep', 'user-A'), row('b-new', 'user-A')],
        keepIds: ['b-keep', 'b-new'],
      );

      final ownedA = await database.bookingDao.getAllBookings(userId: 'user-A');
      expect(ownedA.map((b) => b.id).toSet(), equals({'b-keep', 'b-new'}));
      final ownedX = await database.bookingDao.getAllBookings(userId: 'user-X');
      expect(ownedX, isEmpty);
    });
  });
}
