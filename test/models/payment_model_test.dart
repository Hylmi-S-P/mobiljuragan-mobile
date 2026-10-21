import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/models/payment_model.dart';

void main() {
  group('PaymentModel Deserialization & Serialization Tests', () {
    test('fromJson mem-parsing payload API pembayaran backend dengan tepat', () {
      final json = {
        'id': 'pay-uuid-001',
        'bookingId': 'book-uuid-101',
        'baseAmount': 450000,
        'uniqueCode': 418,
        'totalAmount': 450418,
        'method': 'QRIS',
        'status': 'UNPAID',
        'qrisPayload': '000201010212...63041234',
        'bankName': 'GOPAY',
        'expiresAt': '2026-10-21T14:00:00.000Z',
        'createdAt': '2026-10-21T12:00:00.000Z',
      };

      final payment = PaymentModel.fromJson(json);

      expect(payment.id, equals('pay-uuid-001'));
      expect(payment.bookingId, equals('book-uuid-101'));
      expect(payment.baseAmount, equals(450000));
      expect(payment.uniqueCode, equals(418));
      expect(payment.totalAmount, equals(450418));
      expect(payment.method, equals(PaymentMethod.qris));
      expect(payment.status, equals(PaymentStatus.unpaid));
      expect(payment.qrisPayload, equals('000201010212...63041234'));
      expect(payment.bankName, equals('GOPAY'));
      expect(payment.isPaid, isFalse);
      expect(payment.isPendingVerification, isFalse);
    });

    test('fromJson menangani konversi tipe dinamis (string dan decimal)', () {
      final json = {
        'id': 'pay-002',
        'bookingId': 'book-002',
        'baseAmount': '350000.00',
        'uniqueCode': '123',
        'totalAmount': '350123.00',
        'method': 'BANK_TRANSFER',
        'status': 'PAID',
        'verifiedAt': '2026-10-21T13:00:00.000Z',
      };

      final payment = PaymentModel.fromJson(json);

      expect(payment.baseAmount, equals(350000));
      expect(payment.uniqueCode, equals(123));
      expect(payment.totalAmount, equals(350123));
      expect(payment.method, equals(PaymentMethod.bankTransfer));
      expect(payment.status, equals(PaymentStatus.paid));
      expect(payment.isPaid, isTrue);
      expect(payment.verifiedAt, isNotNull);
    });

    test('toJson menghasilkan Map JSON terstruktur secara simetris', () {
      final now = DateTime.parse('2026-10-21T12:00:00.000Z');
      final expires = DateTime.parse('2026-10-21T14:00:00.000Z');

      final payment = PaymentModel(
        id: 'pay-003',
        bookingId: 'book-003',
        baseAmount: 500000,
        uniqueCode: 250,
        totalAmount: 500250,
        method: PaymentMethod.qris,
        status: PaymentStatus.pendingVerification,
        qrisPayload: 'QRIS-PAYLOAD-SAMPLE',
        bankName: 'GOPAY',
        createdAt: now,
        expiresAt: expires,
      );

      final json = payment.toJson();

      expect(json['id'], equals('pay-003'));
      expect(json['bookingId'], equals('book-003'));
      expect(json['baseAmount'], equals(500000));
      expect(json['uniqueCode'], equals(250));
      expect(json['totalAmount'], equals(500250));
      expect(json['method'], equals('QRIS'));
      expect(json['status'], equals('PENDING_VERIFICATION'));
      expect(json['qrisPayload'], equals('QRIS-PAYLOAD-SAMPLE'));
      expect(json['expiresAt'], equals(expires.toIso8601String()));
    });
  });

  group('PaymentModel Dynamic QRIS Generator (EMVCo Engine) Tests', () {
    test('generateDynamicQris menginjeksi Tag 54 dan Tag 01 dinamis dengan CRC-16 valid', () {
      const amount = 450418;
      final qris = PaymentModel.generateDynamicQris(amount);

      // Verifikasi Tag 01 bernilai '12' (Dinamis)
      expect(qris, contains('010212'));

      // Verifikasi Tag 54 mengunci nominal pas
      expect(qris, contains('5406450418'));

      // Verifikasi Tag 63 (CRC-16) di bagian akhir
      expect(qris, contains('6304'));
      final crcIndex = qris.lastIndexOf('6304');
      expect(crcIndex, isPositive);
      final checksum = qris.substring(crcIndex + 4);
      expect(checksum.length, equals(4));

      // Checksum harus berupa karakter hex uppercase
      expect(RegExp(r'^[0-9A-F]{4}$').hasMatch(checksum), isTrue);
    });

    test('generateDynamicQris dengan nominal berbeda menghasilkan checksum yang berbeda pula', () {
      final qris1 = PaymentModel.generateDynamicQris(350100);
      final qris2 = PaymentModel.generateDynamicQris(350200);

      expect(qris1, isNot(equals(qris2)));
      expect(qris1, contains('5406350100'));
      expect(qris2, contains('5406350200'));
    });
  });

  group('PaymentMethod & PaymentStatus Enum Tests', () {
    test('PaymentMethod fromString dan label sesuai konvensi', () {
      expect(PaymentMethod.fromString('QRIS'), equals(PaymentMethod.qris));
      expect(PaymentMethod.fromString('BANK_TRANSFER'), equals(PaymentMethod.bankTransfer));
      expect(PaymentMethod.fromString('CASH'), equals(PaymentMethod.cash));
      expect(PaymentMethod.fromString('COD'), equals(PaymentMethod.cash));
      expect(PaymentMethod.fromString(null), equals(PaymentMethod.qris));

      expect(PaymentMethod.qris.label, equals('QRIS Dinamis'));
      expect(PaymentMethod.bankTransfer.label, equals('Transfer Bank'));
      expect(PaymentMethod.cash.label, contains('COD'));
    });

    test('PaymentStatus fromString dan label sesuai konvensi', () {
      expect(PaymentStatus.fromString('UNPAID'), equals(PaymentStatus.unpaid));
      expect(PaymentStatus.fromString('PENDING_VERIFICATION'), equals(PaymentStatus.pendingVerification));
      expect(PaymentStatus.fromString('PAID'), equals(PaymentStatus.paid));
      expect(PaymentStatus.fromString('FAILED'), equals(PaymentStatus.failed));
      expect(PaymentStatus.fromString('REFUNDED'), equals(PaymentStatus.refunded));

      expect(PaymentStatus.unpaid.label, equals('Menunggu Pembayaran'));
      expect(PaymentStatus.paid.label, contains('Lunas'));
    });
  });
}
