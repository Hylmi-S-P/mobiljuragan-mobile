import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/favorites_table.dart';
import '../tables/vehicles_table.dart';

part 'vehicle_dao.g.dart';

/// Satu baris armada beserta status favorit milik pemilik yang diminta.
typedef VehicleWithFavorite = ({Vehicle vehicle, bool isFavorite});

/// Data Access Object (DAO) untuk tabel Vehicles dan Favorites.
///
/// Menyediakan stream reaktif (.watch()) dan penulisan batch secara atomik
/// dalam transaksi database. Status favorit kini dipisahkan dari tabel armada:
/// penandanya disimpan di tabel Favorites dan selalu difilter berdasarkan
/// pemilik, sehingga akun lain di perangkat yang sama tidak ikut melihatnya.
@DriftAccessor(tables: [Vehicles, Favorites])
class VehicleDao extends DatabaseAccessor<AppDatabase>
    with _$VehicleDaoMixin {
  VehicleDao(super.db);

  /// Kondisi pencocokan baris favorit untuk pemilik tertentu.
  ///
  /// Pemilik `null` berarti mode tamu, dan tamu hanya melihat penanda yang
  /// juga tidak punya pemilik.
  Expression<bool> _milikFavorit(String? userId) {
    if (userId == null) return favorites.userId.isNull();
    return favorites.userId.equals(userId);
  }

  /// Stream reaktif seluruh katalog armada beserta status favorit pemiliknya
  Stream<List<VehicleWithFavorite>> watchAllVehicles({required String? userId}) {
    final query = select(vehicles).join([
      leftOuterJoin(
        favorites,
        favorites.vehicleId.equalsExp(vehicles.id) & _milikFavorit(userId),
      ),
    ]);
    query.orderBy([OrderingTerm.asc(vehicles.name)]);
    return query.watch().map(_keBarisFavorit);
  }

  /// Stream reaktif berdasarkan filter kategori
  Stream<List<VehicleWithFavorite>> watchVehiclesByCategory(
    String category, {
    required String? userId,
  }) {
    if (category.toLowerCase() == 'semua') {
      return watchAllVehicles(userId: userId);
    }
    if (category.toLowerCase() == 'favorit') {
      return watchFavoriteVehicles(userId: userId);
    }
    final query = select(vehicles).join([
      leftOuterJoin(
        favorites,
        favorites.vehicleId.equalsExp(vehicles.id) & _milikFavorit(userId),
      ),
    ]);
    query
      ..where(vehicles.category.lower().equals(category.toLowerCase()))
      ..orderBy([OrderingTerm.asc(vehicles.name)]);
    return query.watch().map(_keBarisFavorit);
  }

  /// Stream reaktif khusus kendaraan yang ditandai favorit oleh pengguna
  Stream<List<VehicleWithFavorite>> watchFavoriteVehicles({
    required String? userId,
  }) {
    final query = select(vehicles).join([
      innerJoin(favorites, favorites.vehicleId.equalsExp(vehicles.id)),
    ]);
    query
      ..where(_milikFavorit(userId))
      ..orderBy([OrderingTerm.asc(vehicles.name)]);
    return query.watch().map(_keBarisFavorit);
  }

  /// Stream reaktif untuk satu detail kendaraan berdasarkan ID
  Stream<VehicleWithFavorite?> watchVehicleById(
    String id, {
    required String? userId,
  }) {
    final query = select(vehicles).join([
      leftOuterJoin(
        favorites,
        favorites.vehicleId.equalsExp(vehicles.id) & _milikFavorit(userId),
      ),
    ]);
    query.where(vehicles.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _keSatuBarisFavorit(row),
    );
  }

  /// Mengambil data tunggal secara Future
  Future<VehicleWithFavorite?> getVehicleById(
    String id, {
    required String? userId,
  }) async {
    final query = select(vehicles).join([
      leftOuterJoin(
        favorites,
        favorites.vehicleId.equalsExp(vehicles.id) & _milikFavorit(userId),
      ),
    ]);
    query.where(vehicles.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _keSatuBarisFavorit(row);
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
  /// Menyimpan seluruh list armada dari respons server ke database lokal dalam
  /// 1 transaksi. Jika ada 1 baris yang gagal, seluruh penulisan akan
  /// di-rollback sehingga tidak merusak integritas data.
  ///
  /// Penanda favorit tidak lagi ikut ditulis di sini karena sudah dipisahkan ke
  /// tabel Favorites, jadi tidak ada lagi kolom global yang perlu dipertahankan
  /// saat armada diperbarui dari server.
  Future<void> upsertVehiclesBatch(List<VehiclesCompanion> entries) async {
    await transaction(() async {
      for (final entry in entries) {
        await into(vehicles).insertOnConflictUpdate(entry);
      }
    });
  }

  /// Menyamakan isi tabel lokal dengan daftar dari server.
  ///
  /// Berbeda dari [upsertVehiclesBatch] yang hanya menambah dan memperbarui,
  /// metode ini juga MENGHAPUS baris yang tidak ada lagi di server, lalu
  /// menyisipkan sisanya dalam satu transaksi.
  ///
  /// Kenapa perlu: dulu armada yang dihapus admin tetap tampil di aplikasi
  /// pelanggan selamanya, karena sinkronisasi hanya menambah tanpa pernah
  /// membuang. Kalau server mengembalikan daftar kosong, tabel lokal ikut
  /// dikosongkan.
  ///
  /// Penanda favorit tidak terpengaruh karena hidup di tabel Favorites. Baris
  /// favorit yang armadanya sudah hilang ikut dibersihkan agar tidak menumpuk.
  Future<void> gantiSeluruhArmada(List<VehiclesCompanion> entries) async {
    await transaction(() async {
      final idDariServer = entries.map((entry) => entry.id.value).toSet();

      final lokal = await select(vehicles).get();
      for (final baris in lokal) {
        if (!idDariServer.contains(baris.id)) {
          await (delete(
            vehicles,
          )..where((tbl) => tbl.id.equals(baris.id))).go();
        }
      }

      final favoritLokal = await select(favorites).get();
      for (final favorit in favoritLokal) {
        if (!idDariServer.contains(favorit.vehicleId)) {
          await (delete(favorites)..where(
                (tbl) =>
                    tbl.vehicleId.equals(favorit.vehicleId) &
                    (favorit.userId == null
                        ? tbl.userId.isNull()
                        : tbl.userId.equals(favorit.userId!)),
              ))
              .go();
        }
      }

      for (final entry in entries) {
        await into(vehicles).insertOnConflictUpdate(entry);
      }
    });
  }

  /// Mengubah status favorit armada untuk satu pemilik secara instan.
  ///
  /// Mengembalikan status favorit yang baru. Bila armadanya tidak dikenal,
  /// nilai `false` dikembalikan tanpa menulis apa pun.
  Future<bool> toggleFavorite(
    String vehicleId, {
    required String? userId,
  }) async {
    return await transaction(() async {
      final existing = await (select(
        vehicles,
      )..where((tbl) => tbl.id.equals(vehicleId))).getSingleOrNull();
      if (existing == null) return false;

      final barisFavorit = await (select(favorites)..where(
            (tbl) =>
                tbl.vehicleId.equals(vehicleId) & _milikFavorit(userId),
          ))
          .getSingleOrNull();

      if (barisFavorit == null) {
        await into(favorites).insert(
          FavoritesCompanion.insert(
            vehicleId: vehicleId,
            userId: Value(userId),
            createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ),
        );
        return true;
      }

      await (delete(favorites)..where(
            (tbl) =>
                tbl.vehicleId.equals(vehicleId) & _milikFavorit(userId),
          ))
          .go();
      return false;
    });
  }

  /// Menghapus penanda favorit milik pemilik tertentu saja.
  ///
  /// Dipakai saat logout supaya akun yang keluar tidak meninggalkan jejak,
  /// tanpa menyentuh penanda milik akun lain di perangkat yang sama.
  Future<int> wipeFavoritesOwnedBy(String? userId) async {
    final query = delete(favorites)..where((tbl) => _milikFavorit(userId));
    return await query.go();
  }

  /// Menghapus penanda favorit milik akun lain dan yang tanpa pemilik.
  ///
  /// Dipakai saat akun aktif berganti, agar penanda milik akun sebelumnya tidak
  /// menumpuk di perangkat.
  Future<int> deleteFavoritesNotOwnedBy(String userId) async {
    final query = delete(favorites)
      ..where((tbl) => tbl.userId.isNull() | tbl.userId.isNotIn([userId]));
    return await query.go();
  }

  /// Menghapus seluruh penanda favorit yang punya pemilik.
  ///
  /// Dipakai ketika server menyatakan akun sudah tidak berlaku, sehingga tidak
  /// ada lagi identitas yang boleh dipertahankan di perangkat.
  Future<int> deleteFavoritesWithOwner() async {
    final query = delete(favorites)
      ..where((tbl) => tbl.userId.isNotNull());
    return await query.go();
  }

  List<VehicleWithFavorite> _keBarisFavorit(List<TypedResult> rows) {
    return rows.map(_keSatuBarisFavorit).toList(growable: false);
  }

  VehicleWithFavorite _keSatuBarisFavorit(TypedResult row) {
    return (
      vehicle: row.readTable(vehicles),
      isFavorite: row.readTableOrNull(favorites) != null,
    );
  }
}
