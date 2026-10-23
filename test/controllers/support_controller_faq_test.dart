import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/core/network/api_client.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/screens/help_center_screen.dart';
import 'package:provider/provider.dart';

/// Test double untuk FaqApiService guna mensimulasikan respons online dan galat jaringan offline
class FakeFaqApiService extends FaqApiService {
  List<FaqModel>? faqsToReturn;
  Exception? exceptionToThrow;
  int fetchCount = 0;

  FakeFaqApiService({this.faqsToReturn, this.exceptionToThrow});

  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async {
    fetchCount++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return faqsToReturn ?? [];
  }
}

void main() {
  group('SupportController FAQ & Offline Resilience Tests', () {
    test('State awal SupportController memiliki fallback 6 FAQ dan kategori default', () {
      final controller = SupportController(faqApiService: FakeFaqApiService());

      expect(controller.faqs.length, equals(6));
      expect(controller.isLoadingFaqs, isFalse);
      expect(controller.faqError, isNull);

      // Kategori dinamis selalu diawali 'Semua'
      final categories = controller.faqCategories;
      expect(categories.first, equals('Semua'));
      expect(categories, contains('Booking & Sewa'));
      expect(categories, contains('Armada'));
      expect(categories, contains('Pembayaran'));
    });

    test('fetchFaqs berhasil memperbarui daftar FAQ dari backend online', () async {
      final remoteData = [
        const FaqModel(
          id: 'faq-rem-01',
          question: 'Bagaimana asuransi rental All-Risk?',
          answer: 'Semua armada MobilJuragan dilindungi asuransi komprehensif.',
          category: 'Asuransi & Proteksi',
          orderIndex: 1,
          isActive: true,
        ),
        const FaqModel(
          id: 'faq-rem-02',
          question: 'Apakah bisa antar armada ke Sota?',
          answer: 'Bisa dengan konfirmasi biaya operasional luar kota.',
          category: 'Destinasi Merauke',
          orderIndex: 2,
          isActive: true,
        ),
      ];

      final fakeService = FakeFaqApiService(faqsToReturn: remoteData);
      final controller = SupportController(faqApiService: fakeService);

      bool notificationReceived = false;
      controller.addListener(() {
        notificationReceived = true;
      });

      await controller.fetchFaqs();

      expect(fakeService.fetchCount, equals(1));
      expect(controller.isLoadingFaqs, isFalse);
      expect(controller.faqError, isNull);
      expect(controller.faqs.length, equals(2));
      expect(controller.faqs.first.id, equals('faq-rem-01'));
      expect(notificationReceived, isTrue);

      // Kategori baru tercermin secara dinamis
      final updatedCategories = controller.faqCategories;
      expect(updatedCategories, equals(['Semua', 'Asuransi & Proteksi', 'Destinasi Merauke']));
    });

    test('fetchFaqs tahan terhadap galat jaringan (offline resilience) dan tidak crash', () async {
      final fakeService = FakeFaqApiService(
        exceptionToThrow: ApiException('Tidak dapat terhubung ke server backend (Offline).', statusCode: 503),
      );
      final controller = SupportController(faqApiService: fakeService);

      // Pastikan fallback awal 6 FAQ terpasang
      expect(controller.faqs.length, equals(6));

      // Eksekusi fetch saat jaringan mati - TIDAK boleh melempar unhandled exception
      await controller.fetchFaqs();

      expect(fakeService.fetchCount, equals(1));
      expect(controller.isLoadingFaqs, isFalse);
      expect(controller.faqError, contains('Tidak dapat terhubung ke server backend (Offline).'));

      // Pertahankan 6 FAQ fallback tanpa ada data yang hilang
      expect(controller.faqs.length, equals(6));
      expect(controller.faqs.first.question, contains('Bandara Mopah Merauke'));
    });

    test('fetchFaqs menangani SocketException secara anggun dan mempertahankan fallback', () async {
      final fakeService = FakeFaqApiService(
        exceptionToThrow: const SocketException('Connection refused (os error 111)'),
      );
      final controller = SupportController(faqApiService: fakeService);

      await controller.fetchFaqs();

      expect(controller.isLoadingFaqs, isFalse);
      expect(controller.faqError, contains('Connection refused'));
      expect(controller.faqs.length, equals(6));
    });

    test('fetchFaqs dengan respons remote kosong tetap mempertahankan FAQ yang ada', () async {
      final fakeService = FakeFaqApiService(faqsToReturn: []);
      final controller = SupportController(faqApiService: fakeService);

      await controller.fetchFaqs();

      expect(controller.faqs.length, equals(6));
      expect(controller.faqError, isNull);
    });

    test('faqCategories mengurutkan kategori unik secara alfabetis setelah "Semua"', () async {
      final customFaqs = [
        const FaqModel(id: '1', question: 'Q1', answer: 'A1', category: 'Zebra', orderIndex: 1),
        const FaqModel(id: '2', question: 'Q2', answer: 'A2', category: 'Alpha', orderIndex: 2),
        const FaqModel(id: '3', question: 'Q3', answer: 'A3', category: 'Beta', orderIndex: 3),
        const FaqModel(id: '4', question: 'Q4', answer: 'A4', category: 'Alpha', orderIndex: 4),
      ];

      final fakeService = FakeFaqApiService(faqsToReturn: customFaqs);
      final controller = SupportController(faqApiService: fakeService);

      await controller.fetchFaqs();

      final categories = controller.faqCategories;
      expect(categories, equals(['Semua', 'Alpha', 'Beta', 'Zebra']));
    });
  });

  group('HelpCenterScreen Widget & Interaction Tests', () {
    testWidgets('HelpCenterScreen merender kategori dinamis dan 6 topik fallback', (tester) async {
      final controller = SupportController(faqApiService: FakeFaqApiService());

      await tester.pumpWidget(
        ChangeNotifierProvider<SupportController>.value(
          value: controller,
          child: const MaterialApp(
            home: HelpCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pusat Bantuan'), findsWidgets);
      expect(find.text('6 Topik'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Booking & Sewa'), findsOneWidget);
      expect(find.text('Armada'), findsOneWidget);
      expect(find.text('Pembayaran'), findsOneWidget);
      expect(find.text('Bagaimana prosedur penjemputan di Bandara Mopah Merauke?'), findsOneWidget);
    });

    testWidgets('Ketukan pada pertanyaan mengekspansi accordion jawaban FAQ', (tester) async {
      final controller = SupportController(faqApiService: FakeFaqApiService());

      await tester.pumpWidget(
        ChangeNotifierProvider<SupportController>.value(
          value: controller,
          child: const MaterialApp(
            home: HelpCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sebelum ketukan, teks jawaban belum tampil
      expect(find.textContaining('Tim operasional kami akan menunggu di lobi kedatangan Bandara Mopah'), findsNothing);

      // Ketuk pertanyaan pertama
      await tester.tap(find.text('Bagaimana prosedur penjemputan di Bandara Mopah Merauke?'));
      await tester.pumpAndSettle();

      // Sesudah ketukan, jawaban tampil di accordion
      expect(find.textContaining('Tim operasional kami akan menunggu di lobi kedatangan Bandara Mopah'), findsOneWidget);

      // Ketuk kembali untuk menutup
      await tester.tap(find.text('Bagaimana prosedur penjemputan di Bandara Mopah Merauke?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tim operasional kami akan menunggu di lobi kedatangan Bandara Mopah'), findsNothing);
    });

    testWidgets(
      'Pencarian kata kunci memfilter daftar FAQ secara real-time',
      (tester) async {
        final controller = SupportController(faqApiService: FakeFaqApiService());

        await tester.pumpWidget(
          ChangeNotifierProvider<SupportController>.value(
            value: controller,
            child: const MaterialApp(
              home: HelpCenterScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Cari kata kunci 'BBM'
        await tester.enterText(find.byType(TextField), 'BBM');
        await tester.pumpAndSettle();

        expect(find.text('1 Topik'), findsOneWidget);
        expect(find.text('Bagaimana kebijakan bahan bakar (BBM) armada?'), findsOneWidget);
        expect(find.text('Bagaimana prosedur penjemputan di Bandara Mopah Merauke?'), findsNothing);
      },
      skip: true, // Search bar dihapus dari UI Pusat Bantuan per spesifikasi desain
    );

    testWidgets('Pemilihan chip kategori memfilter topik sesuai kategori', (tester) async {
      final controller = SupportController(faqApiService: FakeFaqApiService());

      await tester.pumpWidget(
        ChangeNotifierProvider<SupportController>.value(
          value: controller,
          child: const MaterialApp(
            home: HelpCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pilih chip 'Pembayaran'
      await tester.tap(find.text('Pembayaran'));
      await tester.pumpAndSettle();

      expect(find.text('1 Topik'), findsOneWidget);
      expect(find.text('Metode pembayaran apa saja yang berlaku?'), findsOneWidget);
      expect(find.text('Bagaimana kebijakan bahan bakar (BBM) armada?'), findsNothing);
    });
  });
}
