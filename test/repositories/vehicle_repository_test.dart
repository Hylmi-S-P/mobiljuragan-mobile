import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/local/preferences/app_settings_service.dart';
import 'package:mobiljuragan_mobile/data/repositories/vehicle_repository.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    test('ensureSeeded mengisi database lokal dengan armada awal jika kosong', () async {
      expect(await database.vehicleDao.countVehicles(), equals(0));

      await vehicleRepository.ensureSeeded();

      final count = await database.vehicleDao.countVehicles();
      expect(count, equals(VehicleModel.sampleVehicles.length));

      // Pastikan lastSyncTime tercatat di SharedPreferences
      expect(settingsService.getLastSyncTime(), isNotNull);
    });

    test('watchVehicles mengalirkan stream armada secara offline-first', () async {
      await vehicleRepository.ensureSeeded();

      final stream = vehicleRepository.watchVehicles();
      final vehicles = await stream.first;

      expect(vehicles.isNotEmpty, isTrue);
      expect(vehicles.any((v) => v.name.contains('AVANZA')), isTrue);
    });

    test('toggleFavorite mengubah status favorit dan dapat didengar melalui stream', () async {
      await vehicleRepository.ensureSeeded();

      final targetId = VehicleModel.sampleVehicles.first.id;
      final initialVehicle = await vehicleRepository.getVehicleById(targetId);
      expect(initialVehicle?.isFavorite, isFalse);

      final newStatus = await vehicleRepository.toggleFavorite(targetId);
      expect(newStatus, isTrue);

      final updatedVehicle = await vehicleRepository.getVehicleById(targetId);
      expect(updatedVehicle?.isFavorite, isTrue);
    });
  });
}
