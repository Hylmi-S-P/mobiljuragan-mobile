import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/core/network/api_client.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';
import 'package:mobiljuragan_mobile/models/support_ticket_model.dart';

/// Test double untuk TicketApiService guna mensimulasikan respons backend tiket
class FakeTicketApiService extends TicketApiService {
  Map<String, dynamic>? createResponse;
  Map<String, dynamic>? addMessageResponse;
  List<dynamic>? listResponse;
  Exception? exceptionToThrow;

  int createTicketCount = 0;
  int addMessageCount = 0;
  int fetchCount = 0;
  String? lastCreatedTitle;
  String? lastCreatedCategory;
  String? lastAddedMessage;
  String? lastTicketId;

  FakeTicketApiService({
    this.createResponse,
    this.addMessageResponse,
    this.listResponse,
    this.exceptionToThrow,
  });

  @override
  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    String? category,
  }) async {
    createTicketCount++;
    lastCreatedTitle = title;
    lastCreatedCategory = category;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return createResponse ??
        {
          'id': 'tck-srv-999',
          'ticketNumber': 'TKT-20261022-0099',
          'title': title,
          'category': category ?? 'GENERAL',
        };
  }

  @override
  Future<Map<String, dynamic>> addMessage({
    required String ticketId,
    required String message,
  }) async {
    addMessageCount++;
    lastTicketId = ticketId;
    lastAddedMessage = message;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return addMessageResponse ??
        {
          'id': 'msg-srv-001',
          'ticketId': ticketId,
          'body': message,
          'isCustomer': true,
        };
  }

  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async {
    fetchCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return listResponse ?? [];
  }
}

void main() {
  group('SupportController Customer Ticket & Offline-First Tests', () {
    test('TicketCategory apiKey memetakan kategori Flutter ke Prisma enum backend', () {
      expect(TicketCategory.reservasi.apiKey, equals('GENERAL'));
      expect(TicketCategory.pembayaran.apiKey, equals('PAYMENT_CONFIRMATION'));
      expect(TicketCategory.kendaraan.apiKey, equals('VEHICLE_ISSUE'));
      expect(TicketCategory.layananSopir.apiKey, equals('COMPLAINT'));
      expect(TicketCategory.lainnya.apiKey, equals('OTHER'));
    });

    test('createTicket mengirim apiKey ke backend dan memperbarui ID dari server', () async {
      final fakeService = FakeTicketApiService();
      final controller = SupportController(ticketApiService: fakeService);

      final initialLength = controller.tickets.length;

      await controller.createTicket(
        title: 'Penjemputan Bandara',
        category: TicketCategory.reservasi,
        description: 'Mohon jemput di Gate Kedatangan',
      );

      expect(fakeService.createTicketCount, equals(1));
      expect(fakeService.lastCreatedTitle, equals('Penjemputan Bandara'));
      // Kategori yang dikirim adalah apiKey kanonik backend
      expect(fakeService.lastCreatedCategory, equals('GENERAL'));

      expect(controller.tickets.length, equals(initialLength + 1));
      final createdTicket = controller.tickets.first;
      expect(createdTicket.id, equals('tck-srv-999'));
      expect(createdTicket.title, contains('TKT-20261022-0099'));
    });

    test('createTicket tahan terhadap galat offline tanpa melempar exception crash', () async {
      final fakeService = FakeTicketApiService(
        exceptionToThrow: ApiException('Server tidak dapat dijangkau (Offline).', statusCode: 503),
      );
      final controller = SupportController(ticketApiService: fakeService);

      final initialLength = controller.tickets.length;

      await controller.createTicket(
        title: 'Kendala AC Panas',
        category: TicketCategory.kendaraan,
        description: 'AC mobil kurang dingin saat siang hari',
      );

      expect(fakeService.createTicketCount, equals(1));
      // Tiket tetap tersimpan secara lokal di controller (offline-first)
      expect(controller.tickets.length, equals(initialLength + 1));
      final fallbackTicket = controller.tickets.first;
      expect(fallbackTicket.id, startsWith('TCK-2026-'));
    });

    test('sendUserMessage pada thread tiket mengirim pesan ke REST backend', () async {
      final fakeService = FakeTicketApiService();
      final controller = SupportController(ticketApiService: fakeService);

      const ticketKey = 'ticket_TCK-2026-081';

      controller.sendUserMessage(
        text: 'Halo, apakah supir sudah standby?',
        conversationKey: ticketKey,
      );

      // Pastikan pesan lokal masuk
      final msgs = controller.getMessages(ticketKey);
      expect(msgs.any((m) => m.message == 'Halo, apakah supir sudah standby?'), isTrue);

      // Beri sedikit jeda mikrotask untuk unawaited API call
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakeService.addMessageCount, equals(1));
      expect(fakeService.lastTicketId, equals('TCK-2026-081'));
      expect(fakeService.lastAddedMessage, equals('Halo, apakah supir sudah standby?'));
    });
  });
}
