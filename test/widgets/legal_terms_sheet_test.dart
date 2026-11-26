import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/widgets/legal_terms_sheet.dart';

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
    'LegalTermsSheet menampilkan Syarat & Ketentuan Sewa resmi lengkap dengan larangan umum dan biaya refund',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LegalTermsSheet.showSewaUnit(context),
                child: const Text('Buka Sewa'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Sewa'));
      await tester.pumpAndSettle();

      expect(find.text('Syarat & Ketentuan Sewa'), findsOneWidget);
      expect(
        find.text('Pasal 4: Larangan Umum & Kepatuhan Hukum (Berlaku Semua Mode)'),
        findsOneWidget,
      );
      expect(find.textContaining('Rp 50.000'), findsOneWidget);
      expect(find.textContaining('biaya admin bank dan administrasi'), findsOneWidget);
      expect(find.textContaining('tambahan jam sopir'), findsOneWidget);

      await tester.tap(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();

      expect(find.text('Syarat & Ketentuan Sewa'), findsNothing);
    },
  );
}
