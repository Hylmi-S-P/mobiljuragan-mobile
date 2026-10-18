import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';

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
          imageUrl: const Value('assets/images/avanza_card.png'),
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
          imageUrl: const Value('assets/images/fortuner_card.png'),
          isFavorite: const Value(true),
          lastFetched: Value(nowMillis),
        ),
      ];

      // Jalankan atomic write batch
      await database.vehicleDao.upsertVehiclesBatch(companions);

      final count = await database.vehicleDao.countVehicles();
      expect(count, equals(2));

      final avanza = await database.vehicleDao.getVehicleById('avanza-test');
      expect(avanza, isNotNull);
      expect(avanza!.name, equals('Avanza Test Unit'));
      expect(avanza.lastFetched, equals(nowMillis));
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
          imageUrl: const Value('assets/images/hilux_card.png'),
          isFavorite: const Value(false),
          lastFetched: Value(nowMillis),
        ),
      ]);

      // Dengarkan stream watchFavoriteVehicles
      final favoriteStream = database.vehicleDao.watchFavoriteVehicles();

      expect(
        favoriteStream,
        emitsInOrder([
          isEmpty, // Awalnya belum ada yang favorit
          predicate<List<Vehicle>>((list) => list.length == 1 && list.first.id == 'hilux-test'),
        ]),
      );

      // Beri sedikit jeda mikro lalu panggil toggleFavorite
      await Future.delayed(const Duration(milliseconds: 50));
      final newStatus = await database.vehicleDao.toggleFavorite('hilux-test');
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
      await database.bookingDao.updateBookingStatus('MKQ-TEST-001', 'selesai');
      final all = await database.bookingDao.getAllBookings();
      expect(all.first.status, equals('selesai'));
    });
  });
}
