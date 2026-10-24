import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/vehicles_table.dart';
import 'tables/bookings_table.dart';
import 'daos/vehicle_dao.dart';
import 'daos/booking_dao.dart';

part 'app_database.g.dart';

/// Database SQLite lokal utama MobilJuragan menggunakan Drift
///
/// Menyediakan penyimpanan terstruktur yang bersifat type-safe, offline-first,
/// dan reaktif untuk seluruh data aplikasi.
@DriftDatabase(
  tables: [Vehicles, Bookings],
  daos: [VehicleDao, BookingDao],
)
class AppDatabase extends _$AppDatabase {
  /// Konstruktor standar untuk aplikasi (membuka database file SQLite pada perangkat)
  AppDatabase() : super(_openConnection());

  /// Konstruktor khusus untuk pengujian otomatis (in-memory SQLite executor)
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

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
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mobiljuragan_local_db');
  }
}
