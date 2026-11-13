import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/bookings_table.dart';

part 'booking_dao.g.dart';

/// Data Access Object (DAO) untuk tabel Bookings
/// Menyediakan stream reaktif (.watch()) dan penulisan batch secara atomik dalam transaksi database.
///
/// Setiap pembacaan menerima `userId` pemilik cache. Penyaringan dilakukan di
/// SQL, bukan setelah baris terbaca: satu perangkat bisa menyimpan riwayat
/// beberapa akun, dan baris milik akun lain tidak boleh pernah ikut terkirim ke
/// lapisan tampilan. `userId == null` berarti mode tamu — hanya baris tanpa
/// pemilik yang boleh terlihat.
@DriftAccessor(tables: [Bookings])
class BookingDao extends DatabaseAccessor<AppDatabase> with _$BookingDaoMixin {
  BookingDao(super.db);

  /// Menyaring baris sesuai pemilik cache.
  SimpleSelectStatement<$BookingsTable, Booking> _milik(
    SimpleSelectStatement<$BookingsTable, Booking> query,
    String? userId,
  ) {
    if (userId == null) {
      return query..where((tbl) => tbl.userId.isNull());
    }
    return query..where((tbl) => tbl.userId.equals(userId));
  }

  /// Stream reaktif seluruh riwayat pemesanan pelanggan
  Stream<List<Booking>> watchAllBookings({String? userId}) {
    final query = select(bookings)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return _milik(query, userId).watch();
  }

  /// Stream reaktif untuk pesanan yang masih aktif (belum selesai / belum dibatalkan)
  Stream<List<Booking>> watchActiveBookings({String? userId}) {
    final query = select(bookings)
      ..where((tbl) => tbl.status.isNotIn(['selesai', 'dibatalkan']))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return _milik(query, userId).watch();
  }

  /// Stream reaktif untuk satu detail pemesanan berdasarkan kode pesanan
  Stream<Booking?> watchBookingById(String id) {
    return (select(bookings)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// Mengambil seluruh riwayat pemesanan milik satu akun
  Future<List<Booking>> getAllBookings({String? userId}) {
    final query = select(bookings)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return _milik(query, userId).get();
  }

  /// Mengambil satu data pemesanan berdasarkan ID atau kode pesanan
  Future<Booking?> getBookingById(String id) {
    return (select(bookings)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Menghitung jumlah pesanan yang tersimpan milik satu akun
  Future<int> countBookings({String? userId}) async {
    final countExp = bookings.id.count();
    final query = selectOnly(bookings)..addColumns([countExp]);
    if (userId == null) {
      query.where(bookings.userId.isNull());
    } else {
      query.where(bookings.userId.equals(userId));
    }
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Transaksi Database Atomik (Atomic Write) untuk daftar pesanan
  Future<void> upsertBookingsBatch(List<BookingsCompanion> entries) async {
    await transaction(() async {
      for (final entry in entries) {
        await into(bookings).insertOnConflictUpdate(entry);
      }
    });
  }

  /// Menyimpan satu pesanan baru secara atomik
  Future<void> insertOrUpdateBooking(BookingsCompanion entry) async {
    await into(bookings).insertOnConflictUpdate(entry);
  }

  /// Memperbarui status pemesanan
  Future<void> updateBookingStatus(String id, String newStatus) async {
    await (update(bookings)..where((tbl) => tbl.id.equals(id))).write(
      BookingsCompanion(
        status: Value(newStatus),
      ),
    );
  }

  /// Menghapus seluruh data pemesanan lokal
  Future<int> clearAllBookings() async {
    return delete(bookings).go();
  }

  /// Menghapus cache milik akun lain (termasuk baris lama tanpa pemilik).
  ///
  /// Dipakai setelah login berhasil: cache akun sebelumnya tidak boleh ikut
  /// tampil di akun baru.
  Future<int> deleteBookingsNotOwnedBy(String userId) async {
    return (delete(bookings)
          ..where((tbl) => tbl.userId.isNull() | tbl.userId.isNotIn([userId])))
        .go();
  }

  /// Menghapus seluruh baris yang punya pemilik.
  ///
  /// Dipakai saat sesi berakhir atau saat server menyatakan akunnya tidak ada
  /// lagi: yang tersisa hanya baris tamu, sehingga riwayat akun lama tidak
  /// menyamar sebagai milik pengunjung.
  Future<int> deleteBookingsWithOwner() async {
    return (delete(bookings)..where((tbl) => tbl.userId.isNotNull())).go();
  }

  /// Menghapus satu baris pesanan.
  ///
  /// Dipakai saat server menolak pembuatan pesanan: baris lokal yang tidak
  /// pernah ada di server akan menjadi "pesanan hantu" yang tidak bisa
  /// dibatalkan maupun dibayar.
  Future<int> deleteBookingById(String id) async {
    return (delete(bookings)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Menghapus seluruh baris milik satu akun.
  Future<int> deleteBookingsOwnedBy(String userId) async {
    return (delete(bookings)..where((tbl) => tbl.userId.equals(userId))).go();
  }

  /// Menghapus baris milik satu akun yang tidak lagi ada di daftar server.
  ///
  /// Dipakai setelah sinkronisasi: pesanan yang dihapus atau dibatalkan di
  /// tempat lain tidak boleh tertinggal di perangkat dan menyamar sebagai
  /// pesanan yang masih berlaku.
  Future<int> deleteBookingsOwnedByExcept(
    String userId,
    List<String> keepIds,
  ) async {
    final query = delete(bookings)..where((tbl) => tbl.userId.equals(userId));
    if (keepIds.isNotEmpty) {
      query.where((tbl) => tbl.id.isNotIn(keepIds));
    }
    return query.go();
  }
}
