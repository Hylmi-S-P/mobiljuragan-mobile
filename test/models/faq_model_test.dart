import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';

void main() {
  group('FaqModel Serialization & Deserialization Tests', () {
    test('fromJson mem-parsing JSON lengkap dari backend dengan tepat', () {
      final json = {
        'id': 'faq-uuid-001',
        'question': 'Bagaimana cara booking sewa mobil lepas kunci?',
        'answer': 'Pilih armada di katalog, tentukan tanggal, lalu unggah KTP dan SIM A.',
        'category': 'Booking & Sewa',
        'orderIndex': 1,
        'isActive': true,
        'createdAt': '2026-10-21T10:00:00.000Z',
        'updatedAt': '2026-10-21T10:30:00.000Z',
      };

      final faq = FaqModel.fromJson(json);

      expect(faq.id, equals('faq-uuid-001'));
      expect(faq.question, equals('Bagaimana cara booking sewa mobil lepas kunci?'));
      expect(faq.answer, contains('Pilih armada di katalog'));
      expect(faq.category, equals('Booking & Sewa'));
      expect(faq.orderIndex, equals(1));
      expect(faq.isActive, isTrue);
      expect(faq.createdAt, isNotNull);
      expect(faq.updatedAt, isNotNull);
      expect(faq.createdAt!.year, equals(2026));
    });

    test('fromJson menangani konversi tipe dinamis (string orderIndex & boolean string)', () {
      final json = {
        'id': 'faq-002',
        'question': 'Metode pembayaran?',
        'answer': 'QRIS dan Transfer Bank BRI/Mandiri.',
        'category': 'Pembayaran',
        'orderIndex': '4',
        'isActive': 'true',
      };

      final faq = FaqModel.fromJson(json);

      expect(faq.orderIndex, equals(4));
      expect(faq.isActive, isTrue);
    });

    test('fromJson menangani data parsial dan nilai fallback default', () {
      final json = <String, dynamic>{
        'question': 'Pertanyaan tanpa kategori',
        'answer': 'Jawaban ringkas',
      };

      final faq = FaqModel.fromJson(json);

      expect(faq.id, equals(''));
      expect(faq.category, equals('Umum'));
      expect(faq.orderIndex, equals(0));
      expect(faq.isActive, isTrue);
      expect(faq.createdAt, isNull);
      expect(faq.updatedAt, isNull);
    });

    test('toJson menghasilkan Map JSON terstruktur secara simetris', () {
      final now = DateTime.parse('2026-10-21T12:00:00.000Z');
      final faq = FaqModel(
        id: 'faq-003',
        question: 'Apakah BBM terisi penuh?',
        answer: 'Diserahterimakan minimal setengah bar.',
        category: 'Armada',
        orderIndex: 3,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = faq.toJson();

      expect(json['id'], equals('faq-003'));
      expect(json['category'], equals('Armada'));
      expect(json['orderIndex'], equals(3));
      expect(json['isActive'], isTrue);
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(now.toIso8601String()));
    });
  });

  group('FaqModel Fallback FAQs Integrity Tests', () {
    test('fallbackFaqs menyediakan tepat 6 FAQ kanonik Merauke', () {
      final fallbacks = FaqModel.fallbackFaqs;

      expect(fallbacks.length, equals(6));
      for (final faq in fallbacks) {
        expect(faq.id.isNotEmpty, isTrue);
        expect(faq.question.isNotEmpty, isTrue);
        expect(faq.answer.isNotEmpty, isTrue);
        expect(faq.category.isNotEmpty, isTrue);
        expect(faq.isActive, isTrue);
        expect(faq.orderIndex, inInclusiveRange(1, 6));
      }
    });

    test('fallbackFaqs mencakup kategori Booking & Sewa, Armada, dan Pembayaran', () {
      final categories = FaqModel.fallbackFaqs.map((f) => f.category).toSet();

      expect(categories, contains('Booking & Sewa'));
      expect(categories, contains('Armada'));
      expect(categories, contains('Pembayaran'));
    });

    test('operator equality dan hashCode bekerja dengan benar', () {
      final item1 = FaqModel.fallbackFaqs.first;
      final item2 = FaqModel(
        id: item1.id,
        question: item1.question,
        answer: item1.answer,
        category: item1.category,
        orderIndex: item1.orderIndex,
        isActive: item1.isActive,
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });
  });
}
