import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/core/config/app_config_store.dart';
import 'package:mobiljuragan_mobile/core/network/app_config_api_service.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';

import '../support/armada_uji.dart';

/*
 * Perkiraan biaya di aplikasi harus memakai tarif yang sama dengan server.
 *
 * Sebelumnya tarif jasa supir ditulis 150.000 di dalam aplikasi, sehingga layar
 * pelanggan bisa menampilkan angka yang berbeda dari tagihan setelah admin
 * mengubah tarif global.
 */
void main() {
  tearDown(AppConfigStore.reset);

  BookingModel pesananBersupir() => BookingModel(
    id: 'MJ-SUPIR-1',
    vehicle: armadaUji.first,
    startDate: DateTime(2026, 11, 20, 9, 0),
    startTime: '09.00 WIT',
    durationDays: 2,
    withDriver: true,
    pickupLocation: 'Kantor MobilJuragan',
    status: BookingStatus.menungguTarifFinal,
    createdAt: DateTime.now(),
    dailyRate: 400000,
    serviceFee: 0,
  );

  test('subtotal supir mengikuti tarif dari server, bukan angka di aplikasi', () {
    AppConfigStore.terapkan(
      const AppConfig(
        driverDailyRate: 200000,
        serviceOpenMinute: 360,
        serviceCloseMinute: 1320,
      ),
    );

    final booking = pesananBersupir();

    expect(booking.driverSubtotal, equals(400000));
    expect(booking.vehicleSubtotal, equals(800000));
  });

  test('tanpa sopir, tidak ada biaya supir walaupun tarif global berubah', () {
    AppConfigStore.terapkan(
      const AppConfig(
        driverDailyRate: 250000,
        serviceOpenMinute: 360,
        serviceCloseMinute: 1320,
      ),
    );

    final booking = pesananBersupir().copyWith(withDriver: false);

    expect(booking.driverSubtotal, isZero);
  });

  test('nilai cadangan dipakai hanya sebelum server sempat dihubungi', () {
    AppConfigStore.reset();

    expect(
      AppConfigStore.driverDailyRate,
      equals(AppConfig.fallback.driverDailyRate),
    );
  });
}
