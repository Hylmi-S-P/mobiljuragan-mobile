import 'dart:async';
import '../../models/vehicle_model.dart';
import '../local/database/daos/vehicle_dao.dart';
import '../local/preferences/app_settings_service.dart';
import '../remote/vehicle_api_service.dart';

/// Repository Offline-First untuk entitas armada kendaraan
///
/// Mengatur sinkronisasi data backend ke database SQLite Drift lokal,
/// mengalirkan Stream reaktif ke UI, dan mempertahankan ketersediaan data saat offline.
class VehicleRepository {
  final VehicleDao vehicleDao;
  final VehicleApiService _apiService;
  final AppSettingsService settingsService;

  // Cache Time-To-Live: 5 Menit
  static const int cacheTtlMillis = 5 * 60 * 1000;

  VehicleRepository({
    required this.vehicleDao,
    VehicleApiService? apiService,
    required this.settingsService,
  })  : _apiService = apiService ?? VehicleApiService();

  /// Memastikan database lokal memiliki data dasar armada Merauke saat aplikasi pertama kali dijalankan
  Future<void> ensureSeeded() async {
    final count = await vehicleDao.countVehicles();
    if (count == 0) {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final seedEntries = VehicleModel.sampleVehicles
          .map((v) => v.toCompanion(lastFetchedMillis: now))
          .toList();
      await vehicleDao.upsertVehiclesBatch(seedEntries);
      await settingsService.setLastSyncTime(now);
    }
  }

  /// Stream reaktif seluruh armada kendaraan yang langsung bersumber dari database SQLite lokal
  Stream<List<VehicleModel>> watchVehicles({String category = 'Semua'}) {
    return vehicleDao.watchVehiclesByCategory(category).map((driftList) {
      return driftList.map((entry) => VehicleModel.fromDrift(entry)).toList();
    });
  }

  /// Stream reaktif armada favorit pengguna
  Stream<List<VehicleModel>> watchFavoriteVehicles() {
    return vehicleDao.watchFavoriteVehicles().map((driftList) {
      return driftList.map((entry) => VehicleModel.fromDrift(entry)).toList();
    });
  }

  /// Stream reaktif detail armada tunggal berdasarkan ID
  Stream<VehicleModel?> watchVehicleById(String id) {
    return vehicleDao.watchVehicleById(id).map((entry) {
      return entry != null ? VehicleModel.fromDrift(entry) : null;
    });
  }

  /// Mengambil data armada tunggal secara Future (Cache-First)
  Future<VehicleModel?> getVehicleById(String id) async {
    final entry = await vehicleDao.getVehicleById(id);
    if (entry != null) {
      return VehicleModel.fromDrift(entry);
    }
    return null;
  }

  /// Sinkronisasi Offline-First: Mengambil data dari backend dan menyimpannya ke Drift
  ///
  /// Menggunakan Database Transaction (Atomic Write) agar penulisan batch multi-baris aman.
  /// Jika offline atau koneksi gagal, data lokal tetap dipertahankan tanpa error yang memblokir UI.
  Future<bool> syncFromBackend({bool force = false}) async {
    final lastSync = settingsService.getLastSyncTime() ?? 0;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Lewati jika cache masih segar (< 5 menit) dan tidak dipaksa refresh
    if (!force && (now - lastSync < cacheTtlMillis)) {
      return false;
    }

    try {
      final rawList = await _apiService.fetchCatalog();
      if (rawList.isNotEmpty) {
        final companions = rawList.map((json) {
          final model = VehicleModel.fromJson(json);
          return model.toCompanion(lastFetchedMillis: now);
        }).toList();

        // Atomic Batch Upsert di dalam Drift transaction
        await vehicleDao.upsertVehiclesBatch(companions);
        await settingsService.setLastSyncTime(now);
        return true;
      }
    } catch (_) {
      // Offline fallback: jangan lempar exception agar aplikasi tetap jalan dengan cache lokal
    }
    return false;
  }

  /// Toggle status favorit pada armada (reaktif seketika melalui Stream Drift)
  Future<bool> toggleFavorite(String vehicleId) async {
    return await vehicleDao.toggleFavorite(vehicleId);
  }
}
