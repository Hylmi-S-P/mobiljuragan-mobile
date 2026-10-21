import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';

void main() {
  Widget createTestWidget({required BookingModel booking}) {
    return ChangeNotifierProvider<BookingController>(
      create: (_) => BookingController(),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: OnlinePaymentSheetModal(
                booking: booking,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final testBooking = BookingModel(
    id: 'MBJ-TEST-2026',
    vehicle: VehicleModel.sampleVehicles.first,
    startDate: DateTime(2026, 10, 22),
    startTime: '09.00 WIT',
    durationDays: 2,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.menungguPembayaran,
    createdAt: DateTime(2026, 10, 21),
    dailyRate: 400000,
    isFinalTariffConfirmed: true,
  );

  group('OnlinePaymentSheetModal UI & Interaction Tests', () {
    testWidgets('Merender judul pemesanan, ID reservasi, dan countdown timer aktif', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.text('Pembayaran Pemesanan'), findsOneWidget);
      expect(find.text('Reservasi #MBJ-TEST-2026'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('Merender tab switcher: QRIS Dinamis, Transfer Bank, dan Bayar di Tempat', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.text('QRIS Dinamis'), findsOneWidget);
      expect(find.text('Transfer Bank'), findsOneWidget);
      expect(find.text('Bayar di Tempat'), findsOneWidget);
    });

    testWidgets('Merender komponen QrImageView pada tab QRIS Dinamis', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('STANDAR PEMBAYARAN NASIONAL'), findsOneWidget);
      expect(find.text('Salin String QRIS'), findsOneWidget);
    });

    testWidgets('Merender rincian breakdown tarif sewa, kode unik, dan tombol salin nominal pas', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.text('Tarif Sewa Pokok'), findsOneWidget);
      expect(find.text('Kode Unik Verifikasi'), findsOneWidget);
      expect(find.text('Total Transfer Pas:'), findsOneWidget);
      expect(find.text('Salin Nominal Pas'), findsOneWidget);

      // Ketuk tombol Salin Nominal Pas
      await tester.ensureVisible(find.text('Salin Nominal Pas'));
      await tester.tap(find.text('Salin Nominal Pas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Nominal pas Rp'), findsOneWidget);
    });

    testWidgets('Beralih ke tab Transfer Bank menampilkan opsi bank resmi dan tombol salin rekening', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      // Pindah ke tab Transfer Bank
      await tester.tap(find.text('Transfer Bank'));
      await tester.pump();

      expect(find.text('Pilih Bank Tujuan Transfer'), findsOneWidget);
      expect(find.text('BRI'), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('Mandiri'), findsOneWidget);
      expect(find.text('BNI'), findsOneWidget);
      expect(find.text('Salin'), findsOneWidget);
      expect(find.text('Atas Nama: CV Mobil Juragan Express Transport'), findsOneWidget);

      // Ketuk tombol Salin rekening
      await tester.tap(find.text('Salin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Nomor rekening'), findsOneWidget);
    });

    testWidgets('Beralih ke tab Bayar di Tempat menampilkan panduan serah terima COD', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      // Pindah ke tab Bayar di Tempat
      await tester.tap(find.text('Bayar di Tempat'));
      await tester.pump();

      expect(find.text('Bayar Tunai di Tempat (COD)'), findsOneWidget);
      expect(find.text('Nominal Pelunasan Tunai'), findsOneWidget);
      expect(find.text('Pilih Bayar di Tempat (COD)'), findsOneWidget);
    });

    testWidgets('Tombol Cek Status Pembayaran dan Simulasi Pembayaran Berhasil dapat ditekan', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.text('Cek Status Pembayaran (Otomatis)'), findsOneWidget);
      expect(find.text('Simulasikan Pembayaran Berhasil (Demo Sandbox)'), findsOneWidget);

      // Ketuk tombol Cek Status Pembayaran
      await tester.ensureVisible(find.text('Cek Status Pembayaran (Otomatis)'));
      await tester.tap(find.text('Cek Status Pembayaran (Otomatis)'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Pastikan ada respon interaktif (tidak crash)
      expect(tester.takeException(), isNull);
    });
  });
}
