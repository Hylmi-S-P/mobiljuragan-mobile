import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/network/api_client.dart';
import '../../core/util/rental_duration.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../local/database/app_database.dart';
import '../local/database/daos/booking_dao.dart';
import '../local/database/daos/vehicle_dao.dart';
import '../local/secure/secure_storage_service.dart';
import '../remote/booking_api_service.dart';

/// Repository untuk penyimpanan dan sinkronisasi data pemesanan rental mobil (Offline-First Drift SQLite)
class BookingRepository {
  final BookingDao _bookingDao;
  final BookingApiService _apiService;
  final SecureStorageService? _secureStorage;

  final VehicleDao? _vehicleDao;

  /// Pemilik cache yang sedang aktif.
  ///
  /// Null berarti belum ada sesi (mode tamu). Nilai ini di-refresh dari secure
  /// storage setiap kali sesi berubah, jadi satu perangkat tidak pernah
  /// menampilkan riwayat pesanan akun lain.
  String? _userId;

  /// [vehicleDao] dipakai untuk membaca nama/plat unit dari tabel `vehicles`,
  /// [secureStorage] dipakai untuk mengetahui pemilik cache yang aktif.
  BookingRepository(
    this._bookingDao, [
    BookingApiService? apiService,
    SecureStorageService? secureStorage,
    this._vehicleDao,
  ])  : _apiService = apiService ?? BookingApiService(),
        _secureStorage = secureStorage;

  /// Membaca ulang identitas pemilik cache dari secure storage.
  Future<String?> refreshSession() async {
    _userId = await _secureStorage?.getUserId();
    return _userId;
  }

  String? get activeUserId => _userId;

  /// Menetapkan pemilik cache tanpa secure storage (dipakai pengujian).
  @visibleForTesting
  void setActiveUserForTest(String? userId) {
    _userId = userId;
  }

  /// Memfilter baris Drift milik akun aktif.
  ///
  /// Saat belum ada sesi (mode tamu), hanya baris **tanpa pemilik** yang boleh
  /// tampil. Sebelumnya mode tamu mengembalikan seluruh baris, sehingga riwayat
  /// akun yang sudah dihapus di server tetap terlihat oleh pengunjung yang tidak
  /// pernah logout.
  List<Booking> _ownedRows(List<Booking> rows) {
    final owner = _userId;
    if (owner == null) {
      return rows.where((row) => row.userId == null).toList();
    }
    return rows.where((row) => row.userId == owner).toList();
  }

  /// Menempelkan kepemilikan milik [owner] yang ditangkap di awal operasi.
  ///
  /// Dipakai setelah `await` jaringan: memakai `_userId` yang bisa berubah di
  /// tengah jalan akan mencap data akun lama sebagai milik akun baru.
  BookingsCompanion _ownedFor(
    BookingsCompanion companion,
    String? owner,
  ) {
    if (owner == null) return companion;
    return companion.copyWith(userId: Value(owner));
  }

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
    final owner = _userId;
    final driftList = _ownedRows(
      await _bookingDao.getAllBookings(userId: owner),
    );
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
    await for (final driftList in _bookingDao.watchAllBookings(userId: _userId)) {
      yield _ownedRows(driftList)
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
    await for (final driftList in _bookingDao.watchActiveBookings(userId: _userId)) {
      yield _ownedRows(driftList)
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

  /// Mengirim pesanan baru ke backend REST API dan menyimpannya secara atomik ke Drift SQLite.
  ///
  /// Tidak ada lagi pesanan karangan saat jaringan gagal. Dulu, kalau koneksi
  /// terputus, aplikasi membuat kode `MBJ-2026-xxxxx` sendiri dan menyimpannya
  /// seolah-olah pesanan itu sudah masuk. Pesanan seperti itu tidak pernah ada
  /// di server, sehingga tidak bisa dibayar, dibatalkan, maupun disinkronkan,
  /// dan pelanggan mengira pesanannya sudah tercatat padahal tidak. Sekarang
  /// kegagalan dilaporkan apa adanya dan pelanggan bisa mencoba lagi.
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
    final owner = await refreshSession();

    /* Jam yang dipilih pelanggan ikut dikirim. Sebelumnya hanya tanggalnya yang
       dipakai, sehingga pesanan selalu tercatat mulai tengah malam dan jam yang
       tampil di layar tinjauan tidak pernah berlaku. */
    final mulai = gabungTanggalDanJam(startDate, startTime);
    final end = mulai.add(
      Duration(days: durationDays > 0 ? durationDays : 1),
    );

    final res = await _apiService.createBooking(
      vehicleId: vehicle.id,
      startDateTime: mulai,
      endDateTime: end,
      withDriver: withDriver,
      pickupLocation: pickupLocation,
      customerRequest: note,
    );

    if (res.isEmpty || (res['bookingCode'] == null && res['id'] == null)) {
      throw ApiException(
        'Server tidak mengembalikan kode pesanan. Silakan coba lagi.',
      );
    }

    /* Sesi bisa berganti selama permintaan berjalan (pengguna menekan keluar
       atau masuk dengan akun lain). Baris hasil permintaan akun lama tidak boleh
       dicap sebagai milik akun yang baru. */
    final ownerSekarang = _userId;
    if (ownerSekarang != owner) {
      throw ApiException(
        'Sesi berubah saat pesanan dikirim. Silakan periksa riwayat pesanan.',
      );
    }

    final vehicleJson = res['vehicle'] is Map
        ? Map<String, dynamic>.from(res['vehicle'] as Map)
        : null;
    final resolvedVehicle = vehicleJson != null
        ? (_resolveVehicle(vehicleJson: vehicleJson, vehicleId: vehicle.id) ??
              vehicle)
        : vehicle;

    final remoteModel = BookingModel.fromJson(res, resolvedVehicle).copyWith(
      startTime: startTime,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
    );
    await _bookingDao.insertOrUpdateBooking(
      _ownedFor(remoteModel.toCompanion(), owner),
    );
    return remoteModel;
  }

  /// Sinkronisasi status pesanan dan rincian penyesuaian biaya dari backend ke SQLite lokal
  Future<BookingModel?> syncBookingStatus(
    String bookingId, {
    Map<String, VehicleModel>? vehicleMap,
  }) async {
    final owner = await refreshSession();
    final map = vehicleMap ?? _defaultVehicleMap;
    try {
      final res = await _apiService.fetchBookingDetail(bookingId);

      // Pemilik berganti selama menunggu jawaban: hasilnya bukan untuk akun ini.
      if (_userId != owner) return null;

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
        await _bookingDao.insertOrUpdateBooking(
          _ownedFor(updatedModel.toCompanion(), owner),
        );
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
    final owner = await refreshSession();
    try {
      final list = await _apiService.fetchBookings();

      /* Pemilik berganti selama pengambilan data. Melanjutkan berarti menulis
         riwayat akun lama dengan cap akun baru, atau menghapus riwayat akun baru
         karena dianggap bukan milik sesi ini. */
      if (_userId != owner) return [];

      /* Mode tamu tidak punya riwayat di server. Jangan menyentuh cache: yang
         ada di perangkat mungkin milik akun yang sesinya belum terbaca. */
      if (owner == null) return [];

      /* Baris milik akun lain dibuang lebih dulu, lalu baris milik akun ini
         yang tidak lagi dikirim server ikut dibuang. Tidak memakai
         `clearAllBookings()`: cara lama menghapus seluruh tabel, termasuk baris
         tamu, dan tetap menyisakan riwayat akun yang sudah dihapus di server
         ketika pengambilan datanya gagal. */
      await _bookingDao.deleteBookingsNotOwnedBy(owner);

      final List<BookingModel> synced = [];
      final idsDariServer = <String>{};
      for (final item in list) {
        if (item is! Map) continue;
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
        await _bookingDao.insertOrUpdateBooking(
          _ownedFor(model.toCompanion(), owner),
        );
        idsDariServer.add(model.id);
        synced.add(model);
      }

      await _bookingDao.deleteBookingsOwnedByExcept(owner, idsDariServer.toList());
      return synced;
    } on ApiException catch (e) {
      /* Server menyatakan sesi ini tidak berlaku lagi (akun dihapus, token
         dicabut, atau pengguna tidak ditemukan). Riwayat yang tersimpan di
         perangkat harus ikut hilang: menampilkannya membuat pengunjung melihat
         pesanan milik akun yang sudah tidak ada. */
      final kode = e.statusCode;
      if (kode == 401 || kode == 403 || kode == 404) {
        if (_userId != owner) return [];
        if (owner != null) {
          await _bookingDao.deleteBookingsOwnedBy(owner);
        } else {
          await _bookingDao.deleteBookingsWithOwner();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Menghapus seluruh baris pesanan tanpa memandang pemilik.
  ///
  /// Hanya untuk pembersihan menyeluruh satu perangkat. Jalur logout memakai
  /// [wipeOwnedRows] supaya riwayat akun lain di perangkat yang sama tetap utuh.
  Future<void> clearLocalBookings() async {
    await _bookingDao.clearAllBookings();
  }

  /// Menghapus baris pesanan milik satu akun saja.
  ///
  /// Dipakai saat logout: hanya riwayat akun yang keluar yang dibuang.
  Future<int> wipeOwnedRows(String? userId) async {
    return _bookingDao.wipeOwnedRows(userId);
  }

  /// Membuang cache milik akun lain setelah login berhasil.
  ///
  /// Baris tanpa pemilik (data contoh tamu, atau sisa versi lama) ikut dibuang
  /// supaya tidak menyamar sebagai riwayat akun yang baru masuk.
  Future<void> purgeOtherAccounts() async {
    final owner = _userId ?? await refreshSession();
    if (owner == null) {
      /* Mode tamu: baris ber-pemilik tidak boleh tampil sama sekali. */
      await _bookingDao.deleteBookingsWithOwner();
      return;
    }
    await _bookingDao.deleteBookingsNotOwnedBy(owner);
  }

  /// Menyimpan pesanan atau pembaruan status ke dalam SQLite lokal (Offline-First)
  ///
  /// Hanya mengirimkan createBooking ke remote jika pesanan belum ada di
  /// database lokal, guna mencegah duplikasi pesanan saat pembaruan status
  /// (seperti pembatalan).
  ///
  /// Baris yang kolom JSON-nya sudah rusak tidak ditulis ulang. Model hasil
  /// [BookingModel.fromDrift] membawa [BookingModel.rawCorrupted]; kalau
  /// ditandai, penulisan dilewati sama sekali supaya isi mentah yang masih
  /// tersimpan tidak berubah menjadi data kosong.
  Future<void> saveBooking(BookingModel booking) async {
    final owner = await refreshSession();

    if (booking.rawCorrupted) return;

    /* Kode pesanan yang sudah dipakai pemilik lain tidak boleh ditimpa. Kunci
       utama tabel hanya `{id}`, jadi `insertOnConflictUpdate` akan mengganti
       baris beserta kolom pemiliknya tanpa peringatan. Karena itu pemilik baris
       diperiksa lebih dulu lewat query khusus, dan penulisan dilewati bila
       baris itu ternyata milik akun lain (atau milik tamu). */
    final sudahAda = await _bookingDao.hasBookingWithId(booking.id);
    if (sudahAda) {
      final pemilikLama = await _bookingDao.getOwnerOfBooking(booking.id);
      if (pemilikLama != owner) return;
    }

    final existing = await _bookingDao.getBookingById(
      booking.id,
      userId: owner,
    );

    await _bookingDao.insertOrUpdateBooking(
      _ownedFor(booking.toCompanion(), owner),
    );

    if (existing == null) {
      if (_userId != owner) return;
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
      } on ApiException catch (e) {
        /* Server menolak pesanan ini (validasi, kuota, atau bentrok jadwal).
           Baris lokalnya dibuang: pesanan yang tidak pernah ada di server tidak
           bisa dibayar maupun dibatalkan, dan hanya membingungkan pelanggan.
           Kegagalan jaringan tidak masuk ke sini — pesanan tetap disimpan untuk
           dikirim ulang saat online. */
        final kode = e.statusCode;
        if (kode != null && kode >= 400 && kode < 500) {
          await _bookingDao.deleteBookingById(booking.id, userId: owner);
        }
      } catch (_) {
        // Offline-first fallback: pesanan tetap tersimpan di database SQLite lokal
      }
    }
  }

  /// Memperbarui status pesanan secara spesifik di Drift.
  ///
  /// Pemilik disebut eksplisit supaya kode pesanan milik akun lain tidak ikut
  /// berubah saat sinkronisasi.
  Future<void> updateBookingStatus(String id, BookingStatus newStatus) async {
    final owner = await refreshSession();
    await _bookingDao.updateBookingStatus(id, newStatus.name, userId: owner);
  }

  /// Mengirimkan pembatalan pesanan ke backend API.
  ///
  /// Mengembalikan data pesanan yang sudah dibatalkan (berisi `refund` bila
  /// pembatalan ini memicu pengembalian dana), atau `null` bila gagal/offline.
  /// Nominal refund SELALU berasal dari server; aplikasi tidak menghitung
  /// sendiri potongannya.
  Future<Map<String, dynamic>?> cancelBookingRemote({
    required String bookingId,
    String? reason,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
  }) async {
    try {
      final res = await _apiService.cancelBooking(
        bookingId: bookingId,
        reason: reason,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
      );
      final booking = res['booking'];
      if (booking is Map) {
        return Map<String, dynamic>.from(booking);
      }
      return res.isEmpty ? null : res;
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Mengirim rekening tujuan pengembalian dana untuk pesanan yang sudah batal.
  ///
  /// Mengembalikan `null` bila server menolak atau tidak terjangkau, supaya
  /// pemanggil tidak menampilkan rekening yang sebenarnya belum tersimpan.
  Future<Map<String, dynamic>?> claimRefundAccountRemote({
    required String bookingId,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      final res = await _apiService.claimRefundAccount(
        bookingId: bookingId,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
      );
      final refund = res['refund'];
      if (refund is Map) {
        return Map<String, dynamic>.from(refund);
      }
      return res.isEmpty ? null : res;
    } catch (_) {
      return null;
    }
  }
}
