import 'dart:async';
import '../../core/network/api_client.dart';
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

  /// Resolusi armada kendaraan secara akurat dari ID, externalId, atau payload JSON relasi
  VehicleModel _resolveVehicle({
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

    // 3. Cocokkan dengan sampleVehicles berdasarkan kecocokan ID, externalId, atau nama
    final searchKey = (extId ?? vehicleId ?? jsonId ?? '').toLowerCase();
    final nameKey = vehicleJson?['name']?.toString().toUpperCase();

    for (final v in VehicleModel.sampleVehicles) {
      final vIdLower = v.id.toLowerCase();
      if (searchKey.isNotEmpty) {
        if (vIdLower == searchKey ||
            vIdLower.contains(searchKey) ||
            searchKey.contains(vIdLower)) {
          return v;
        }
        final searchPrefix = searchKey.split('-').first;
        if (searchPrefix.length >= 4 && vIdLower.startsWith(searchPrefix)) {
          return v;
        }
      }
      if (nameKey != null) {
        final vNameUpper = v.name.toUpperCase();
        if (nameKey.contains(vNameUpper) || vNameUpper.contains(nameKey)) {
          return v;
        }
        final namePrefix = nameKey.split(' ').first;
        if (namePrefix.length >= 4 && vNameUpper.startsWith(namePrefix)) {
          return v;
        }
      }
    }

    // 4. Jika backend mengirimkan relasi vehicle lengkap, bangun VehicleModel dari JSON
    if (vehicleJson != null && vehicleJson.isNotEmpty) {
      return VehicleModel.fromJson(vehicleJson);
    }

    // 5. Fallback terakhir jika benar-benar tidak ditemukan
    return VehicleModel.sampleVehicles.first;
  }


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
      final vehicle = _resolveVehicle(
        vehicleId: entry.vehicleId,
        customMap: map,
      );
      return BookingModel.fromDrift(entry, vehicle);
    }).toList();
  }

  /// Stream reaktif seluruh pesanan pelanggan
  Stream<List<BookingModel>> watchAllBookings([Map<String, VehicleModel>? vehicleMap]) {
    final map = vehicleMap ?? _defaultVehicleMap;
    return _bookingDao.watchAllBookings().map((driftList) {
      return driftList.map((entry) {
        final vehicle = _resolveVehicle(
          vehicleId: entry.vehicleId,
          customMap: map,
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
        final vehicle = _resolveVehicle(
          vehicleId: entry.vehicleId,
          customMap: map,
        );
        return BookingModel.fromDrift(entry, vehicle);
      }).toList();
    });
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
    final end = startDate.add(Duration(days: durationDays > 0 ? durationDays : 1));

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
            ? _resolveVehicle(vehicleJson: vehicleJson, vehicleId: vehicle.id)
            : vehicle;

        final remoteModel = BookingModel.fromJson(res, resolvedVehicle).copyWith(
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
      serviceFee: 25000,
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
        final rawVehicleId = res['vehicleId']?.toString() ?? vehicleJson?['id']?.toString();

        final vehicle = _resolveVehicle(
          vehicleId: rawVehicleId,
          vehicleJson: vehicleJson,
          customMap: map,
        );

        final updatedModel = BookingModel.fromJson(res, vehicle);
        await _bookingDao.insertOrUpdateBooking(updatedModel.toCompanion());
        return updatedModel;
      }
    } catch (_) {}
    return null;
  }

  /// Sinkronisasi seluruh daftar pesanan pelanggan dari backend REST API ke SQLite lokal
  Future<List<BookingModel>> syncAllBookingsFromRemote([Map<String, VehicleModel>? vehicleMap]) async {
    final map = vehicleMap ?? _defaultVehicleMap;
    try {
      final list = await _apiService.fetchBookings();
      if (list.isNotEmpty) {
        final List<BookingModel> synced = [];
        for (final item in list) {
          if (item is Map) {
            final json = Map<String, dynamic>.from(item);
            final vehicleJson = json['vehicle'] is Map
                ? Map<String, dynamic>.from(json['vehicle'] as Map)
                : null;
            final rawVehicleId = json['vehicleId']?.toString() ?? vehicleJson?['id']?.toString();
            final vehicle = _resolveVehicle(
              vehicleId: rawVehicleId,
              vehicleJson: vehicleJson,
              customMap: map,
            );
            final model = BookingModel.fromJson(json, vehicle);
            await _bookingDao.insertOrUpdateBooking(model.toCompanion());
            synced.add(model);
          }
        }
        return synced;
      }
    } catch (_) {}
    return [];
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

  /// Memperbarui status pesanan secara spesifik di Drift
  Future<void> updateBookingStatus(String id, BookingStatus newStatus) async {
    await _bookingDao.updateBookingStatus(id, newStatus.name);
  }
}
