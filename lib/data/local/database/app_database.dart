import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
  /// terikat pemilik. Versi 9 menambahkan indeks komposit & kategori.
  @override
  int get schemaVersion => 9;

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
          if (from < 9) {
            await m.createIndex(idxVehiclesCategory);
            await m.createIndex(idxFavoritesUserVehicle);
            await m.createIndex(idxBookingsUserCreated);
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
            if (kDebugMode) {
              debugPrint(
                'Skema lokal (${details.versionBefore}) lebih baru daripada '
                'aplikasi (${details.versionNow}). Versi aplikasi yang lebih '
                'baru pernah terpasang di perangkat ini; jalankan ulang '
                'pemeriksaan data setelah pembaruan aplikasi.',
              );
            }
          }
        },
      );

  static QueryExecutor _openConnection() {
    /* Pembukaan dibungkus LazyDatabase supaya berkas yang sudah rusak bisa
       dibuang sebelum SQLite mencoba membacanya. Berkas korup (mis. terpotong
       karena perangkat mati saat menulis) tidak bisa dipulihkan oleh Drift dan
       dulu membuat aplikasi gagal total saat dibuka; satu-satunya jalan keluar
       adalah menghapus berkasnya dan membiarkan skema dibuat ulang. */
    return LazyDatabase(() async {
      await _pulihkanBerkasKorup();
      return driftDatabase(
        name: _namaDatabase,
        native: const DriftNativeOptions(setup: _siapkanKoneksi),
      );
    });
  }

  /// Nama berkas database lokal (tanpa ekstensi).
  static const String _namaDatabase = 'mobiljuragan_local_db';

  /// Header wajib berkas SQLite: "SQLite format 3" diikuti satu byte nol.
  static final Uint8List _headerSqlite = Uint8List.fromList(
    'SQLite format 3\u0000'.codeUnits,
  );

  /// Membuang berkas database yang jelas bukan database SQLite.
  ///
  /// Pemeriksaan dilakukan pada 16 byte pertama berkas karena SQLite selalu
  /// menulis header itu. Berkas kosong, terpotong, atau berisi data lain
  /// dianggap rusak. Berkas yang tidak ada dilewati, sehingga pembukaan pertama
  /// di perangkat baru tidak melakukan apa pun.
  static Future<void> _pulihkanBerkasKorup() async {
    try {
      final folder = await getApplicationDocumentsDirectory();
      final berkas = File('${folder.path}/$_namaDatabase.sqlite');
      if (!await berkas.exists()) return;

      final panjang = await berkas.length();
      var sehat = false;
      if (panjang >= _headerSqlite.length) {
        final pembuka = await berkas.openRead(0, _headerSqlite.length).first;
        sehat = pembuka.length == _headerSqlite.length &&
            _isiSama(pembuka, _headerSqlite);
      }

      if (sehat) return;

      /* Ketiga pendamping dibuang bersama berkas utama. Kalau `-wal` tertinggal,
         SQLite akan mencoba memutarnya ke berkas baru dan langsung menolak. */
      for (final akhiran in const ['', '-wal', '-shm']) {
        final bagian = File('${berkas.path}$akhiran');
        if (await bagian.exists()) {
          try {
            await bagian.delete();
          } catch (_) {
            // Berkas terkunci; percobaan berikutnya akan mengulang pemeriksaan.
          }
        }
      }
      if (kDebugMode) {
        debugPrint(
          'Berkas database lokal tidak terbaca sebagai SQLite dan telah dihapus '
          'agar skema dibuat ulang.',
        );
      }
    } catch (_) {
      /* Pemeriksaan ini bersifat pencegahan. Kegagalan membaca folder (mis.
         plugin path belum siap) tidak boleh menghalangi pembukaan database. */
    }
  }

  /// Membandingkan dua deret byte tanpa bergantung pada `package:collection`.
  static bool _isiSama(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('PRAGMA temp_store = MEMORY;');
    db.execute('PRAGMA busy_timeout = 5000;');
    db.execute('PRAGMA foreign_keys = ON;');
  }
}
