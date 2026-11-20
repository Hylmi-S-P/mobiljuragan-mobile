import 'package:drift/drift.dart';

/// Tabel penanda armada favorit milik satu akun.
///
/// Sebelumnya status favorit menumpang di kolom `Vehicles.isFavorite` yang
/// berlaku global untuk seluruh akun di perangkat yang sama. Akibatnya akun B
/// melihat armada favorit milik akun A, dan setelah logout penanda itu tetap
/// tertinggal. Karena itu favorit dipindahkan ke tabel tersendiri dan diikat
/// ke pemiliknya lewat kunci gabungan {userId, vehicleId}.
///
/// `userId` dibiarkan nullable agar baris milik mode tamu tetap punya tempat,
/// sama seperti kepemilikan pada tabel `Bookings`.
class Favorites extends Table {
  TextColumn get userId => text().nullable()();

  TextColumn get vehicleId => text()();

  /// Waktu penandaan, dipakai untuk urutan tampil bila diperlukan.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {userId, vehicleId};
}
