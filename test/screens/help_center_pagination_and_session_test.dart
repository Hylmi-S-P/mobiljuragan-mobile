import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobiljuragan_mobile/controllers/auth_controller.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/core/network/api_client.dart';
import 'package:mobiljuragan_mobile/data/local/secure/secure_storage_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/models/support_ticket_model.dart';
import 'package:mobiljuragan_mobile/models/user_model.dart';
import 'package:mobiljuragan_mobile/screens/help_center_screen.dart';
import 'package:provider/provider.dart';

class _StubAiApi extends AiApiService {
  @override
  Future<AiChatResult> kirimPesan({
    required String pesan,
    String? ticketId,
  }) async {
    return const AiChatResult(balasan: 'Siap dibantu.', pakaiCadangan: false);
  }
}

class _StubFaqApi extends FaqApiService {
  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async {
    return [];
  }
}

class _StubTicketApi extends TicketApiService {
  _StubTicketApi(this._rawTickets);

  final List<Map<String, dynamic>> _rawTickets;

  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async {
    return _rawTickets;
  }

  @override
  Future<Map<String, dynamic>> fetchTicketDetail({
    required String ticketId,
  }) async {
    return {'id': ticketId, 'handledBy': 'AI', 'messages': []};
  }
}

class _MemorySecureStorage extends SecureStorageService {
  String? _token = 'token-uji-aktif';
  bool _wipePending = false;

  @override
  Future<String?> getAccessToken() async => _token;

  @override
  Future<bool> hasValidToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<bool> isWipePending() async => _wipePending;

  @override
  Future<void> markWipePending() async {
    _wipePending = true;
  }

  @override
  Future<void> clearWipePending() async {
    _wipePending = false;
  }

  @override
  Future<void> clearAuth() async {
    _token = null;
  }
}

void main() {
  tearDown(() {
    ApiClient.onSessionRejected = null;
    ApiClient.onUnauthorized = null;
  });

  group('HelpCenterScreen pagination dan pembersihan card tiket', () {
    testWidgets(
      'Menampilkan maksimal 3 tiket aktif per halaman dengan indikator halaman dan label bersih',
      (tester) async {
        final rawTickets = List.generate(4, (i) {
          final nomor = i + 1;
          return {
            'id': 'tck-page-$nomor',
            'ticketNumber': 'TKT-20261124-000$nomor',
            'title': 'Kendala Perjalanan $nomor',
            'category': 'COMPLAINT',
            'description': 'Deskripsi kendala perjalanan ke-$nomor',
            'status': 'OPEN',
            'handledBy': 'AI',
            'createdAt': '2026-11-24T09:00:00.000Z',
          };
        });

        final support = SupportController(
          aiApiService: _StubAiApi(),
          ticketApiService: _StubTicketApi(rawTickets),
          faqApiService: _StubFaqApi(),
        );
        final auth = AuthController();
        auth.setSessionForTest(
          user: UserModel(
            id: 'cust-1',
            name: 'Pelanggan Uji',
            phoneNumber: '081248001122',
            avatarInitials: 'PU',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthController>.value(value: auth),
                ChangeNotifierProvider<SupportController>.value(value: support),
              ],
              child: const HelpCenterScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Riwayat Tiket Selesai ›'), findsOneWidget);
        expect(find.text('Kendala Perjalanan 1'), findsOneWidget);
        expect(find.text('Kendala Perjalanan 2'), findsOneWidget);
        expect(find.text('Kendala Perjalanan 3'), findsOneWidget);
        expect(find.text('Kendala Perjalanan 4'), findsNothing);

        expect(find.text('Aktif'), findsNWidgets(3));
        expect(find.textContaining('Menunggu'), findsNothing);
        expect(find.textContaining('TKT-20261124'), findsNothing);
        expect(find.textContaining('Layanan Driver'), findsNothing);

        final pageViewFinder = find.byType(PageView);
        expect(pageViewFinder, findsOneWidget);

        await tester.drag(pageViewFinder, const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(find.text('Kendala Perjalanan 4'), findsOneWidget);
        expect(find.text('Kendala Perjalanan 1'), findsNothing);
      },
    );
  });

  group('Konversi waktu lokal pesan dan tiket', () {
    test('ChatMessageModel dan SupportTicketModel mengonversi ISO UTC ke waktu lokal', () {
      const utcIso = '2026-11-24T09:15:00.000Z';
      final msg = ChatMessageModel.fromJson({
        'id': 'msg-utc-1',
        'body': 'Halo admin',
        'isCustomer': true,
        'sentAt': utcIso,
      });
      final ticket = SupportTicketModel.fromJson({
        'id': 'tck-utc-1',
        'title': 'Cek Jam',
        'category': 'GENERAL',
        'description': 'Cek konversi jam',
        'status': 'OPEN',
        'createdAt': utcIso,
        'handoverAt': utcIso,
      });

      final expectedLocal = DateTime.parse(utcIso).toLocal();
      expect(msg.timestamp.isUtc, isFalse);
      expect(msg.timestamp, equals(expectedLocal));
      expect(ticket.createdAt.isUtc, isFalse);
      expect(ticket.createdAt, equals(expectedLocal));
      expect(ticket.handoverAt?.isUtc, isFalse);
      expect(ticket.handoverAt, equals(expectedLocal));
    });
  });

  group('Pencabutan sesi instan dan pesan akun dinonaktifkan', () {
    test('ApiClient meneruskan ACCOUNT_INACTIVE hanya untuk permintaan requiresAuth', () async {
      final storage = _MemorySecureStorage();
      final auth = AuthController(secureStorage: storage);
      auth.setSessionForTest(
        user: UserModel(
          id: 'cust-inactive-1',
          name: 'Budi',
          phoneNumber: '081248009999',
          avatarInitials: 'BD',
        ),
      );
      ApiClient.onSessionRejected = auth.tanganiSesiDitolak;

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'ACCOUNT_INACTIVE',
              'message':
                  'Akun Anda sedang dinonaktifkan oleh admin. Hubungi admin untuk bantuan.',
            },
          }),
          403,
        );
      });
      final client = ApiClient(client: mockHttp, secureStorage: storage);

      await expectLater(
        () => client.post('/auth/login/password', requiresAuth: false),
        throwsA(isA<ApiException>()),
      );
      expect(auth.isLoggedIn, isTrue);
      expect(auth.adaPesanSesiBerakhir, isFalse);

      await expectLater(
        () => client.get('/me', requiresAuth: true),
        throwsA(isA<ApiException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(auth.isLoggedIn, isFalse);
      expect(
        auth.konsumsiPesanSesiBerakhir(),
        equals('Akun Anda dinonaktifkan oleh admin. Sesi telah diakhiri.'),
      );
      expect(auth.konsumsiPesanSesiBerakhir(), isNull);
    });
  });
}
