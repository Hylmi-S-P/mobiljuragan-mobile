import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/local/preferences/app_settings_service.dart';
import 'package:mobiljuragan_mobile/data/repositories/vehicle_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/armada_uji.dart';

/*
 * Catatan perilaku: repositori tidak lagi menyemai armada contoh ke SQLite.
 *
 * Dulu ada metode `ensureSeeded()` yang menyalin sembilan unit contoh saat
 * basis data lokal kosong. Itu membuat katalog selalu tampak berisi walaupun
 * backend belum punya satu unit pun. Pengujian di bawah menjaga agar perilaku
 * lama tidak kembali.
 */
void main() {
  late AppDatabase database;
  late AppSettingsService settingsService;
  late VehicleRepository vehicleRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settingsService = await AppSettingsService.create();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    vehicleRepository = VehicleRepository(
      vehicleDao: database.vehicleDao,
      settingsService: settingsService,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('VehicleRepository (Offline-First) Tests', () {
    test('basis data lokal tetap kosong sebelum ada sinkronisasi', () async {
      expect(await database.vehicleDao.countVehicles(), equals(0));

      // Tidak ada pemanggilan penyemaian: katalog dibiarkan kosong.
      final jumlah = await database.vehicleDao.countVehicles();
      expect(jumlah, equals(0));
      expect(settingsService.getLastSyncTime(), isNull);
    });

    test('armada yang disimpan lewat DAO mengalir ke stream', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await database.vehicleDao.upsertVehiclesBatch(
        armadaUji.map((v) => v.toCompanion(lastFetchedMillis: now)).toList(),
      );

      final vehicles = await vehicleRepository.watchVehicles().first;

      expect(vehicles.length, equals(armadaUji.length));
      expect(vehicles.any((v) => v.name == armadaUji.first.name), isTrue);
    });

    test('toggleFavorite mengubah status favorit dan dapat didengar melalui stream', () async {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await database.vehicleDao.upsertVehiclesBatch(
        armadaUji.map((v) => v.toCompanion(lastFetchedMillis: now)).toList(),
      );

      final targetId = armadaUji.first.id;
      final initialVehicle = await vehicleRepository.getVehicleById(targetId);
      expect(initialVehicle?.isFavorite, isFalse);

      final newStatus = await vehicleRepository.toggleFavorite(targetId);
      expect(newStatus, isTrue);

      final updatedVehicle = await vehicleRepository.getVehicleById(targetId);
      expect(updatedVehicle?.isFavorite, isTrue);
    });
  });
}
