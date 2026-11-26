import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/auth_controller.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/vehicle_controller.dart';
import 'package:mobiljuragan_mobile/screens/auth/register_screen.dart';
import 'package:mobiljuragan_mobile/screens/order_review_screen.dart';
import 'package:mobiljuragan_mobile/widgets/legal_terms_sheet.dart';
import 'package:provider/provider.dart';

import '../support/armada_uji.dart';

Offset _centerOfSubstring(
  WidgetTester tester,
  Finder richTextFinder,
  String target,
) {
  final renderParagraph = tester.renderObject<RenderParagraph>(richTextFinder);
  final plainText = renderParagraph.text.toPlainText();
  final start = plainText.indexOf(target);
  expect(start, greaterThanOrEqualTo(0), reason: 'Teks "$target" tidak ditemukan');
  final boxes = renderParagraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + target.length),
  );
  expect(boxes, isNotEmpty, reason: 'Box seleksi "$target" kosong');
  return renderParagraph.localToGlobal(boxes.first.toRect().center);
}

void main() {
  testWidgets(
    'LegalTermsSheet menampilkan Syarat Layanan & Privasi Akun resmi dan dapat ditutup',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LegalTermsSheet.showAkunDanPrivasi(context),
                child: const Text('Buka Akun'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Syarat Layanan & Privasi Akun'), findsOneWidget);
      expect(
        find.text('Pasal 3: Kategori Data Pribadi yang Dikumpulkan'),
        findsOneWidget,
      );
      expect(find.text('Saya Mengerti'), findsOneWidget);

      await tester.tap(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();

      expect(find.text('Syarat Layanan & Privasi Akun'), findsNothing);
    },
  );

  testWidgets(
    'LegalTermsSheet menampilkan Syarat & Ketentuan Pengguna resmi lengkap dan showSewaUnit mendelegasikan ke sana',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => LegalTermsSheet.showSyaratDanKetentuan(context),
                    child: const Text('Buka Ketentuan'),
                  ),
                  ElevatedButton(
                    onPressed: () => LegalTermsSheet.showSewaUnit(context),
                    child: const Text('Buka Sewa'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      for (final label in ['Buka Ketentuan', 'Buka Sewa']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text('Syarat & Ketentuan Pengguna'), findsOneWidget);
        expect(find.text('Selamat datang di MobilJuragan!'), findsOneWidget);
        expect(find.text('1. Definisi'), findsOneWidget);
        expect(
          find.text('7. Ketentuan Pembatalan dan Perubahan Pemesanan'),
          findsOneWidget,
        );
        expect(
          find.text('11. Privasi dan Penggunaan Data'),
          findsOneWidget,
        );
        expect(find.text('15. Penutup'), findsOneWidget);
        expect(find.text('Saya Mengerti'), findsOneWidget);

        await tester.tap(find.text('Saya Mengerti'));
        await tester.pumpAndSettle();

        expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);
      }
    },
  );

  testWidgets(
    'OrderReviewScreen mengisolasi klik checkbox, teks pengantar, dan hyperlink Syarat & Ketentuan',
    (WidgetTester tester) async {
      final vehicle = armadaUji.first;
      final booking = BookingController()..selectVehicle(vehicle);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
            ChangeNotifierProvider<BookingController>.value(value: booking),
            ChangeNotifierProvider<VehicleController>(
              create: (_) => VehicleController(),
            ),
          ],
          child: MaterialApp(
            home: OrderReviewScreen(vehicle: vehicle),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);
      final richTextFinder = find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('Syarat dan Ketentuan Pengguna MobilJuragan'),
      );

      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();

      expect(booking.agreementChecked, isFalse);

      // 1. Klik Checkbox -> toggle false -> true -> false tanpa membuka sheet
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(booking.agreementChecked, isTrue);
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(booking.agreementChecked, isFalse);
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);

      // 2. Klik hyperlink saat unchecked -> buka sheet, checkbox tetap false
      final linkCenter = _centerOfSubstring(
        tester,
        richTextFinder,
        'Syarat dan Ketentuan Pengguna MobilJuragan',
      );
      await tester.tapAt(linkCenter);
      await tester.pumpAndSettle();

      expect(find.text('Syarat & Ketentuan Pengguna'), findsOneWidget);
      expect(booking.agreementChecked, isFalse);

      await tester.tap(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);
      expect(booking.agreementChecked, isFalse);

      // 3. Klik teks pengantar -> toggle checkbox true tanpa membuka sheet
      final prefixCenter = _centerOfSubstring(
        tester,
        richTextFinder,
        'Saya menyetujui ',
      );
      await tester.tapAt(prefixCenter);
      await tester.pumpAndSettle();
      expect(booking.agreementChecked, isTrue);
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);

      // 4. Klik hyperlink saat checked -> buka sheet dan tutup, checkbox tetap true
      await tester.tapAt(
        _centerOfSubstring(
          tester,
          richTextFinder,
          'Syarat dan Ketentuan Pengguna MobilJuragan',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Syarat & Ketentuan Pengguna'), findsOneWidget);
      expect(booking.agreementChecked, isTrue);

      await tester.tap(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);
      expect(booking.agreementChecked, isTrue);
    },
  );

  testWidgets(
    'RegisterScreen mengisolasi klik checkbox, teks pengantar, dan hyperlink Syarat & Ketentuan',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(),
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);
      final richTextFinder = find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('Syarat dan Ketentuan Pengguna MobilJuragan'),
      );

      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

      // 1. Klik Checkbox -> toggle false -> true -> false tanpa membuka sheet
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);

      // 2. Klik hyperlink saat unchecked -> buka sheet, checkbox tetap false
      await tester.tapAt(
        _centerOfSubstring(
          tester,
          richTextFinder,
          'Syarat dan Ketentuan Pengguna MobilJuragan',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Syarat & Ketentuan Pengguna'), findsOneWidget);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

      await tester.tap(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

      // 3. Klik teks pengantar -> toggle checkbox true tanpa membuka sheet
      await tester.tapAt(
        _centerOfSubstring(
          tester,
          richTextFinder,
          'Saya menyatakan data di atas benar dan menyetujui ',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);

      // 4. Klik hyperlink saat checked -> buka sheet dan tutup, checkbox tetap true
      await tester.tapAt(
        _centerOfSubstring(
          tester,
          richTextFinder,
          'Syarat dan Ketentuan Pengguna MobilJuragan',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Syarat & Ketentuan Pengguna'), findsOneWidget);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

      await tester.tap(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Syarat & Ketentuan Pengguna'), findsNothing);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
    },
  );
}
