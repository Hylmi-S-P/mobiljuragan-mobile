import 'dart:async';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../local/database/daos/booking_dao.dart';
import '../remote/booking_api_service.dart';

/// Repository untuk penyimpanan dan sinkronisasi data pemesanan rental mobil (Offline-First Drift SQLite)
class BookingRepository {
  final BookingDao _bookingDao;
  final BookingApiService _apiService;

  BookingRepository(this._bookingDao, [BookingApiService? apiService])
      : _apiService = apiService ?? BookingApiService();

  Map<String, VehicleModel> get _defaultVehicleMap => {
        for (final v in VehicleModel.sampleVehicles) v.id: v,
      };

  /// Inisialisasi data pemesanan awal jika database masih kosong
  Future<void> ensureSeeded([List<VehicleModel>? availableVehicles]) async {
    final count = await _bookingDao.countBookings();
    if (count == 0) {
      final samples = BookingModel.initialSampleBookings;
      if (samples.isNotEmpty) {
        final companions = samples.map((b) => b.toCompanion()).toList();
        await _bookingDao.upsertBookingsBatch(companions);
      }
    }
  }

  /// Mengambil seluruh riwayat pemesanan secara sinkron dari SQLite lokal
  Future<List<BookingModel>> getAllBookings([Map<String, VehicleModel>? vehicleMap]) async {
    final map = vehicleMap ?? _defaultVehicleMap;
    final driftList = await _bookingDao.getAllBookings();
    return driftList.map((entry) {
      final vehicle = map[entry.vehicleId] ??
          VehicleModel.sampleVehicles.firstWhere(
            (v) => v.id == entry.vehicleId,
            orElse: () => VehicleModel.sampleVehicles.first,
          );
      return BookingModel.fromDrift(entry, vehicle);
    }).toList();
  }

  /// Stream reaktif seluruh pesanan pelanggan
  Stream<List<BookingModel>> watchAllBookings([Map<String, VehicleModel>? vehicleMap]) {
    final map = vehicleMap ?? _defaultVehicleMap;
    return _bookingDao.watchAllBookings().map((driftList) {
      return driftList.map((entry) {
        final vehicle = map[entry.vehicleId] ??
            VehicleModel.sampleVehicles.firstWhere(
              (v) => v.id == entry.vehicleId,
              orElse: () => VehicleModel.sampleVehicles.first,
            );
        return BookingModel.fromDrift(entry, vehicle);
      }).toList();
    });
  }

  /// Stream reaktif pesanan yang sedang aktif
  Stream<List<BookingModel>> watchActiveBookings([Map<String, VehicleModel>? vehicleMap]) {
    final map = vehicleMap ?? _defaultVehicleMap;
    return _bookingDao.watchActiveBookings().map((driftList) {
      return driftList.map((entry) {
        final vehicle = map[entry.vehicleId] ??
            VehicleModel.sampleVehicles.firstWhere(
              (v) => v.id == entry.vehicleId,
              orElse: () => VehicleModel.sampleVehicles.first,
            );
        return BookingModel.fromDrift(entry, vehicle);
      }).toList();
    });
  }

  /// Menyimpan pesanan baru atau pembaruan status ke dalam SQLite lokal dan sinkronisasi ke backend jika online
  Future<void> saveBooking(BookingModel booking) async {
    await _bookingDao.insertOrUpdateBooking(booking.toCompanion());
    try {
      final start = booking.startDate;
      final end = start.add(Duration(days: booking.durationDays > 0 ? booking.durationDays : 1));
      await _apiService.createBooking(
        vehicleId: booking.vehicle.id,
        startDateTime: start,
        endDateTime: end,
        withDriver: booking.withDriver,
        pickupLocation: booking.pickupLocation,
        customerRequest: booking.note,
      );
    } catch (_) {
      // Offline-first fallback: pesanan tetap tersimpan di database SQLite lokal
    }
  }

  /// Memperbarui status pesanan secara spesifik
  Future<void> updateBookingStatus(String id, BookingStatus newStatus) async {
    await _bookingDao.updateBookingStatus(id, newStatus.name);
  }
}
