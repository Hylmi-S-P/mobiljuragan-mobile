import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;
import 'tables/vehicles_table.dart';
import 'tables/favorites_table.dart';
import 'tables/bookings_table.dart';
import 'daos/vehicle_dao.dart';
import 'daos/booking_dao.dart';

part 'app_database.g.dart';

/// Database SQLite lokal utama MobilJuragan menggunakan Drift
///
/// Menyediakan penyimpanan terstruktur yang bersifat type-safe, offline-first,
/// dan reaktif untuk seluruh data aplikasi.
@DriftDatabase(
  tables: [Vehicles, Favorites, Bookings],
  daos: [VehicleDao, BookingDao],
)
class AppDatabase extends _$AppDatabase {
  /// Konstruktor standar untuk aplikasi (membuka database file SQLite pada perangkat)
  AppDatabase() : super(_openConnection());

  /// Konstruktor khusus untuk pengujian otomatis (in-memory SQLite executor)
  AppDatabase.forTesting(super.e);

  /// Versi skema saat ini.
  ///
  /// Riwayat: 7 menambahkan `bookings.finalAmount`. Versi 8 memindahkan status
  /// favorit dari kolom global `vehicles.isFavorite` ke tabel `Favorites` yang
  /// terikat pemilik.
  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(bookings, bookings.adminAdjustmentsJson);
          }
          if (from < 3) {
            await m.addColumn(bookings, bookings.driverJson);
          }
          if (from < 4) {
            await m.addColumn(bookings, bookings.quotedAmount);
          }
          if (from < 5) {
            await m.addColumn(bookings, bookings.userId);
          }
          if (from < 6) {
            await m.addColumn(bookings, bookings.cancellationJson);
          }
          if (from < 7) {
            await m.addColumn(bookings, bookings.finalAmount);
          }
          if (from < 8) {
            /*
             * Memindahkan penanda favorit dari kolom global
             * `vehicles.is_favorite` ke tabel Favorites.
             *
             * Kolom lama tidak punya pemilik, jadi status favorit yang sudah
             * ada disalin sebagai milik `null` (mode tamu). Dengan begitu
             * pilihan pengguna tidak hilang, tetapi juga tidak diklaim oleh
             * akun mana pun yang kebetulan sedang aktif saat pemutakhiran
             * berjalan.
             */
            await m.createTable(favorites);
            final lama = await customSelect(
              'SELECT id FROM vehicles WHERE is_favorite = 1',
            ).get();
            final sekarang = DateTime.now().toUtc().millisecondsSinceEpoch;
            for (final baris in lama) {
              await customStatement(
                'INSERT OR IGNORE INTO favorites '
                '(user_id, vehicle_id, created_at) VALUES (NULL, ?, ?)',
                [baris.read<String>('id'), sekarang],
              );
            }
          }
        },
        beforeOpen: (details) async {
          /*
           * Penjagaan versi skema di sisi perangkat.
           *
           * Kalau pengguna pernah memasang versi aplikasi yang lebih baru lalu
           * turun versi, `user_version` di file SQLite bisa lebih tinggi
           * daripada [schemaVersion]. Drift tidak punya hook onDowngrade, jadi
           * kondisi itu diperiksa di sini agar tidak berujung pada query yang
           * gagal karena kolom atau tabel yang tidak dikenal.
           */
          if (details.versionBefore != null &&
              details.versionBefore! > details.versionNow) {
            debugPrint(
              'Skema lokal (${details.versionBefore}) lebih baru daripada '
              'aplikasi (${details.versionNow}).',
            );
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'mobiljuragan_local_db',
      native: const DriftNativeOptions(setup: _siapkanKoneksi),
    );
  }

  /// Menyiapkan PRAGMA yang dibutuhkan setiap koneksi database.
  ///
  /// - `journal_mode = WAL` membuat pembacaan tidak terblokir saat penulisan
  ///   berjalan, sehingga stream UI tetap hidup ketika sinkronisasi menulis.
  /// - `busy_timeout = 5000` mencegah `database is locked` langsung muncul saat
  ///   dua penulisan bertemu; SQLite menunggu hingga 5 detik sebelum menyerah.
  /// - `foreign_keys = ON` wajib karena SQLite mematikannya secara bawaan.
  ///
  /// Fungsi ini dikirim ke isolate pembuka koneksi, jadi tidak boleh menangkap
  /// variabel tertutup yang tidak bisa dikirim lintas isolate.
  static void _siapkanKoneksi(CommonDatabase db) {
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA busy_timeout = 5000;');
    db.execute('PRAGMA foreign_keys = ON;');
  }
}
