import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';

import '../support/armada_uji.dart';

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
    vehicle: armadaUji.first,
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

    testWidgets('Merender tab switcher: QRIS, Transfer Bank, dan Bayar di Tempat', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.text('QRIS'), findsOneWidget);
      expect(find.text('Transfer Bank'), findsOneWidget);
      expect(find.text('Bayar di Tempat'), findsOneWidget);
    });

    testWidgets('Merender kode QR pada tab QRIS tanpa jargon teknis', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.textContaining('Pindai dengan m-banking'), findsOneWidget);
      // String payload QRIS adalah urusan teknis, bukan untuk penyewa.
      expect(find.text('Salin String QRIS'), findsNothing);
      expect(find.text('QRIS Dinamis'), findsNothing);
    });

    testWidgets('Nominal tagihan hanya muncul sekali di kartu Total Tagihan', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      expect(find.text('TOTAL TAGIHAN'), findsOneWidget);
      // Satu sumber angka: tidak ada rincian duplikat di bawah.
      expect(find.textContaining('Tarif Sewa Pokok'), findsNothing);
      expect(find.textContaining('Total Transfer Pas'), findsNothing);
      expect(find.text('Kode Unik Verifikasi'), findsNothing);
      expect(find.textContaining('3 digit'), findsNothing);

      // Salin nominal lewat ikon di kartu tagihan.
      await tester.ensureVisible(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('disalin'), findsOneWidget);
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

    testWidgets('Tidak ada tombol cek status otomatis maupun tombol simulasi', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(booking: testBooking));
      await tester.pump();

      /* Pemeriksaan status manual sudah tidak ditonjolkan: pelanggan tidak
         seharusnya disuruh "mengecek" pembayaran yang belum ia kirim buktinya. */
      expect(find.textContaining('Cek Status Pembayaran'), findsNothing);
      expect(find.text('Simulasikan Pembayaran Berhasil (Demo Sandbox)'), findsNothing);

      // Yang tersedia hanya ajakan mengunggah bukti.
      expect(find.text('Sudah melakukan pembayaran?'), findsOneWidget);
      expect(find.text('Kirim Bukti Pembayaran'), findsOneWidget);
      expect(find.text('Unggah bukti pembayaran'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
