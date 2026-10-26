import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/vehicle_controller.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/vehicle_detail_screen.dart';
import 'package:mobiljuragan_mobile/widgets/vehicle_card_item.dart';
import 'package:provider/provider.dart';

void main() {
  group('VehicleModel Availability Tests', () {
    test('isAvailable dan isBooked mengembalikan nilai yang sesuai dengan availabilityTag', () {
      final availableVehicle = VehicleModel(
        id: 'v-avail',
        name: 'AVANZA G PUTIH',
        plateNumber: 'PA1001',
        category: 'MPV',
        seatCapacity: '7 Penumpang',
        transmission: 'Manual',
        bodyType: 'MPV Keluarga',
        condition: 'Siap Pakai',
        availabilityTag: 'Tersedia • Lepas Kunci',
        pricePerDay: 400000,
        imageUrl: 'assets/images/avanza_card.png',
      );

      expect(availableVehicle.isAvailable, isTrue);
      expect(availableVehicle.isBooked, isFalse);

      final bookedVehicle = VehicleModel(
        id: 'v-booked',
        name: 'XPANDER EXCEED HITAM',
        plateNumber: 'PA1002',
        category: 'MPV',
        seatCapacity: '7 Penumpang',
        transmission: 'Manual',
        bodyType: 'MPV Keluarga',
        condition: 'Sedang Beroperasi',
        availabilityTag: 'Sedang Disewa',
        pricePerDay: 550000,
        imageUrl: 'assets/images/innova_card.png',
      );

      expect(bookedVehicle.isAvailable, isFalse);
      expect(bookedVehicle.isBooked, isTrue);
    });

    test('VehicleModel.fromJson mendeteksi bookings aktif dan operationalStatus BOOKED', () {
      final jsonWithActiveBooking = {
        'id': 'v-1',
        'name': 'INNOVA REBORN',
        'licensePlate': 'PA1504G',
        'category': 'MPV',
        'operationalStatus': 'AVAILABLE',
        'bookings': [
          {'id': 'b-101', 'bookingCode': 'BK-101', 'status': 'CONFIRMED'}
        ],
      };

      final vehicleFromBooking = VehicleModel.fromJson(jsonWithActiveBooking);
      expect(vehicleFromBooking.isAvailable, isFalse);
      expect(vehicleFromBooking.isBooked, isTrue);
      expect(vehicleFromBooking.availabilityTag, equals('Sedang Disewa'));

      final jsonWithBookedStatus = {
        'id': 'v-2',
        'name': 'FORTUNER VRZ',
        'licensePlate': 'PA1234F',
        'category': 'SUV',
        'operationalStatus': 'BOOKED',
      };

      final vehicleFromStatus = VehicleModel.fromJson(jsonWithBookedStatus);
      expect(vehicleFromStatus.isAvailable, isFalse);
      expect(vehicleFromStatus.isBooked, isTrue);
      expect(vehicleFromStatus.availabilityTag, equals('Sedang Disewa'));

      final jsonAvailable = {
        'id': 'v-3',
        'name': 'AVANZA VELOZ',
        'licensePlate': 'PA5678V',
        'category': 'MPV',
        'operationalStatus': 'AVAILABLE',
        'bookings': [],
      };

      final vehicleAvailable = VehicleModel.fromJson(jsonAvailable);
      expect(vehicleAvailable.isAvailable, isTrue);
      expect(vehicleAvailable.isBooked, isFalse);
      expect(vehicleAvailable.availabilityTag, contains('Tersedia'));
    });
  });

  group('VehicleCardItem Widget Tests', () {
    testWidgets('Merender badge Tersedia untuk unit tersedia dan Sedang Disewa untuk unit terisi', (tester) async {
      final availableVehicle = VehicleModel(
        id: 'v-avail',
        name: 'AVANZA G PUTIH',
        plateNumber: 'PA1001',
        category: 'MPV',
        seatCapacity: '7 Penumpang',
        transmission: 'Manual',
        bodyType: 'MPV Keluarga',
        condition: 'Siap Pakai',
        availabilityTag: 'Tersedia',
        pricePerDay: 400000,
        imageUrl: 'assets/images/avanza_card.png',
      );

      final bookedVehicle = VehicleModel(
        id: 'v-booked',
        name: 'XPANDER EXCEED HITAM',
        plateNumber: 'PA1002',
        category: 'MPV',
        seatCapacity: '7 Penumpang',
        transmission: 'Manual',
        bodyType: 'MPV Keluarga',
        condition: 'Sedang Beroperasi',
        availabilityTag: 'Sedang Disewa',
        pricePerDay: 550000,
        imageUrl: 'assets/images/innova_card.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VehicleCardItem(
                  vehicle: availableVehicle,
                  isSelected: false,
                  onTap: () {},
                ),
                VehicleCardItem(
                  vehicle: bookedVehicle,
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tersedia'), findsOneWidget);
      expect(find.text('Sedang Disewa'), findsOneWidget);
    });
  });

  group('VehicleDetailScreen Widget Tests', () {
    testWidgets('Unit Sedang Disewa menampilkan banner peringatan dan tombol lanjut terkunci abu-abu', (tester) async {
      final bookedVehicle = VehicleModel(
        id: 'xpander-exceed-hitam-ps1691b',
        name: 'XPANDER EXCEED HITAM',
        plateNumber: 'PS1691B',
        category: 'MPV',
        seatCapacity: '7 Penumpang',
        transmission: 'Manual',
        bodyType: 'MPV Keluarga',
        condition: 'Sedang Beroperasi',
        availabilityTag: 'Sedang Disewa',
        pricePerDay: 550000,
        imageUrl: 'assets/images/innova_card.png',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
            ChangeNotifierProvider<VehicleController>(create: (_) => VehicleController()),
          ],
          child: MaterialApp(
            home: VehicleDetailScreen(vehicle: bookedVehicle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge status pada header dan kartu spesifikasi 'Status Unit'
      expect(find.text('Sedang Disewa'), findsNWidgets(2));
      expect(find.text('Armada Sedang Disewa'), findsOneWidget); // Judul banner
      expect(
        find.textContaining('Unit ini telah dipesan dan dibayar oleh pelanggan lain'),
        findsOneWidget,
      );

      // Tombol CTA bawah dalam kondisi terkunci
      final ctaFinder = find.widgetWithText(ElevatedButton, 'Armada Sedang Tidak Tersedia');
      expect(ctaFinder, findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(ctaFinder);
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('Unit Tersedia menampilkan tombol Lanjut ke Opsi Rental yang aktif', (tester) async {
      final availableVehicle = VehicleModel(
        id: 'avanza-g-putih-ps1692b',
        name: 'AVANZA G PUTIH',
        plateNumber: 'PS1692B',
        category: 'MPV',
        seatCapacity: '7 Penumpang',
        transmission: 'Manual',
        bodyType: 'MPV Keluarga',
        condition: 'Siap Pakai',
        availabilityTag: 'Tersedia • Lepas Kunci',
        pricePerDay: 400000,
        imageUrl: 'assets/images/avanza_card.png',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
            ChangeNotifierProvider<VehicleController>(create: (_) => VehicleController()),
          ],
          child: MaterialApp(
            home: VehicleDetailScreen(vehicle: availableVehicle),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Banner peringatan tidak boleh muncul
      expect(
        find.textContaining('Unit ini telah dipesan dan dibayar oleh pelanggan lain'),
        findsNothing,
      );

      // Tombol CTA aktif
      final ctaFinder = find.widgetWithText(ElevatedButton, 'Lanjut ke Opsi Rental');
      expect(ctaFinder, findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(ctaFinder);
      expect(elevatedButton.onPressed, isNotNull);
    });
  });
}
