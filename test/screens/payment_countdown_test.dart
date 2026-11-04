import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';

import '../support/armada_uji.dart';

/// Hitungan mundur pembayaran harus bersumber dari server.
///
/// Regresi yang dicegah: dulu sisa waktu dikarang di klien
/// (`DateTime.now() + 12 jam`, padahal server menetapkan 2 jam), sehingga angka
/// yang dilihat pelanggan tidak pernah sesuai tagihan dan ikut ter-reset setiap
/// widget dibangun ulang.
void main() {
  final testBooking = BookingModel(
    id: 'MBJ-COUNTDOWN-2026',
    vehicle: armadaUji.first,
    startDate: DateTime(2026, 11, 2),
    startTime: '09.00 WIT',
    durationDays: 2,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.menungguPembayaran,
    createdAt: DateTime(2026, 11, 1),
    dailyRate: 400000,
    isFinalTariffConfirmed: true,
  );

  Widget createTestWidget() {
    return ChangeNotifierProvider<BookingController>(
      create: (_) => BookingController(),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: OnlinePaymentSheetModal(booking: testBooking),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tanpa batas waktu dari server, tidak menampilkan hitungan karangan', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text('Menunggu tagihan'), findsOneWidget);

    // Tidak boleh ada angka berformat jam:menit:detik yang ditebak klien.
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}')), findsNothing);
    expect(find.text('Waktu Habis'), findsNothing);
  });

  testWidgets('ticker berjalan tanpa error dan berhenti saat widget dibuang', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    // Beberapa detik berjalan: label tidak berubah karena belum ada tagihan,
    // tetapi ticker tetap hidup tanpa melempar galat.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Menunggu tagihan'), findsOneWidget);

    // Membuang widget harus membatalkan timer; kalau tidak, pengujian gagal
    // dengan "A Timer is still pending".
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
