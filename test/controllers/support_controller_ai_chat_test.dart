import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_chat_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';

class FakeAiChatApiService extends AiChatApiService {
  String? returnReply;
  Exception? exceptionToThrow;
  int callCount = 0;
  String? lastMessage;
  List<Map<String, String>>? lastHistory;

  FakeAiChatApiService({this.returnReply, this.exceptionToThrow});

  @override
  Future<String?> sendChat({
    required String message,
    List<Map<String, String>>? history,
  }) async {
    callCount++;
    lastMessage = message;
    lastHistory = history;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return returnReply;
  }
}

class FakeTicketApiService extends TicketApiService {
  int handoverCount = 0;
  String? lastHandoverTicketId;

  @override
  Future<bool> handoverTicket(String ticketId) async {
    handoverCount++;
    lastHandoverTicketId = ticketId;
    return true;
  }
}

void main() {
  group('SupportController AI Chat & Handover Tests', () {
    test('sendUserMessage pada obrolan umum memanggil AiChatApiService dan menambahkan balasan AI', () async {
      final fakeAi = FakeAiChatApiService(
        returnReply: 'Armada Innova Reborn tersedia untuk rute Merauke ke Sota seharga Rp 650.000 per hari.',
      );
      final controller = SupportController(aiChatApiService: fakeAi);

      controller.sendUserMessage(text: 'Apakah Innova tersedia besok?');

      // Tunggu Future asinkron selesai
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakeAi.callCount, equals(1));
      expect(fakeAi.lastMessage, equals('Apakah Innova tersedia besok?'));

      final messages = controller.getMessages('general');
      expect(messages.length, greaterThanOrEqualTo(2));
      final lastMsg = messages.last;
      expect(lastMsg.isFromUser, isFalse);
      expect(lastMsg.isAI, isTrue);
      expect(lastMsg.senderName, equals('Asisten AI MobilJuragan'));
      expect(lastMsg.message, contains('Innova Reborn'));
    });

    test('sendUserMessage tahan terhadap galat AI gateway dengan balasan fallback ramah', () async {
      final fakeAi = FakeAiChatApiService(
        exceptionToThrow: Exception('Gateway timeout'),
      );
      final controller = SupportController(aiChatApiService: fakeAi);

      controller.sendUserMessage(text: 'Berapa tarif Avanza?');

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakeAi.callCount, equals(1));
      final messages = controller.getMessages('general');
      final lastMsg = messages.last;
      expect(lastMsg.isFromUser, isFalse);
      expect(lastMsg.isAI, isTrue);
      expect(lastMsg.message, contains('Asisten AI'));
    });

    test('handoffToAdmin pada tiket memanggil TicketApiService.handoverTicket', () async {
      final fakeTicket = FakeTicketApiService();
      final controller = SupportController(ticketApiService: fakeTicket);

      controller.handoffToAdmin(conversationKey: 'ticket_TCK-2026-081');

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakeTicket.handoverCount, equals(1));
      expect(fakeTicket.lastHandoverTicketId, equals('TCK-2026-081'));
      expect(controller.isAiHandoffToAdminFor('ticket_TCK-2026-081'), isTrue);
    });
  });
}
