import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/services/notification_service.dart';

/* Di lingkungan uji tidak ada channel platform untuk plugin notifikasi, jadi
   setiap panggilan plugin melempar MissingPluginException. Test ini mengunci
   janji yang penting: kegagalan notifikasi TIDAK boleh menjatuhkan aplikasi. */
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService tahan kegagalan plugin', () {
    test('init tidak melempar saat plugin tidak tersedia', () async {
      await expectLater(NotificationService().init(), completes);
    });

    test('showTariffReadyNotification tidak melempar tanpa plugin', () async {
      await expectLater(
        NotificationService().showTariffReadyNotification(
          bookingId: 'MJ-20261114-UJI1',
          vehicleName: 'Toyota Avanza Uji',
          totalCost: 900000,
        ),
        completes,
      );
    });

    test('showBookingRejectedNotification tidak melempar tanpa plugin', () async {
      await expectLater(
        NotificationService().showBookingRejectedNotification(
          bookingId: 'MJ-20261114-UJI2',
          vehicleName: 'Toyota Avanza Uji',
          reason: 'Dokumen tidak sesuai',
        ),
        completes,
      );
    });

    test('showRentalCompletedNotification tidak melempar tanpa plugin', () async {
      await expectLater(
        NotificationService().showRentalCompletedNotification(
          bookingId: 'MJ-20261114-UJI3',
          vehicleName: 'Toyota Avanza Uji',
        ),
        completes,
      );
    });
  });
}
