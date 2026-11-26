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
///
/// Sifat yang sama berlaku untuk pembacaan satu baris, pembaruan status, dan
/// penghapusan: semuanya wajib menyebut pemilik. Tanpa itu, sebuah kode pesanan
/// yang kebetulan sama di dua akun bisa saling menimpa.
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

  /// Syarat pemilik untuk pembaruan dan penghapusan.
  Expression<bool> _pemilik(String? userId, $BookingsTable tbl) {
    return userId == null ? tbl.userId.isNull() : tbl.userId.equals(userId);
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

  /// Stream reaktif untuk satu detail pemesanan berdasarkan kode pesanan.
  ///
  /// Pemilik wajib disebut supaya kode pesanan yang sama milik akun lain tidak
  /// pernah bocor ke layar akun yang sedang masuk.
  Stream<Booking?> watchBookingById(String id, {required String? userId}) {
    final query = select(bookings)
      ..where((tbl) => tbl.id.equals(id) & _pemilik(userId, tbl));
    return query.watchSingleOrNull();
  }

  /// Mengambil seluruh riwayat pemesanan milik satu akun
  Future<List<Booking>> getAllBookings({String? userId}) {
    final query = select(bookings)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return _milik(query, userId).get();
  }

  /// Mengambil satu data pemesanan berdasarkan ID atau kode pesanan.
  ///
  /// Pemilik wajib disebut, sama seperti [watchBookingById].
  Future<Booking?> getBookingById(String id, {required String? userId}) {
    final query = select(bookings)
      ..where((tbl) => tbl.id.equals(id) & _pemilik(userId, tbl));
    return query.getSingleOrNull();
  }

  /// Mengambil pemilik dari sebuah kode pesanan tanpa membaca isi barisnya.
  ///
  /// Dipakai untuk mendeteksi tabrakan kode pesanan antar akun: kalau baris
  /// dengan kode yang sama ternyata milik akun lain, penulisan harus dibatalkan
  /// alih-alih menimpa riwayat orang lain. `null` berarti baris tanpa pemilik
  /// (mode tamu) atau baris tidak ditemukan — pemanggil membedakannya lewat
  /// [countBookings] bila perlu.
  Future<String?> getOwnerOfBooking(String id) async {
    final query = selectOnly(bookings)
      ..addColumns([bookings.userId])
      ..where(bookings.id.equals(id))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.read(bookings.userId);
  }

  /// Memeriksa apakah sebuah kode pesanan sudah dipakai baris mana pun.
  ///
  /// Dipakai bersama [getOwnerOfBooking] untuk membedakan "baris belum ada"
  /// dari "baris ada tetapi tanpa pemilik" (mode tamu). Tanpa pemeriksaan ini
  /// penulisan bisa menimpa baris tamu secara diam-diam.
  Future<bool> hasBookingWithId(String id) async {
    final query = selectOnly(bookings)
      ..addColumns([bookings.id])
      ..where(bookings.id.equals(id))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row != null;
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
    if (entries.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(bookings, entries);
    });
  }

  /// Menyinkronkan pesanan milik [owner] dalam 1 transaksi atomik (bersihkan
  /// milik akun lain, batch upsert pesanan baru, lalu buang pesanan usang)
  /// agar listener stream UI tidak berkedip berkali-kali.
  Future<void> syncOwnedBookingsAtomically({
    required String owner,
    required List<BookingsCompanion> entries,
    required List<String> keepIds,
  }) async {
    await transaction(() async {
      await deleteBookingsNotOwnedBy(owner);
      if (entries.isNotEmpty) {
        await batch((b) {
          b.insertAllOnConflictUpdate(bookings, entries);
        });
      }
      await deleteBookingsOwnedByExcept(owner, keepIds);
    });
  }

  /// Menyimpan satu pesanan baru secara atomik
  Future<void> insertOrUpdateBooking(BookingsCompanion entry) async {
    await into(bookings).insertOnConflictUpdate(entry);
  }

  /// Memperbarui status pemesanan milik satu akun.
  ///
  /// Pemilik wajib disebut supaya status pesanan akun lain tidak ikut berubah
  /// saat dua akun memakai kode pesanan yang sama.
  Future<void> updateBookingStatus(
    String id,
    String newStatus, {
    required String? userId,
  }) async {
    final query = update(bookings)
      ..where((tbl) => tbl.id.equals(id) & _pemilik(userId, tbl));
    await query.write(BookingsCompanion(status: Value(newStatus)));
  }

  /// Menghapus seluruh data pemesanan lokal.
  ///
  /// Hanya dipakai untuk pembersihan menyeluruh satu perangkat. Jalur logout
  /// biasa memakai [wipeOwnedRows] agar riwayat akun lain tetap utuh.
  Future<int> clearAllBookings() async {
    return delete(bookings).go();
  }

  /// Menghapus baris milik satu akun saja.
  ///
  /// Inilah jalur yang dipakai saat logout: baris milik akun yang keluar
  /// dihapus, sedangkan baris akun lain (dan baris tamu) dibiarkan. `userId ==
  /// null` menghapus baris tamu saja.
  Future<int> wipeOwnedRows(String? userId) async {
    return (delete(bookings)..where((tbl) => _pemilik(userId, tbl))).go();
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

  /// Menghapus satu baris pesanan milik satu akun.
  ///
  /// Dipakai saat server menolak pembuatan pesanan: baris lokal yang tidak
  /// pernah ada di server akan menjadi "pesanan hantu" yang tidak bisa
  /// dibatalkan maupun dibayar.
  Future<int> deleteBookingById(String id, {required String? userId}) async {
    return (delete(bookings)
          ..where((tbl) => tbl.id.equals(id) & _pemilik(userId, tbl)))
        .go();
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
