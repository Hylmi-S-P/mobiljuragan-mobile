import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobiljuragan_mobile/core/network/api_client.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/data/local/secure/secure_storage_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_chat_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';

class _TestSecureStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'token-uji';
}

class _DirectMapApiClient extends ApiClient {
  final Map<String, dynamic> stubResponse;

  _DirectMapApiClient(this.stubResponse)
      : super(client: MockClient((_) async => http.Response('{}', 200)), secureStorage: _TestSecureStorage());

  @override
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    return stubResponse;
  }
}

class _ThrowingAiApiService extends AiApiService {
  final Object errorToThrow;
  int callCount = 0;

  _ThrowingAiApiService(this.errorToThrow);

  @override
  Future<AiChatResult> kirimPesan({
    required String pesan,
    String? ticketId,
  }) async {
    callCount++;
    throw errorToThrow;
  }
}

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

    test('AiApiService.kirimPesan mem-parsing ticketHandedOver dari payload unwrapped dan wrapped', () async {
      final mockUnwrappedHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'reply': 'Baik, saya teruskan ke admin operasional sekarang.',
              'fallback': false,
              'ticketHandedOver': true,
            },
          }),
          200,
        );
      });
      final serviceUnwrapped = AiApiService(
        ApiClient(client: mockUnwrappedHttp, secureStorage: _TestSecureStorage()),
      );
      final hasilUnwrapped = await serviceUnwrapped.kirimPesan(
        pesan: 'Saya mau bicara dengan admin manusia',
        ticketId: 'tck-100',
      );
      expect(hasilUnwrapped.balasan, equals('Baik, saya teruskan ke admin operasional sekarang.'));
      expect(hasilUnwrapped.dialihkanKeAdmin, isTrue);

      final serviceWrapped = AiApiService(
        _DirectMapApiClient({
          'data': {
            'reply': 'Permintaan pengalihan sedang diproses.',
            'fallback': false,
            'ticketHandedOver': true,
          },
        }),
      );
      final hasilWrapped = await serviceWrapped.kirimPesan(
        pesan: 'Tolong sambungkan admin',
        ticketId: 'tck-100',
      );
      expect(hasilWrapped.balasan, equals('Permintaan pengalihan sedang diproses.'));
      expect(hasilWrapped.dialihkanKeAdmin, isTrue);

      final mockDefaultHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'reply': 'Silakan cek jam operasional kami.',
              'fallback': false,
            },
          }),
          200,
        );
      });
      final serviceDefault = AiApiService(
        ApiClient(client: mockDefaultHttp, secureStorage: _TestSecureStorage()),
      );
      final hasilDefault = await serviceDefault.kirimPesan(
        pesan: 'Jam buka kapan?',
        ticketId: 'tck-100',
      );
      expect(hasilDefault.dialihkanKeAdmin, isFalse);
    });

    test('Saat server membalas 409 TICKET_HANDED_OVER, SupportController mengunci handoff tanpa bubble error palsu', () async {
      final throwingAi = _ThrowingAiApiService(
        ApiException(
          'Tiket sudah ditangani admin',
          statusCode: 409,
          details: {
            'error': {'code': 'TICKET_HANDED_OVER'},
          },
        ),
      );
      final controller = SupportController(aiApiService: throwingAi);
      const key = 'ticket_tck-409-test';

      controller.sendUserMessage(
        text: 'Halo apakah ada admin?',
        conversationKey: key,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(throwingAi.callCount, equals(1));
      expect(controller.isAiHandoffToAdminFor(key), isTrue);

      final messages = controller.getMessages(key);
      expect(messages.length, equals(1));
      expect(messages.single.isFromUser, isTrue);
      expect(messages.single.message, equals('Halo apakah ada admin?'));
    });
  });
}
