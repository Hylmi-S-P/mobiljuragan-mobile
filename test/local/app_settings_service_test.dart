import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/preferences/app_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppSettingsService settingsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settingsService = await AppSettingsService.create();
  });

  group('AppSettingsService (SharedPreferences) Tests', () {
    test('Kategori filter default adalah "Semua" dan dapat diperbarui', () async {
      expect(settingsService.getSelectedCategory(), equals('Semua'));

      await settingsService.setSelectedCategory('SUV');
      expect(settingsService.getSelectedCategory(), equals('SUV'));
    });

    test('Riwayat pencarian menyimpan urutan terbaru dan membatasi ukuran riwayat', () async {
      expect(settingsService.getSearchHistory(), isEmpty);

      await settingsService.addSearchQuery('Avanza');
      await settingsService.addSearchQuery('Fortuner');
      await settingsService.addSearchQuery('Hilux');

      final history = settingsService.getSearchHistory();
      expect(history.length, equals(3));
      expect(history.first, equals('Hilux')); // Paling akhir dicari berada di paling depan

      // Tambahkan kembali Avanza: harus naik ke urutan paling depan
      await settingsService.addSearchQuery('Avanza');
      final updatedHistory = settingsService.getSearchHistory();
      expect(updatedHistory.first, equals('Avanza'));
      expect(updatedHistory.length, equals(3));
    });

    test('Pengaturan preferensi notifikasi dan waktu sinkronisasi', () async {
      expect(settingsService.getNotificationsEnabled(), isTrue);

      await settingsService.setNotificationsEnabled(false);
      expect(settingsService.getNotificationsEnabled(), isFalse);

      final nowMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
      await settingsService.setLastSyncTime(nowMillis);
      expect(settingsService.getLastSyncTime(), equals(nowMillis));
    });
  });
}
