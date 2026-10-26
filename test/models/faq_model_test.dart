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

  group('FaqModel Equality Tests', () {
    test('operator equality dan hashCode bekerja dengan benar', () {
      const item1 = FaqModel(
        id: 'faq-uji-01',
        question: 'Apakah unit bisa diantar ke bandara?',
        answer: 'Bisa, tanpa biaya tambahan di dalam kota Merauke.',
        category: 'Booking & Sewa',
        orderIndex: 1,
        isActive: true,
      );
      const item2 = FaqModel(
        id: 'faq-uji-01',
        question: 'Apakah unit bisa diantar ke bandara?',
        answer: 'Bisa, tanpa biaya tambahan di dalam kota Merauke.',
        category: 'Booking & Sewa',
        orderIndex: 1,
        isActive: true,
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });
  });
}
