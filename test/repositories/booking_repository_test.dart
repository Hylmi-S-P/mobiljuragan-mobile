import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/core/network/api_client.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/remote/booking_api_service.dart';
import 'package:mobiljuragan_mobile/data/repositories/booking_repository.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';

/// Test double untuk BookingApiService
class FakeBookingApiService extends BookingApiService {
  int createCount = 0;
  int cancelCount = 0;
  String? lastCancelledBookingId;
  String? lastVehicleId;
  DateTime? lastStart;
  DateTime? lastEnd;
  bool? lastWithDriver;
  Exception? exceptionToThrow;

  FakeBookingApiService({this.exceptionToThrow});

  @override
  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    cancelCount++;
    lastCancelledBookingId = bookingId;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return {'status': 'success', 'message': 'Booking cancelled'};
  }

  @override
  Future<Map<String, dynamic>> createBooking({
    required String vehicleId,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool withDriver,
    String? pickupLocation,
    String? customerRequest,
    int? numberGuests,
  }) async {
    createCount++;
    lastVehicleId = vehicleId;
    lastStart = startDateTime;
    lastEnd = endDateTime;
    lastWithDriver = withDriver;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return {
      'id': 'bkg-uuid-1234',
      'bookingCode': 'MJ-20261022-TEST',
      'vehicleId': vehicleId,
    };
  }

  @override
  Future<List<dynamic>> fetchBookings() async {
    return [];
  }
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('BookingRepository Offline-First & API Integration Tests', () {
    test('saveBooking menyimpan ke Drift SQLite dan mengirimkan reservasi ke REST backend', () async {
      final fakeApi = FakeBookingApiService();
      final repository = BookingRepository(database.bookingDao, fakeApi);

      final vehicle = VehicleModel.sampleVehicles.first;
      final booking = BookingModel(
        id: 'MBJ-2026-0043',
        vehicle: vehicle,
        startDate: DateTime.utc(2026, 10, 25, 8, 0),
        startTime: '08.00 WIT',
        durationDays: 3,
        withDriver: true,
        pickupLocation: 'Bandara Mopah Merauke',
        note: 'Mohon siapkan unit bersih',
        status: BookingStatus.menungguTarifFinal,
        createdAt: DateTime.now(),
        dailyRate: 400000,
        serviceFee: 25000,
      );

      await repository.saveBooking(booking);

      // Verifikasi Drift SQLite menyimpan pesanan
      final allBookings = await repository.getAllBookings();
      final savedInDrift = allBookings.firstWhere((b) => b.id == 'MBJ-2026-0043');
      expect(savedInDrift, isNotNull);
      expect(savedInDrift.vehicle.id, equals(vehicle.id));

      // Verifikasi API client dipanggil
      expect(fakeApi.createCount, equals(1));
      expect(fakeApi.lastVehicleId, equals(vehicle.id));
      expect(fakeApi.lastWithDriver, isTrue);
      expect(fakeApi.lastEnd!.difference(fakeApi.lastStart!).inDays, equals(3));
    });

    test('saveBooking tetap menyimpan ke Drift SQLite saat backend offline (graceful resilience)', () async {
      final fakeApi = FakeBookingApiService(
        exceptionToThrow: ApiException('Koneksi terputus (Offline)', statusCode: 503),
      );
      final repository = BookingRepository(database.bookingDao, fakeApi);

      final vehicle = VehicleModel.sampleVehicles.first;
      final booking = BookingModel(
        id: 'MBJ-2026-0044',
        vehicle: vehicle,
        startDate: DateTime.utc(2026, 10, 26, 9, 0),
        startTime: '09.00 WIT',
        durationDays: 1,
        withDriver: false,
        pickupLocation: 'Hotel Megaria Merauke',
        status: BookingStatus.menungguTarifFinal,
        createdAt: DateTime.now(),
        dailyRate: 400000,
        serviceFee: 25000,
      );

      // Eksekusi saveBooking saat offline - tidak melempar crash
      await repository.saveBooking(booking);

      expect(fakeApi.createCount, equals(1));
      final allBookings = await repository.getAllBookings();
      final savedInDrift = allBookings.firstWhere((b) => b.id == 'MBJ-2026-0044');
      expect(savedInDrift, isNotNull);
      expect(savedInDrift.id, equals('MBJ-2026-0044'));
    });

    test('cancelBookingRemote memanggil API pembatalan dan menangani offline fallback', () async {
      final fakeApi = FakeBookingApiService();
      final repository = BookingRepository(database.bookingDao, fakeApi);

      final success = await repository.cancelBookingRemote(
        bookingId: 'bkg-123',
        reason: 'Rencana berubah',
      );

      expect(success, isTrue);
      expect(fakeApi.cancelCount, equals(1));
      expect(fakeApi.lastCancelledBookingId, equals('bkg-123'));

      // Uji offline fallback
      final offlineApi = FakeBookingApiService(exceptionToThrow: Exception('Offline network error'));
      final offlineRepo = BookingRepository(database.bookingDao, offlineApi);
      final offlineResult = await offlineRepo.cancelBookingRemote(bookingId: 'bkg-999');
      expect(offlineResult, isFalse);
    });
  });
}
