import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/bookings_table.dart';

part 'booking_dao.g.dart';

/// Data Access Object (DAO) untuk tabel Bookings
/// Menyediakan stream reaktif (.watch()) dan penulisan batch secara atomik dalam transaksi database.
@DriftAccessor(tables: [Bookings])
class BookingDao extends DatabaseAccessor<AppDatabase> with _$BookingDaoMixin {
  BookingDao(super.db);

  /// Stream reaktif seluruh riwayat pemesanan pelanggan
  Stream<List<Booking>> watchAllBookings() {
    return (select(bookings)..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).watch();
  }

  /// Stream reaktif untuk pesanan yang masih aktif (belum selesai / belum dibatalkan)
  Stream<List<Booking>> watchActiveBookings() {
    return (select(bookings)
          ..where((tbl) =>
              tbl.status.isNotIn(['selesai', 'dibatalkan']))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Stream reaktif untuk satu detail pemesanan berdasarkan kode pesanan
  Stream<Booking?> watchBookingById(String id) {
    return (select(bookings)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// Mengambil seluruh riwayat pemesanan
  Future<List<Booking>> getAllBookings() {
    return (select(bookings)..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).get();
  }

  /// Mengambil satu data pemesanan berdasarkan ID atau kode pesanan
  Future<Booking?> getBookingById(String id) {
    return (select(bookings)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Menghitung jumlah pesanan yang tersimpan
  Future<int> countBookings() async {
    final countExp = bookings.id.count();
    final query = selectOnly(bookings)..addColumns([countExp]);
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
}
