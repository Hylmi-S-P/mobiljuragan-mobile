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

  Map<String, dynamic>? detailResponse;
  int fetchDetailCount = 0;
  String? lastDetailTicketId;

  Map<String, dynamic>? closeResponse;
  int closeTicketCount = 0;
  String? lastClosedTicketId;

  FakeTicketApiService({
    this.createResponse,
    this.addMessageResponse,
    this.listResponse,
    this.detailResponse,
    this.closeResponse,
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

  @override
  Future<Map<String, dynamic>> fetchTicketDetail({required String ticketId}) async {
    fetchDetailCount++;
    lastDetailTicketId = ticketId;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return detailResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> closeTicket(String ticketId) async {
    closeTicketCount++;
    lastClosedTicketId = ticketId;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return closeResponse ??
        {
          'id': ticketId,
          'status': 'CLOSED',
        };
  }

  @override
  Future<bool> handover({required String ticketId}) async {
    return true;
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

    test('fetchTickets berhasil menyinkronkan tiket backend dan pesan percakapannya', () async {
      final fakeService = FakeTicketApiService(
        listResponse: [
          {
            'id': 'uuid-ticket-101',
            'ticketNumber': 'TKT-20261025-0001',
            'title': 'Klaim Pengembalian Deposit',
            'category': 'PAYMENT_CONFIRMATION',
            'description': 'Deposit belum kembali setelah sewa selesai.',
            'status': 'IN_PROGRESS',
            'handledBy': 'HUMAN',
            'createdAt': DateTime.now().toIso8601String(),
            'messages': [
              {
                'id': 'msg-srv-1',
                'body': 'Deposit belum kembali setelah sewa selesai.',
                'isCustomer': true,
                'sentAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
              },
              {
                'id': 'msg-srv-2',
                'body': 'Halo, tim finance kami sedang memproses transfer pengembalian dana Anda.',
                'isCustomer': false,
                'sender': {'fullName': 'Staf Keuangan Merauke'},
                'sentAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
              },
            ],
          },
        ],
      );
      final controller = SupportController(ticketApiService: fakeService);

      await controller.fetchTickets();

      expect(fakeService.fetchCount, equals(1));
      expect(controller.tickets.length, equals(1));
      final syncedTicket = controller.tickets.first;
      expect(syncedTicket.id, equals('uuid-ticket-101'));
      expect(syncedTicket.ticketNumber, equals('TKT-20261025-0001'));
      expect(syncedTicket.category, equals(TicketCategory.pembayaran));
      expect(syncedTicket.status, equals('Diproses'));
      expect(syncedTicket.isHandledByHuman, isTrue);

      final messages = controller.getMessages('ticket_uuid-ticket-101');
      expect(messages.length, equals(2));
      expect(messages.first.isFromUser, isTrue);
      expect(messages.last.senderName, equals('Staf Keuangan Merauke'));
    });

    test('refreshTicketConversation menyinkronkan balasan staf nyata dan status handover', () async {
      final fakeService = FakeTicketApiService(
        detailResponse: {
          'id': 'uuid-ticket-101',
          'status': 'RESOLVED',
          'handledBy': 'HUMAN',
          'messages': [
            {
              'id': 'msg-srv-1',
              'body': 'Kendala penjemputan Bandara Mopah.',
              'isCustomer': true,
              'sentAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            },
            {
              'id': 'msg-srv-2',
              'body': 'Driver kami sudah berada di parkir kedatangan bandara.',
              'isCustomer': false,
              'sender': {'fullName': 'Admin Lapangan'},
              'sentAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
            },
          ],
        },
      );
      final controller = SupportController(ticketApiService: fakeService);

      await controller.refreshTicketConversation('uuid-ticket-101');

      expect(fakeService.fetchDetailCount, equals(1));
      expect(fakeService.lastDetailTicketId, equals('uuid-ticket-101'));
      expect(controller.isAiHandoffToAdminFor('ticket_uuid-ticket-101'), isTrue);

      final messages = controller.getMessages('ticket_uuid-ticket-101');
      expect(messages.any((m) => m.message == 'Driver kami sudah berada di parkir kedatangan bandara.'), isTrue);
    });

    test('sendUserMessage pada tiket tidak memicu balasan tiruan admin otomatis', () async {
      final fakeService = FakeTicketApiService();
      final controller = SupportController(ticketApiService: fakeService);

      const ticketKey = 'ticket_TCK-2026-081';
      await controller.handoffToAdmin(conversationKey: ticketKey);

      final initialMessageCount = controller.getMessages(ticketKey).length;

      controller.sendUserMessage(
        text: 'Konfirmasi serah terima unit',
        conversationKey: ticketKey,
      );

      // Tunggu melebihi timer simulasi lama (900ms)
      await Future<void>.delayed(const Duration(milliseconds: 1000));

      final currentMessages = controller.getMessages(ticketKey);
      // Hanya pesan pengguna yang bertambah, tidak ada pesan tiruan admin otomatis
      expect(currentMessages.length, equals(initialMessageCount + 1));
      expect(
        currentMessages.any((m) => m.message.contains('Halo, saya staf operasional MobilJuragan Merauke')),
        isFalse,
      );
    });

    test('SupportTicketModel parseStatus memetakan RESOLVED ke Selesai dan CLOSED ke Ditutup', () {
      expect(SupportTicketModel.parseStatus('RESOLVED'), equals('Selesai'));
      expect(SupportTicketModel.parseStatus('CLOSED'), equals('Ditutup'));
      expect(SupportTicketModel.parseStatus('IN_PROGRESS'), equals('Diproses'));
      expect(SupportTicketModel.parseStatus('OPEN'), equals('Menunggu'));

      final resolvedTicket = SupportTicketModel(
        id: 't-1',
        title: 'Judul',
        category: TicketCategory.reservasi,
        description: 'Desc',
        status: 'Selesai',
        createdAt: DateTime.now(),
      );
      expect(resolvedTicket.isResolved, isTrue);
      expect(resolvedTicket.isClosed, isFalse);
      expect(resolvedTicket.isFinished, isTrue);

      final closedTicket = resolvedTicket.copyWith(status: 'Ditutup');
      expect(closedTicket.isResolved, isFalse);
      expect(closedTicket.isClosed, isTrue);
      expect(closedTicket.isFinished, isTrue);

      final activeTicket = resolvedTicket.copyWith(status: 'Diproses');
      expect(activeTicket.isFinished, isFalse);
    });

    test('closeTicket mengubah status lokal menjadi Ditutup dan menambahkan pesan sistem penutupan', () async {
      final fakeService = FakeTicketApiService();
      final controller = SupportController(ticketApiService: fakeService);

      final created = await controller.createTicket(
        title: 'Konfirmasi penjemputan',
        category: TicketCategory.reservasi,
        description: 'Serah terima di bandara',
      );
      final targetTicketId = created.id;

      final ticketBefore = controller.tickets.firstWhere((t) => t.id == targetTicketId);
      expect(ticketBefore.status, isNot(equals('Ditutup')));

      final success = await controller.closeTicket(targetTicketId);

      expect(success, isTrue);
      expect(fakeService.closeTicketCount, equals(1));
      expect(fakeService.lastClosedTicketId, equals(targetTicketId));

      final ticketAfter = controller.tickets.firstWhere((t) => t.id == targetTicketId);
      expect(ticketAfter.status, equals('Ditutup'));
      expect(ticketAfter.isClosed, isTrue);
      expect(ticketAfter.isFinished, isTrue);

      final messages = controller.getMessages('ticket_$targetTicketId');
      expect(
        messages.any((m) => m.senderName == 'Sistem' && m.message.contains('telah ditutup oleh pelanggan')),
        isTrue,
      );
    });
  });
}
