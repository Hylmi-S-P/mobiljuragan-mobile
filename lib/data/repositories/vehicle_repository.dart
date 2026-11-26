import 'dart:async';

import '../../models/vehicle_model.dart';
import '../local/database/daos/vehicle_dao.dart';
import '../local/preferences/app_settings_service.dart';
import '../local/secure/secure_storage_service.dart';
import '../remote/vehicle_api_service.dart';

/// Repository Offline-First untuk entitas armada kendaraan
///
/// Mengatur sinkronisasi data backend ke database SQLite Drift lokal,
/// mengalirkan Stream reaktif ke UI, dan mempertahankan ketersediaan data saat
/// offline.
class VehicleRepository {
  final VehicleDao vehicleDao;
  final VehicleApiService _apiService;
  final AppSettingsService settingsService;
  final SecureStorageService? secureStorage;

  // Cache Time-To-Live: 5 Menit
  static const int cacheTtlMillis = 5 * 60 * 1000;

  /// Pemilik yang sedang aktif menurut penyimpanan aman.
  ///
  /// Dipakai sebagai nilai awal sebelum pemanggil memberi nilai yang lebih
  /// spesifik. Penanda favorit selalu diikat ke nilai ini supaya akun lain di
  /// perangkat yang sama tidak ikut melihat pilihannya.
  String? _userId;
  Future<bool>? _syncInFlight;

  VehicleRepository({
    required this.vehicleDao,
    VehicleApiService? apiService,
    required this.settingsService,
    this.secureStorage,
  }) : _apiService = apiService ?? VehicleApiService();

  /// Pemilik yang terakhir dibaca dari penyimpanan aman.
  String? get activeUserId => _userId;

  /// Membaca ulang pemilik aktif dari penyimpanan aman.
  Future<String?> refreshSession() async {
    _userId = await secureStorage?.getUserId();
    return _userId;
  }

  /// Mengunci pemilik untuk pengujian tanpa penyimpanan aman.
  void setActiveUserForTest(String? userId) {
    _userId = userId;
  }

  /*
   * Tidak ada lagi penyemaian armada contoh ke database lokal.
   *
   * Sebelumnya, saat basis data lokal masih kosong, aplikasi menyalin sembilan
   * unit contoh ke SQLite. Akibatnya katalog selalu tampak berisi walaupun admin
   * belum menambahkan satu unit pun, dan unit contoh itu tidak pernah hilang
   * walaupun backend sudah punya data sebenarnya.
   *
   * Sekarang katalog sepenuhnya mengikuti hasil sinkronisasi dari backend.
   * Kalau belum ada data, yang tampil adalah keadaan kosong.
   */

  /// Stream reaktif seluruh armada kendaraan yang langsung bersumber dari
  /// database SQLite lokal, sudah dilengkapi status favorit pemilik aktif.
  Stream<List<VehicleModel>> watchVehicles({
    String category = 'Semua',
    String? userId,
  }) {
    final pemilik = userId ?? _userId;
    return vehicleDao
        .watchVehiclesByCategory(category, userId: pemilik)
        .map(_keModel);
  }

  /// Stream reaktif armada favorit pengguna
  Stream<List<VehicleModel>> watchFavoriteVehicles({String? userId}) {
    final pemilik = userId ?? _userId;
    return vehicleDao.watchFavoriteVehicles(userId: pemilik).map(_keModel);
  }

  /// Stream reaktif detail armada tunggal berdasarkan ID
  Stream<VehicleModel?> watchVehicleById(String id, {String? userId}) {
    final pemilik = userId ?? _userId;
    return vehicleDao
        .watchVehicleById(id, userId: pemilik)
        .map((baris) => baris == null ? null : VehicleModel.fromDriftRow(baris));
  }

  /// Mengambil data armada tunggal secara Future (Cache-First)
  Future<VehicleModel?> getVehicleById(String id, {String? userId}) async {
    final pemilik = userId ?? _userId;
    final baris = await vehicleDao.getVehicleById(id, userId: pemilik);
    if (baris != null) {
      return VehicleModel.fromDriftRow(baris);
    }
    return null;
  }

  /// Sinkronisasi Offline-First: Mengambil data dari backend dan menyimpannya ke Drift
  ///
  /// Menggunakan Database Transaction (Atomic Write) agar penulisan batch multi-baris aman.
  /// Jika offline atau koneksi gagal, data lokal tetap dipertahankan tanpa error yang memblokir UI.
  Future<bool> syncFromBackend({bool force = false}) {
    if (_syncInFlight != null && !force) {
      return _syncInFlight!;
    }
    final inFlight = _jalankanSyncBackend(force: force);
    _syncInFlight = inFlight;
    return inFlight.whenComplete(() {
      if (identical(_syncInFlight, inFlight)) {
        _syncInFlight = null;
      }
    });
  }

  Future<bool> _jalankanSyncBackend({required bool force}) async {
    final lastSync = settingsService.getLastSyncTime() ?? 0;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Lewati jika cache masih segar (< 5 menit) dan tidak dipaksa refresh
    if (!force && (now - lastSync < cacheTtlMillis)) {
      return false;
    }

    try {
      final rawList = await _apiService.fetchCatalog();

      /*
       * Daftar kosong dari server tetap diproses.
       *
       * Sebelumnya ada syarat `rawList.isNotEmpty`, sehingga kalau admin
       * menghapus semua armada, aplikasi pelanggan tetap menampilkan unit lama
       * dari cache dan tidak pernah tahu katalognya sudah kosong.
       */
      final companions = rawList.map((json) {
        final model = VehicleModel.fromJson(json);
        return model.toCompanion(lastFetchedMillis: now);
      }).toList();

      // Samakan isi lokal dengan server: tambah, perbarui, dan buang yang hilang.
      await vehicleDao.gantiSeluruhArmada(companions);
      await settingsService.setLastSyncTime(now);
      return true;
    } catch (_) {
      // Offline fallback: jangan lempar exception agar aplikasi tetap jalan dengan cache lokal
    }
    return false;
  }

  /// Toggle status favorit pada armada milik pemilik aktif.
  ///
  /// Penanda disimpan di tabel Favorites yang terikat pemilik, sehingga
  /// perubahan langsung terlihat lewat Stream Drift tanpa menyentuh baris
  /// armada yang dipakai bersama.
  Future<bool> toggleFavorite(String vehicleId, {String? userId}) async {
    final pemilik = userId ?? _userId;
    return await vehicleDao.toggleFavorite(vehicleId, userId: pemilik);
  }

  /// Menghapus penanda favorit milik satu akun saja.
  Future<int> wipeFavoritesOwnedBy(String? userId) {
    return vehicleDao.wipeFavoritesOwnedBy(userId);
  }

  List<VehicleModel> _keModel(List<VehicleWithFavorite> baris) {
    return baris.map(VehicleModel.fromDriftRow).toList(growable: false);
  }
}
