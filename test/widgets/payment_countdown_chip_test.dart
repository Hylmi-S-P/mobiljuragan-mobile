import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/widgets/payment_countdown_chip.dart';

void main() {
  group('PaymentCountdownChip', () {
    testWidgets('angka turun setiap detik tanpa menunggu polling layar induk',
        (tester) async {
      var sekarang = DateTime(2026, 1, 1, 12, 0, 0);
      final batas = sekarang.add(const Duration(minutes: 2, seconds: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCountdownChip(
              expiresAt: batas,
              nowProvider: () => sekarang,
            ),
          ),
        ),
      );

      expect(find.text('00:02:05'), findsOneWidget);

      sekarang = sekarang.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:02:04'), findsOneWidget);

      sekarang = sekarang.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:02:03'), findsOneWidget);
    });

    testWidgets('menampilkan Kedaluwarsa saat batas waktu lewat',
        (tester) async {
      var sekarang = DateTime(2026, 1, 1, 12, 0, 0);
      final batas = sekarang.add(const Duration(seconds: 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCountdownChip(
              expiresAt: batas,
              nowProvider: () => sekarang,
            ),
          ),
        ),
      );

      expect(find.text('00:00:02'), findsOneWidget);

      sekarang = sekarang.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Kedaluwarsa'), findsOneWidget);
    });

    testWidgets('tanpa tagihan tidak menebak sisa waktu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PaymentCountdownChip(expiresAt: null)),
        ),
      );

      expect(find.text('Menunggu tagihan'), findsOneWidget);
    });
  });
}
