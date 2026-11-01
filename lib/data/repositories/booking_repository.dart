import 'dart:async';

import '../../core/network/api_client.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../local/database/daos/booking_dao.dart';
import '../local/database/daos/vehicle_dao.dart';
import '../remote/booking_api_service.dart';

/// Repository untuk penyimpanan dan sinkronisasi data pemesanan rental mobil (Offline-First Drift SQLite)
class BookingRepository {
  final BookingDao _bookingDao;
  final BookingApiService _apiService;

  final VehicleDao? _vehicleDao;

  BookingRepository(
    this._bookingDao, [
    BookingApiService? apiService,
    this._vehicleDao,
  ]) : _apiService = apiService ?? BookingApiService();

  /*
   * Peta armada yang tersimpan di basis data lokal.
   *
   * Tabel `bookings` hanya menyimpan `vehicleId`. Nama dan plat unitnya harus
   * diambil dari tabel `vehicles` supaya riwayat pesanan bisa ditampilkan.
   * Peta ini diisi dari hasil sinkronisasi backend, bukan dari daftar contoh
   * yang menempel di kode.
   */
  Map<String, VehicleModel> _petaKendaraan = {};

  Future<void> _muatPetaKendaraan() async {
    final dao = _vehicleDao;
    if (dao == null) return;
    final rows = await dao.getAllVehicles();
    _petaKendaraan = {
      for (final row in rows) row.id: VehicleModel.fromDrift(row),
    };
  }

  Map<String, VehicleModel> get _defaultVehicleMap => _petaKendaraan;

  /// Resolusi armada kendaraan secara akurat dari ID, externalId, atau payload JSON relasi.
  ///
  /// Mengembalikan null kalau unitnya tidak ditemukan di basis data. Pemanggil
  /// yang membaca dari basis data lokal melewati baris tersebut: menampilkan
  /// pesanan dengan unit karangan lebih buruk daripada tidak menampilkannya.
  VehicleModel? _resolveVehicle({
    String? vehicleId,
    Map<String, dynamic>? vehicleJson,
    Map<String, VehicleModel>? customMap,
  }) {
    final map = customMap ?? _defaultVehicleMap;

    // 1. Cek langsung di map jika vehicleId cocok
    if (vehicleId != null && map.containsKey(vehicleId)) {
      return map[vehicleId]!;
    }

    // 2. Cek jika vehicleJson memiliki externalId atau ID yang cocok di map
    final extId = vehicleJson?['externalId']?.toString();
    if (extId != null && map.containsKey(extId)) {
      return map[extId]!;
    }
    final jsonId = vehicleJson?['id']?.toString();
    if (jsonId != null && map.containsKey(jsonId)) {
      return map[jsonId]!;
    }

    // 3. Jika backend mengirimkan relasi vehicle lengkap, bangun dari JSON.
    if (vehicleJson != null && vehicleJson.isNotEmpty) {
      return VehicleModel.fromJson(vehicleJson);
    }

    // 4. Unit tidak dikenal.
    //
    // Bisa terjadi kalau unitnya sudah dihapus dari katalog tetapi pesanan
    // lamanya masih tersimpan di perangkat. Riwayat tetap ditampilkan dengan
    // keterangan apa adanya, bukan dengan data mobil karangan.
    return _kendaraanTidakDikenal(vehicleId ?? jsonId ?? extId ?? '-');
  }

  VehicleModel _kendaraanTidakDikenal(String id) {
    return VehicleModel(
      id: id,
      name: 'Unit tidak dikenal',
      plateNumber: '-',
      category: '-',
      seatCapacity: '-',
      transmission: '-',
      bodyType: '-',
      condition: '-',
      availabilityTag: 'Tidak tersedia',
      pricePerDay: 0,
      imageUrl: '',
    );
  }

  /// Mengambil seluruh riwayat pemesanan secara sinkron dari SQLite lokal
  Future<List<BookingModel>> getAllBookings([
    Map<String, VehicleModel>? vehicleMap,
  ]) async {
    if (vehicleMap == null) await _muatPetaKendaraan();
    final map = vehicleMap ?? _defaultVehicleMap;
    final driftList = await _bookingDao.getAllBookings();
    return driftList
        .map((entry) {
          final vehicle = _resolveVehicle(
            vehicleId: entry.vehicleId,
            customMap: map,
          );
          if (vehicle == null) return null;
          return BookingModel.fromDrift(entry, vehicle);
        })
        .whereType<BookingModel>()
        .toList();
  }

  /// Stream reaktif seluruh pesanan pelanggan
  Stream<List<BookingModel>> watchAllBookings([
    Map<String, VehicleModel>? vehicleMap,
  ]) async* {
    if (vehicleMap == null) await _muatPetaKendaraan();
    final map = vehicleMap ?? _defaultVehicleMap;
    await for (final driftList in _bookingDao.watchAllBookings()) {
      yield driftList
          .map((entry) {
            final vehicle = _resolveVehicle(
              vehicleId: entry.vehicleId,
              customMap: map,
            );
            if (vehicle == null) return null;
            return BookingModel.fromDrift(entry, vehicle);
          })
          .whereType<BookingModel>()
          .toList();
    }
  }

  /// Stream reaktif pesanan yang sedang aktif
  Stream<List<BookingModel>> watchActiveBookings([
    Map<String, VehicleModel>? vehicleMap,
  ]) async* {
    if (vehicleMap == null) await _muatPetaKendaraan();
    final map = vehicleMap ?? _defaultVehicleMap;
    await for (final driftList in _bookingDao.watchActiveBookings()) {
      yield driftList
          .map((entry) {
            final vehicle = _resolveVehicle(
              vehicleId: entry.vehicleId,
              customMap: map,
            );
            if (vehicle == null) return null;
            return BookingModel.fromDrift(entry, vehicle);
          })
          .whereType<BookingModel>()
          .toList();
    }
  }

  /// Mengirim pesanan baru ke backend REST API dan menyimpannya secara atomik ke Drift SQLite
  Future<BookingModel> createBookingRemote({
    required VehicleModel vehicle,
    required DateTime startDate,
    required String startTime,
    required int durationDays,
    required bool withDriver,
    required String pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? note,
  }) async {
    final end = startDate.add(
      Duration(days: durationDays > 0 ? durationDays : 1),
    );

    try {
      final res = await _apiService.createBooking(
        vehicleId: vehicle.id,
        startDateTime: startDate,
        endDateTime: end,
        withDriver: withDriver,
        pickupLocation: pickupLocation,
        customerRequest: note,
      );

      if (res.isNotEmpty && (res['bookingCode'] != null || res['id'] != null)) {
        final vehicleJson = res['vehicle'] is Map
            ? Map<String, dynamic>.from(res['vehicle'] as Map)
            : null;
        final resolvedVehicle = vehicleJson != null
            ? (_resolveVehicle(
                    vehicleJson: vehicleJson,
                    vehicleId: vehicle.id,
                  ) ??
                  vehicle)
            : vehicle;

        final remoteModel = BookingModel.fromJson(res, resolvedVehicle)
            .copyWith(
              startTime: startTime,
              pickupLatitude: pickupLatitude,
              pickupLongitude: pickupLongitude,
            );
        await _bookingDao.insertOrUpdateBooking(remoteModel.toCompanion());
        return remoteModel;
      }
    } on ApiException {
      // Kesalahan spesifik dari backend (seperti 409 armada bentrok jadwal, validasi, dsb.)
      // Jangan disembunyikan sebagai fallback offline dummy agar pelanggan mengetahui alasan penolakan
      rethrow;
    } catch (_) {
      // Fallback offline-first hanya jika benar-benar kegagalan jaringan tak terjangkau
    }

    final fallbackCode =
        'MBJ-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final fallbackModel = BookingModel(
      id: fallbackCode,
      vehicle: vehicle,
      startDate: startDate,
      startTime: startTime,
      durationDays: durationDays,
      withDriver: withDriver,
      pickupLocation: pickupLocation,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      note: note,
      status: BookingStatus.menungguTarifFinal,
      createdAt: DateTime.now(),
      dailyRate: vehicle.pricePerDay,
      serviceFee: 0,
      adminAdjustments: const [],
      isFinalTariffConfirmed: false,
    );

    await _bookingDao.insertOrUpdateBooking(fallbackModel.toCompanion());
    return fallbackModel;
  }

  /// Sinkronisasi status pesanan dan rincian penyesuaian biaya dari backend ke SQLite lokal
  Future<BookingModel?> syncBookingStatus(
    String bookingId, {
    Map<String, VehicleModel>? vehicleMap,
  }) async {
    final map = vehicleMap ?? _defaultVehicleMap;
    try {
      final res = await _apiService.fetchBookingDetail(bookingId);
      if (res.isNotEmpty) {
        final vehicleJson = res['vehicle'] is Map
            ? Map<String, dynamic>.from(res['vehicle'] as Map)
            : null;
        final rawVehicleId =
            res['vehicleId']?.toString() ?? vehicleJson?['id']?.toString();

        final vehicle = _resolveVehicle(
          vehicleId: rawVehicleId,
          vehicleJson: vehicleJson,
          customMap: map,
        );

        if (vehicle == null) return null;
        final updatedModel = BookingModel.fromJson(res, vehicle);
        await _bookingDao.insertOrUpdateBooking(updatedModel.toCompanion());
        return updatedModel;
      }
    } catch (_) {}
    return null;
  }

  /// Sinkronisasi seluruh daftar pesanan pelanggan dari backend REST API ke SQLite lokal
  Future<List<BookingModel>> syncAllBookingsFromRemote([
    Map<String, VehicleModel>? vehicleMap,
  ]) async {
    final map = vehicleMap ?? _defaultVehicleMap;
    try {
      final list = await _apiService.fetchBookings();
      await _bookingDao.clearAllBookings();
      if (list.isNotEmpty) {
        final List<BookingModel> synced = [];
        for (final item in list) {
          if (item is Map) {
            final json = Map<String, dynamic>.from(item);
            final vehicleJson = json['vehicle'] is Map
                ? Map<String, dynamic>.from(json['vehicle'] as Map)
                : null;
            final rawVehicleId =
                json['vehicleId']?.toString() ?? vehicleJson?['id']?.toString();
            final vehicle = _resolveVehicle(
              vehicleId: rawVehicleId,
              vehicleJson: vehicleJson,
              customMap: map,
            );
            if (vehicle == null) continue;
            final model = BookingModel.fromJson(json, vehicle);
            await _bookingDao.insertOrUpdateBooking(model.toCompanion());
            synced.add(model);
          }
        }
        return synced;
      }
      return [];
    } catch (_) {}
    return [];
  }

  /// Menghapus seluruh data pemesanan lokal di Drift
  Future<void> clearLocalBookings() async {
    await _bookingDao.clearAllBookings();
  }

  /// Menyimpan pesanan atau pembaruan status ke dalam SQLite lokal (Offline-First)
  /// Hanya mengirimkan createBooking ke remote jika pesanan belum ada di database lokal,
  /// guna mencegah duplikasi pesanan saat pembaruan status (seperti pembatalan atau konfirmasi COD).
  Future<void> saveBooking(BookingModel booking) async {
    final existing = await _bookingDao.getBookingById(booking.id);
    await _bookingDao.insertOrUpdateBooking(booking.toCompanion());

    if (existing == null) {
      try {
        final start = booking.startDate;
        final end = start.add(
          Duration(days: booking.durationDays > 0 ? booking.durationDays : 1),
        );
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
  }

  /// Memperbarui status pesanan secara spesifik di Drift
  Future<void> updateBookingStatus(String id, BookingStatus newStatus) async {
    await _bookingDao.updateBookingStatus(id, newStatus.name);
  }

  /// Mengirimkan pembatalan pesanan ke backend API
  Future<bool> cancelBookingRemote({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final res = await _apiService.cancelBooking(
        bookingId: bookingId,
        reason: reason,
      );
      return res.isNotEmpty;
    } catch (_) {
      // Offline fallback: tetap aman jika offline
      return false;
    }
  }
}
