import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/screens/help_center_screen.dart';
import 'package:mobiljuragan_mobile/screens/order_history_screen.dart';
import 'package:provider/provider.dart';

import '../support/armada_uji.dart';

class _StubAiApi extends AiApiService {
  @override
  Future<AiChatResult> kirimPesan({
    required String pesan,
    String? ticketId,
  }) async => const AiChatResult(balasan: '', pakaiCadangan: false);
}

class _StubTicketApi extends TicketApiService {
  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async => [];
}

class _StubFaqApi extends FaqApiService {
  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async =>
      [];
}

void main() {
  final vehicle = armadaUji.first;

  group('BookingModel Sesi 3 parsing', () {
    test('membaca statusHistory fallback untuk batal admin / sistem / ditolak & refund bukti', () {
      final base = <String, dynamic>{
        'bookingCode': 'MJ-HIS-ADMIN',
        'rentalType': 'WITH_DRIVER',
        'pickupLocation': 'Bandara Mopah',
        'startDateTime': '2026-11-16T08:00:00.000Z',
        'endDateTime': '2026-11-17T08:00:00.000Z',
        'status': 'CANCELLED',
        'tariffStatus': 'CONFIRMED',
        'quotedAmount': 500000,
        'finalAmount': 500000,
        'createdAt': '2026-11-15T08:00:00.000Z',
        'statusHistory': [
          {
            'toStatus': 'CANCELLED',
            'actor': 'ADMIN',
            'note': 'Dibatalkan oleh admin: Unit masuk perawatan mendadak',
            'changedAt': '2026-11-16T02:00:00.000Z',
          },
        ],
      };

      final adminCancelled = BookingModel.fromJson(base, vehicle);
      expect(adminCancelled.status, BookingStatus.dibatalkan);
      expect(adminCancelled.cancelledBy, 'ADMIN');
      expect(adminCancelled.cancellationReason, 'Unit masuk perawatan mendadak');
      expect(adminCancelled.cancelledAt, isNotNull);
      expect(adminCancelled.isRejectedByAdmin, isFalse);

      final rejected = BookingModel.fromJson({
        ...base,
        'bookingCode': 'MJ-HIS-REJ',
        'status': 'REJECTED',
        'statusHistory': [
          {
            'toStatus': 'REJECTED',
            'actor': 'ADMIN',
            'note': 'Jadwal bentrok di tanggal tersebut',
            'changedAt': '2026-11-16T03:00:00.000Z',
          },
        ],
      }, vehicle);
      expect(rejected.status, BookingStatus.dibatalkan);
      expect(rejected.isRejectedByAdmin, isTrue);
      expect(rejected.cancelledBy, 'ADMIN');
      expect(rejected.cancellationReason, 'Jadwal bentrok di tanggal tersebut');

      final refundDone = BookingModel.fromJson({
        ...base,
        'bookingCode': 'MJ-HIS-REF',
        'refund': {
          'nominal': 500000,
          'dibatalkanOleh': 'ADMIN',
          'alasan': 'Dibatalkan admin: Unit masuk bengkel',
          'dicatatPada': '2026-11-16T04:00:00.000Z',
          'status': 'SELESAI',
          'danaTerverifikasi': true,
          'namaBank': 'BRI',
          'nomorRekening': '005401009988501',
          'namaPemilik': 'Harun Yahya',
          'buktiUrl': '/api/v1/media/abc-123',
        },
      }, vehicle);
      expect(refundDone.refundProofUrl, '/api/v1/media/abc-123');
      expect(refundDone.danaTerverifikasi, isTrue);
      expect(refundDone.cancellationReason, 'Unit masuk bengkel');

      final refundUnverified = BookingModel.fromJson({
        ...base,
        'bookingCode': 'MJ-HIS-UNV',
        'refund': {
          'nominal': 750000,
          'dibatalkanOleh': 'CUSTOMER',
          'alasan': 'Batal sebelum verifikasi',
          'dicatatPada': '2026-11-16T05:00:00.000Z',
          'status': 'MENUNGGU',
          'danaTerverifikasi': false,
        },
      }, vehicle);
      expect(refundUnverified.danaTerverifikasi, isFalse);
    });
  });

  group('OrderHistoryScreen Sesi 3 Riwayat Selesai', () {
    testWidgets('menampilkan filter, badge aktor, gate danaTerverifikasi, dan bukti transfer', (tester) async {
      final unverifiedRefund = BookingModel(
        id: 'MJ-R001',
        vehicle: vehicle,
        startDate: DateTime(2026, 11, 12),
        startTime: '08.00 WIT',
        durationDays: 2,
        withDriver: false,
        pickupLocation: 'Kantor MobilJuragan',
        status: BookingStatus.dibatalkan,
        createdAt: DateTime(2026, 11, 11),
        dailyRate: 400000,
        isFinalTariffConfirmed: true,
        cancellationReason: 'Berubah jadwal',
        cancellationRefundAmount: 750000,
        refundStatus: 'MENUNGGU',
        danaTerverifikasi: false,
        cancelledBy: 'CUSTOMER',
        cancelledAt: DateTime(2026, 11, 12),
      );

      final completedRefund = BookingModel(
        id: 'MJ-R004',
        vehicle: vehicle,
        startDate: DateTime(2026, 11, 15),
        startTime: '08.00 WIT',
        durationDays: 2,
        withDriver: true,
        pickupLocation: 'Hotel Swiss-Belhotel',
        status: BookingStatus.dibatalkan,
        createdAt: DateTime(2026, 11, 14),
        dailyRate: 400000,
        isFinalTariffConfirmed: true,
        cancellationReason: 'Unit masuk perawatan',
        cancellationRefundAmount: 800000,
        refundStatus: 'SELESAI',
        danaTerverifikasi: true,
        cancellationBank: 'BRI',
        cancellationAccountNumber: '005401009988501',
        cancellationAccountName: 'Harun Yahya',
        refundProofUrl: '/api/v1/media/proof-1',
        cancelledBy: 'ADMIN',
        cancelledAt: DateTime(2026, 11, 15),
      );

      final rejectedOrder = BookingModel(
        id: 'MJ-A002',
        vehicle: vehicle,
        startDate: DateTime(2026, 11, 16),
        startTime: '08.00 WIT',
        durationDays: 1,
        withDriver: false,
        pickupLocation: 'Kantor',
        status: BookingStatus.dibatalkan,
        createdAt: DateTime(2026, 11, 15),
        dailyRate: 400000,
        isFinalTariffConfirmed: false,
        cancellationReason: 'Jadwal bentrok',
        cancelledBy: 'ADMIN',
        isRejectedByAdmin: true,
        cancelledAt: DateTime(2026, 11, 16),
      );

      final controller = BookingController();
      controller.setBookingsForTesting([
        unverifiedRefund,
        completedRefund,
        rejectedOrder,
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<BookingController>.value(
          value: controller,
          child: const MaterialApp(home: OrderHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Riwayat Selesai'));
      await tester.pumpAndSettle();

      // Filter pills tampil
      expect(find.text('Sewa Selesai'), findsOneWidget);
      expect(find.text('Refund'), findsOneWidget);

      // Gate danaTerverifikasi menahan tombol Klaim Pengembalian Dana untuk MJ-R001
      expect(find.text('Klaim Pengembalian Dana'), findsNothing);
      expect(find.text('Verifikasi Dana'), findsOneWidget);

      // Badge aktor distinct
      expect(find.text('Dibatalkan Anda'), findsOneWidget);
      expect(find.text('Dibatalkan Admin'), findsOneWidget);
      expect(find.text('Ditolak Admin'), findsOneWidget);

      // Tombol Lihat Bukti Transfer hadir untuk MJ-R004 yang SELESAI
      expect(find.text('Lihat Bukti Transfer'), findsOneWidget);
    });
  });

  group('HelpCenterScreen showBackButton', () {
    testWidgets('menampilkan tombol kembali saat showBackButton bernilai true', (tester) async {
      final support = SupportController(
        aiApiService: _StubAiApi(),
        ticketApiService: _StubTicketApi(),
        faqApiService: _StubFaqApi(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider<SupportController>.value(
                          value: support,
                        ),
                        ChangeNotifierProvider<BookingController>(
                          create: (_) => BookingController(),
                        ),
                      ],
                      child: const HelpCenterScreen(showBackButton: true),
                    ),
                  ),
                );
              },
              child: const Text('Buka'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });
  });
}
