import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/vehicles_table.dart';

part 'vehicle_dao.g.dart';

/// Data Access Object (DAO) untuk tabel Vehicles
/// Menyediakan stream reaktif (.watch()) dan penulisan batch secara atomik dalam transaksi database.
@DriftAccessor(tables: [Vehicles])
class VehicleDao extends DatabaseAccessor<AppDatabase> with _$VehicleDaoMixin {
  VehicleDao(super.db);

  /// Stream reaktif seluruh katalog armada
  Stream<List<Vehicle>> watchAllVehicles() {
    return (select(vehicles)..orderBy([(tbl) => OrderingTerm.asc(tbl.name)])).watch();
  }

  /// Stream reaktif berdasarkan filter kategori
  Stream<List<Vehicle>> watchVehiclesByCategory(String category) {
    if (category.toLowerCase() == 'semua') {
      return watchAllVehicles();
    }
    if (category.toLowerCase() == 'favorit') {
      return watchFavoriteVehicles();
    }
    return (select(vehicles)
          ..where((tbl) => tbl.category.lower().equals(category.toLowerCase()))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  /// Stream reaktif khusus kendaraan yang ditandai favorit oleh pengguna
  Stream<List<Vehicle>> watchFavoriteVehicles() {
    return (select(vehicles)
          ..where((tbl) => tbl.isFavorite.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  /// Stream reaktif untuk satu detail kendaraan berdasarkan ID
  Stream<Vehicle?> watchVehicleById(String id) {
    return (select(vehicles)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// Mengambil data tunggal secara Future
  Future<Vehicle?> getVehicleById(String id) {
    return (select(vehicles)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Mengambil seluruh data armada sebagai List
  Future<List<Vehicle>> getAllVehicles() {
    return select(vehicles).get();
  }

  /// Menghitung jumlah armada di database lokal
  Future<int> countVehicles() async {
    final countExp = vehicles.id.count();
    final query = selectOnly(vehicles)..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Transaksi Database Atomik (Atomic Write)
  ///
  /// Menyimpan seluruh list armada dari respons server ke database lokal dalam 1 transaksi.
  /// Jika ada 1 baris yang gagal, seluruh penulisan akan di-rollback sehingga tidak merusak integritas data.
  Future<void> upsertVehiclesBatch(List<VehiclesCompanion> entries) async {
    await transaction(() async {
      for (final entry in entries) {
        // Pertahankan status isFavorite lokal jika armada sudah pernah di-bookmark sebelumnya
        final existing = await (select(vehicles)..where((tbl) => tbl.id.equals(entry.id.value))).getSingleOrNull();
        if (existing != null) {
          final mergedEntry = entry.copyWith(
            isFavorite: Value(existing.isFavorite),
          );
          await into(vehicles).insertOnConflictUpdate(mergedEntry);
        } else {
          await into(vehicles).insertOnConflictUpdate(entry);
        }
      }
    });
  }

  /// Mengubah status favorit armada secara instan
  Future<bool> toggleFavorite(String vehicleId) async {
    return await transaction(() async {
      final existing = await (select(vehicles)..where((tbl) => tbl.id.equals(vehicleId))).getSingleOrNull();
      if (existing == null) return false;

      final newStatus = !existing.isFavorite;
      await (update(vehicles)..where((tbl) => tbl.id.equals(vehicleId))).write(
        VehiclesCompanion(
          isFavorite: Value(newStatus),
        ),
      );
      return newStatus;
    });
  }
}
