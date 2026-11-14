import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/core/network/api_client.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/screens/help_center_screen.dart';
import 'package:provider/provider.dart';

/// Test double kustom untuk mensimulasikan berbagai kondisi ekstrem API backend
class AdversarialFaqApiService extends FaqApiService {
  Future<List<FaqModel>> Function()? fetchHandler;
  int callCount = 0;

  AdversarialFaqApiService({this.fetchHandler});

  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async {
    callCount++;
    if (fetchHandler != null) {
      return await fetchHandler!();
    }
    return [];
  }
}

void main() {
  group('Adversarial Challenge: Offline Resilience & Exception Handling', () {
    test('Offline: Menangani SocketException (DNS failure, Connection refused)', () async {
      final mock = AdversarialFaqApiService(fetchHandler: () async {
        throw const SocketException('Failed host lookup: api.mobiljuragan.id');
      });
      final controller = SupportController(faqApiService: mock);

      expect(controller.faqs, isEmpty, reason: 'Tidak ada lagi FAQ karangan di model');
      await controller.fetchFaqs();

      expect(mock.callCount, equals(1));
      expect(controller.isLoadingFaqs, isFalse);
      expect(controller.faqError, contains('Failed host lookup'));
      expect(controller.faqs, isEmpty, reason: 'Server gagal, jadi daftar tetap kosong');
      // Tidak ada FAQ bawaan yang bisa diperiksa id-nya.
    });

    test('Offline: Menangani TimeoutException dari koneksi lambat/putus di Merauke', () async {
      final mock = AdversarialFaqApiService(fetchHandler: () async {
        throw TimeoutException('Koneksi timeout 15000ms ke server');
      });
      final controller = SupportController(faqApiService: mock);

      await controller.fetchFaqs();

      expect(controller.isLoadingFaqs, isFalse);
      expect(controller.faqError, contains('timeout'));
expect(controller.faqs, isEmpty);
    });

    test('Offline: Menangani HttpException dan ApiException status 500, 502, 503', () async {
      final errors = [
        ApiException('Internal Server Error', statusCode: 500),
        ApiException('Bad Gateway', statusCode: 502),
        ApiException('Service Unavailable', statusCode: 503),
        const HttpException('Connection reset by peer'),
      ];

      for (final error in errors) {
        final mock = AdversarialFaqApiService(fetchHandler: () async {
          throw error;
        });
        final controller = SupportController(faqApiService: mock);

        await controller.fetchFaqs();

        expect(controller.isLoadingFaqs, isFalse);
        expect(controller.faqError, isNotNull);
expect(controller.faqs, isEmpty);
      }
    });

    test('Offline: Menangani malformed data / FormatException tanpa crash', () async {
      final mock = AdversarialFaqApiService(fetchHandler: () async {
        throw const FormatException('Unexpected character: < at position 0 (HTML returned instead of JSON)');
      });
      final controller = SupportController(faqApiService: mock);

      await controller.fetchFaqs();

      expect(controller.isLoadingFaqs, isFalse);
      expect(controller.faqError, contains('FormatException'));
expect(controller.faqs, isEmpty);
    });

    test('Concurrency: Panggilan serentak (rapid multiple fetchFaqs) diabaikan oleh guard isLoadingFaqs', () async {
      final completer = Completer<List<FaqModel>>();
      final mock = AdversarialFaqApiService(fetchHandler: () => completer.future);
      final controller = SupportController(faqApiService: mock);

      // Jalankan 5 panggilan serentak
      final future1 = controller.fetchFaqs();
      final future2 = controller.fetchFaqs();
      final future3 = controller.fetchFaqs();
      final future4 = controller.fetchFaqs();
      final future5 = controller.fetchFaqs();

      expect(mock.callCount, equals(1), reason: 'Guard isLoadingFaqs harus mencegah duplikasi fetch');

      completer.complete([
        const FaqModel(id: 'c-1', question: 'Q', answer: 'A', category: 'Umum'),
      ]);

      await Future.wait([future1, future2, future3, future4, future5]);

      expect(mock.callCount, equals(1));
      expect(controller.faqs.length, equals(1));
    });

    test('State Integrity: Sekuens pemulihan jaringan (Offline -> Online -> Offline lagi)', () async {
      int step = 0;
      final mock = AdversarialFaqApiService(fetchHandler: () async {
        if (step == 0) {
          throw const SocketException('Network offline');
        } else if (step == 1) {
          return [
            const FaqModel(id: 'sync-1', question: 'Q Online 1', answer: 'A', category: 'OnlineCat'),
            const FaqModel(id: 'sync-2', question: 'Q Online 2', answer: 'A', category: 'OnlineCat'),
          ];
        } else {
          throw TimeoutException('Koneksi putus kembali');
        }
      });
      final controller = SupportController(faqApiService: mock);

      // Langkah 1: Offline -> Fallback 6 tetap ada
      step = 0;
      await controller.fetchFaqs();
expect(controller.faqs, isEmpty);
      expect(controller.faqError, contains('Network offline'));

      // Langkah 2: Online -> Berhasil sinkron ke 2 item remote
      step = 1;
      await controller.fetchFaqs();
      expect(controller.faqs.length, equals(2));
      expect(controller.faqError, isNull);

      // Langkah 3: Offline kembali -> 2 item hasil sinkron sebelumnya TIDAK boleh hilang/wiped
      step = 2;
      await controller.fetchFaqs();
      expect(controller.faqs.length, equals(2));
      expect(controller.faqError?.toLowerCase(), contains('timeout'));
    });
  });

  group('Adversarial Challenge: Dynamic Category Chips & Deduplication', () {
    test('Deduplikasi kategori yang berulang dan penempatan "Semua" di awal', () async {
      final faqs = [
        const FaqModel(id: '1', question: 'Q1', answer: 'A1', category: 'Armada'),
        const FaqModel(id: '2', question: 'Q2', answer: 'A2', category: 'Pembayaran'),
        const FaqModel(id: '3', question: 'Q3', answer: 'A3', category: 'Armada'),
        const FaqModel(id: '4', question: 'Q4', answer: 'A4', category: 'Booking & Sewa'),
        const FaqModel(id: '5', question: 'Q5', answer: 'A5', category: 'Pembayaran'),
      ];

      final mock = AdversarialFaqApiService(fetchHandler: () async => faqs);
      final controller = SupportController(faqApiService: mock);
      await controller.fetchFaqs();

      final categories = controller.faqCategories;
      expect(categories.first, equals('Semua'), reason: '"Semua" wajib di posisi indeks 0');
      expect(categories.where((c) => c == 'Armada').length, equals(1), reason: 'Armada harus dideduplikasi');
      expect(categories.where((c) => c == 'Pembayaran').length, equals(1), reason: 'Pembayaran harus dideduplikasi');
      expect(categories, equals(['Semua', 'Armada', 'Booking & Sewa', 'Pembayaran']));
    });

    test('Pembersihan spasi (trim) dan pemfilteran kategori kosong', () async {
      final faqs = [
        const FaqModel(id: '1', question: 'Q1', answer: 'A1', category: '  Armada  '),
        const FaqModel(id: '2', question: 'Q2', answer: 'A2', category: 'Armada'),
        const FaqModel(id: '3', question: 'Q3', answer: 'A3', category: ''),
        const FaqModel(id: '4', question: 'Q4', answer: 'A4', category: '   '),
        const FaqModel(id: '5', question: 'Q5', answer: 'A5', category: '\tPembayaran\n'),
      ];

      final mock = AdversarialFaqApiService(fetchHandler: () async => faqs);
      final controller = SupportController(faqApiService: mock);
      await controller.fetchFaqs();

      final categories = controller.faqCategories;
      expect(categories, equals(['Semua', 'Armada', 'Pembayaran']));
      expect(categories.contains(''), isFalse);
      expect(categories.contains('   '), isFalse);
    });

    test('Kategori kustom dengan karakter khusus, simbol, dan emoji', () async {
      final faqs = [
        const FaqModel(id: '1', question: 'Q1', answer: 'A1', category: 'Promo 100% & Diskon!'),
        const FaqModel(id: '2', question: 'Q2', answer: 'A2', category: 'VIP / VVIP (Merauke)'),
        const FaqModel(id: '3', question: 'Q3', answer: 'A3', category: 'ðŸš™ Layanan Bandara'),
      ];

      final mock = AdversarialFaqApiService(fetchHandler: () async => faqs);
      final controller = SupportController(faqApiService: mock);
      await controller.fetchFaqs();

      final categories = controller.faqCategories;
      expect(categories.first, equals('Semua'));
      expect(categories, contains('Promo 100% & Diskon!'));
      expect(categories, contains('VIP / VVIP (Merauke)'));
      expect(categories, contains('ðŸš™ Layanan Bandara'));
    });
  });

  group('Adversarial Challenge: Kategori dinamis saat sinkronisasi', () {
    testWidgets('Reset kategori ke "Semua" secara aman jika kategori yang dipilih hilang saat sinkronisasi', (tester) async {
      final mock = AdversarialFaqApiService(fetchHandler: () async {
        return [
          const FaqModel(id: '1', question: 'Q1', answer: 'A1', category: 'Kategori Sementara'),
        ];
      });
      final controller = SupportController(faqApiService: mock);
      await controller.fetchFaqs();

      await tester.pumpWidget(
        ChangeNotifierProvider<SupportController>.value(
          value: controller,
          child: const MaterialApp(home: HelpCenterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Pilih 'Kategori Sementara'
      await tester.tap(find.text('Kategori Sementara'));
      await tester.pumpAndSettle();

      // Sekarang simulasi backend mengembalikan kategori baru tanpa 'Kategori Sementara'
      mock.fetchHandler = () async {
        return [
          const FaqModel(id: '2', question: 'Q2', answer: 'A2', category: 'Kategori Tetap'),
        ];
      };
      await controller.fetchFaqs();
      await tester.pumpAndSettle();

      // Widget tidak boleh crash dan otomatis fallback ke 'Semua'
      expect(find.text('Pusat Bantuan'), findsWidgets);
      expect(find.text('1 Topik'), findsOneWidget);
      expect(find.text('Kategori Tetap'), findsOneWidget);
    });
  });
}
