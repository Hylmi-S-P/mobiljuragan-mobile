import 'package:drift/drift.dart';

/// Skema tabel SQLite lokal Drift untuk entitas katalog armada kendaraan
class Vehicles extends Table {
  /// Pengenal unik armada (contoh: 'avanza-g-putih' atau UUID backend)
  TextColumn get id => text()();

  /// Nama lengkap kendaraan (contoh: 'AVANZA G PUTIH')
  TextColumn get name => text()();

  /// Nomor plat kendaraan (contoh: 'PS1692B')
  TextColumn get plateNumber => text()();

  /// Kategori kendaraan: 'MPV', 'SUV', 'Pickup'
  TextColumn get category => text()();

  /// Kapasitas kursi penumpang (contoh: '7 Penumpang')
  TextColumn get seatCapacity => text()();

  /// Tipe transmisi: 'Manual' atau 'Matic'
  TextColumn get transmission => text()();

  /// Tipe bodi armada (contoh: 'MPV Keluarga', 'SUV Tangguh')
  TextColumn get bodyType => text()();

  /// Kondisi armada (contoh: 'Siap Pakai', 'AC Dingin')
  TextColumn get condition => text()();

  /// Label ketersediaan (contoh: 'Tersedia • Lepas Kunci')
  TextColumn get availabilityTag => text()();

  /// Penanda armada paling diminati
  BoolColumn get isPopular => boolean().withDefault(const Constant(false))();

  /// Tarif sewa harian dalam Rupiah
  IntColumn get pricePerDay => integer()();

  /// URL atau aset gambar kartu
  TextColumn get imageUrl => text()();

  /// Gambar hero layar detail
  TextColumn get heroImageUrl => text().nullable()();

  /// Gambar spesifikasi layar detail
  TextColumn get detailImageUrl => text().nullable()();

  /// Status penanda kendaraan favorit pengguna (reaktif & offline)
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Atribut penanda cache wajib: Waktu terakhir data disinkronkan dari server (UTC Milliseconds)
  IntColumn get lastFetched => integer()();

  /// Waktu pembaruan di server (UTC Milliseconds)
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
