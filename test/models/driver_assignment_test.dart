import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';

void main() {
  final sampleVehicle = VehicleModel.sampleVehicles.first;

  group('DriverAssignment & BookingModel Real Data Tests', () {
    test('BookingModel.fromJson membaca data supir riil dari backend tanpa hardcode', () {
      final json = {
        'id': 'MJ-20261026-YOH1',
        'startDateTime': '2026-10-27T08:00:00.000Z',
        'endDateTime': '2026-10-29T08:00:00.000Z',
        'rentalType': 'WITH_DRIVER',
        'status': 'CONFIRMED',
        'driver': {
          'id': 'drv-uuid-123',
          'externalId': 'yohanes-mahuze',
          'fullName': 'Yohanes Mahuze',
          'phoneNumber': '0812-3456-7890',
          'routeScope': 'LUAR_KOTA',
          'readiness': 'SEDANG_TUGAS',
        },
      };

      final model = BookingModel.fromJson(json, sampleVehicle);

      expect(model.withDriver, isTrue);
      expect(model.assignedDriver, isNotNull);
      expect(model.assignedDriver!.driverName, 'Yohanes Mahuze');
      expect(model.assignedDriver!.staffId, 'yohanes-mahuze');
      expect(model.assignedDriver!.phoneNumber, '0812-3456-7890');
      expect(model.assignedDriver!.operationalRole, 'Staf Pengemudi Rute Luar Kota Merauke');
    });

    test('BookingModel.fromJson tidak mengisi fallback hardcode saat supir belum dialokasikan', () {
      final json = {
        'id': 'MJ-20261026-PENDING',
        'startDateTime': '2026-10-27T08:00:00.000Z',
        'endDateTime': '2026-10-29T08:00:00.000Z',
        'rentalType': 'WITH_DRIVER',
        'status': 'CONFIRMED',
        'driver': null,
      };

      final model = BookingModel.fromJson(json, sampleVehicle);

      expect(model.withDriver, isTrue);
      // Tidak boleh ada fallback 'Staf Sopir Ditugaskan' atau nomor hardcode
      expect(model.assignedDriver, isNull);
    });
  });

  group('OrderStatusScreen Real Driver UI Tests', () {
    Widget buildScreen(BookingModel booking) {
      return ChangeNotifierProvider<BookingController>(
        create: (_) => BookingController(),
        child: MaterialApp(
          home: OrderStatusScreen(booking: booking),
        ),
      );
    }

    testWidgets('Merender nama supir riil (Yohanes Mahuze) dan badge Sopir Resmi saat supir telah dialokasikan', (tester) async {
      final bookingWithDriver = BookingModel(
        id: 'MJ-TEST-YOHANES',
        vehicle: sampleVehicle,
        startDate: DateTime(2026, 10, 27),
        startTime: '08.00 WIT',
        durationDays: 2,
        withDriver: true,
        pickupLocation: 'Bandara Mopah Merauke',
        status: BookingStatus.menungguPembayaran,
        createdAt: DateTime(2026, 10, 26),
        dailyRate: 500000,
        isFinalTariffConfirmed: true,
        assignedDriver: const DriverAssignment(
          driverName: 'Yohanes Mahuze',
          staffId: 'yohanes-mahuze',
          phoneNumber: '0812-3456-7890',
          operationalRole: 'Staf Pengemudi Rute Luar Kota Merauke',
        ),
      );

      await tester.pumpWidget(buildScreen(bookingWithDriver));
      await tester.pumpAndSettle();

      expect(find.text('Pengemudi Anda'), findsOneWidget);
      expect(find.text('Yohanes Mahuze'), findsOneWidget);
      expect(find.text('Sopir Resmi'), findsOneWidget);
      expect(find.text('Staf Pengemudi Rute Luar Kota Merauke'), findsOneWidget);
      expect(find.textContaining('0812-3456-7890'), findsOneWidget);
    });

    testWidgets('Merender status transparan Menunggu Alokasi saat supir belum dialokasikan admin', (tester) async {
      final bookingPendingDriver = BookingModel(
        id: 'MJ-TEST-PENDING-DRIVER',
        vehicle: sampleVehicle,
        startDate: DateTime(2026, 10, 27),
        startTime: '08.00 WIT',
        durationDays: 2,
        withDriver: true,
        pickupLocation: 'Bandara Mopah Merauke',
        status: BookingStatus.menungguPembayaran,
        createdAt: DateTime(2026, 10, 26),
        dailyRate: 500000,
        isFinalTariffConfirmed: true,
        assignedDriver: null,
      );

      await tester.pumpWidget(buildScreen(bookingPendingDriver));
      await tester.pumpAndSettle();

      expect(find.text('Pengemudi Anda'), findsOneWidget);
      expect(find.text('Staf Sopir Sedang Disiapkan'), findsOneWidget);
      expect(find.text('Menunggu Alokasi'), findsOneWidget);
      expect(find.text('Akan dialokasikan oleh tim admin sebelum jadwal sewa'), findsOneWidget);
      expect(find.text('Staf Sopir Ditugaskan'), findsNothing);
    });
  });
}
