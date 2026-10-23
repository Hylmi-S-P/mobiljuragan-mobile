import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';

void main() {
  Widget createTestWidget({required BookingModel booking}) {
    return ChangeNotifierProvider<BookingController>(
      create: (_) => BookingController(),
      child: MaterialApp(
        home: OrderStatusScreen(booking: booking),
      ),
    );
  }

  final completedBooking = BookingModel(
    id: 'MJ-TEST-COMPLETED',
    vehicle: VehicleModel.sampleVehicles.first,
    startDate: DateTime(2026, 10, 20),
    startTime: '09.00 WIT',
    durationDays: 3,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.selesai,
    createdAt: DateTime(2026, 10, 19),
    dailyRate: 450000,
    isFinalTariffConfirmed: true,
  );

  final inProgressBooking = BookingModel(
    id: 'MJ-TEST-INPROGRESS',
    vehicle: VehicleModel.sampleVehicles.first,
    startDate: DateTime(2026, 10, 20),
    startTime: '09.00 WIT',
    durationDays: 3,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.mobilSiapDigunakan,
    createdAt: DateTime(2026, 10, 19),
    dailyRate: 450000,
    isFinalTariffConfirmed: true,
  );

  group('OrderStatusScreen Completion UI Tests', () {
    testWidgets('Merender banner Sewa Selesai dan tombol Kembali ke Beranda saat booking selesai', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: completedBooking));
      await tester.pumpAndSettle();

      // Banner Penyewaan Selesai
      expect(find.text('Penyewaan Selesai'), findsOneWidget);
      expect(find.text('TUNTAS'), findsOneWidget);

      // Badge SELESAI pada tahapan ke-5
      expect(find.text('SELESAI'), findsAtLeastNWidgets(1));

      // Tombol aksi utama Kembali ke Beranda
      expect(find.text('Kembali ke Beranda'), findsOneWidget);

      // Tidak menampilkan tombol batalkan
      expect(find.text('Batalkan Pesanan Ini'), findsNothing);
      expect(find.text('Ajukan Pembatalan & Refund'), findsNothing);
    });

    testWidgets('Merender status Sewa Berjalan dan aksi koordinasi saat masa sewa aktif', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: inProgressBooking));
      await tester.pumpAndSettle();

      // Status sewa aktif
      expect(find.text('Sewa Berjalan'), findsAtLeastNWidgets(1));
      expect(find.text('Penyewaan Selesai'), findsNothing);

      // Tombol koordinasi tim lapangan
      expect(find.text('Koordinasi Penjemputan via Chat CS'), findsOneWidget);
    });
  });
}
