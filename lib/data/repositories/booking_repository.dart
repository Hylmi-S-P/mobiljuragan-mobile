import 'dart:async';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../local/database/daos/booking_dao.dart';

/// Repository untuk penyimpanan dan sinkronisasi data pemesanan rental mobil
class BookingRepository {
  final BookingDao _bookingDao;

  BookingRepository(this._bookingDao);

  /// Inisialisasi data pemesanan awal jika database masih kosong
  Future<void> ensureSeeded(List<VehicleModel> availableVehicles) async {
    final count = await _bookingDao.countBookings();
    if (count == 0 && availableVehicles.isNotEmpty) {
      final samples = BookingModel.initialSampleBookings;
      if (samples.isNotEmpty) {
        final companions = samples.map((b) => b.toCompanion()).toList();
        await _bookingDao.upsertBookingsBatch(companions);
      }
    }
  }

  /// Stream reaktif seluruh pesanan pelanggan
  Stream<List<BookingModel>> watchAllBookings(Map<String, VehicleModel> vehicleMap) {
    return _bookingDao.watchAllBookings().map((driftList) {
      return driftList.map((entry) {
        final vehicle = vehicleMap[entry.vehicleId] ?? VehicleModel.sampleVehicles.first;
        return BookingModel.fromDrift(entry, vehicle);
      }).toList();
    });
  }

  /// Stream reaktif pesanan yang sedang aktif
  Stream<List<BookingModel>> watchActiveBookings(Map<String, VehicleModel> vehicleMap) {
    return _bookingDao.watchActiveBookings().map((driftList) {
      return driftList.map((entry) {
        final vehicle = vehicleMap[entry.vehicleId] ?? VehicleModel.sampleVehicles.first;
        return BookingModel.fromDrift(entry, vehicle);
      }).toList();
    });
  }

  /// Menyimpan pesanan baru ke dalam SQLite lokal
  Future<void> saveBooking(BookingModel booking) async {
    await _bookingDao.insertOrUpdateBooking(booking.toCompanion());
  }

  /// Memperbarui status pesanan
  Future<void> updateBookingStatus(String id, BookingStatus newStatus) async {
    await _bookingDao.updateBookingStatus(id, newStatus.name);
  }
}
