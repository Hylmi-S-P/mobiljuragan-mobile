import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/models/support_ticket_model.dart';
import 'package:mobiljuragan_mobile/screens/chat_support_screen.dart';
import 'package:mobiljuragan_mobile/screens/help_center_screen.dart';
import 'package:provider/provider.dart';

class MockAiApiService extends AiApiService {
  int kirimPesanCount = 0;
  String? lastPesan;
  String? lastTicketId;
  String replyText;

  MockAiApiService({this.replyText = 'Halo! Saya asisten AI resmi MobilJuragan. Kendala Anda sedang kami proses.'});

  @override
  Future<AiChatResult> kirimPesan({
    required String pesan,
    String? ticketId,
  }) async {
    kirimPesanCount++;
    lastPesan = pesan;
    lastTicketId = ticketId;
    return AiChatResult(balasan: replyText, pakaiCadangan: false);
  }
}

class MockTicketApiService extends TicketApiService {
  int createTicketCount = 0;
  int handoverCount = 0;
  String? lastHandoverTicketId;

  @override
  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    String? category,
  }) async {
    createTicketCount++;
    return {
      'id': 'tck-test-101',
      'ticketNumber': 'TKT-20261026-0001',
      'title': title,
      'category': category ?? 'GENERAL',
      'handledBy': 'AI',
      'status': 'OPEN',
    };
  }

  @override
  Future<bool> handoverTicket(String ticketId) async {
    handoverCount++;
    lastHandoverTicketId = ticketId;
    return true;
  }

  @override
  Future<Map<String, dynamic>> addMessage({
    required String ticketId,
    required String message,
  }) async {
    return {
      'id': 'msg-mock-1',
      'ticketId': ticketId,
      'body': message,
      'senderRole': 'CUSTOMER',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchTicketDetail({required String ticketId}) async {
    return {
      'id': ticketId,
      'handledBy': 'AI',
      'messages': [],
    };
  }

  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async {
    return [];
  }
}

class MockFaqApiService extends FaqApiService {
  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async => [];
}

class MockSupportControllerForChat extends SupportController {
  MockSupportControllerForChat({
    required super.aiApiService,
    required super.ticketApiService,
    required super.faqApiService,
  });

  @override
  Future<void> dengarkanTiket({
    required String ticketId,
    required void Function() onPesanBaru,
    void Function(String status)? onStatusBerubah,
    void Function(String pesan)? onGalat,
  }) async {
    // Hindari sambungan socket SSE riil pada widget test
  }

  @override
  Future<void> muatRiwayatTiket({required String ticketId}) async {
    // Hindari panggilan fetch jaringan riil pada widget test
  }
}

void main() {
  group('HelpCenterScreen - Pemusatan Tiket Bantuan Tests', () {
    testWidgets('Merender kartu Buat Tiket Bantuan dan tidak menampilkan Tanya Cepat', (tester) async {
      final mockAi = MockAiApiService();
      final mockTicket = MockTicketApiService();
      final mockFaq = MockFaqApiService();

      final supportController = SupportController(
        aiApiService: mockAi,
        ticketApiService: mockTicket,
        faqApiService: mockFaq,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SupportController>.value(value: supportController),
              ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
            ],
            child: const HelpCenterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan kartu Buat Tiket Bantuan ada
      expect(find.text('Buat Tiket Bantuan'), findsOneWidget);
      expect(find.text('Respon AI'), findsOneWidget);

      // Memastikan aksi lama Tanya Cepat tidak ada
      expect(find.text('Tanya Cepat'), findsNothing);
      expect(find.text('Panggil Staf'), findsNothing);
    });
  });

  group('SupportController - Tiket AI & Retensi Auto-Handoff Tests', () {
    test('createTicket menginisialisasi handledBy = AI dan memicu respon otomatis pertama', () async {
      final mockAi = MockAiApiService(replyText: 'Solusi awal untuk armada Innova: periksa tekanan ban.');
      final mockTicket = MockTicketApiService();
      final mockFaq = MockFaqApiService();

      final supportController = SupportController(
        aiApiService: mockAi,
        ticketApiService: mockTicket,
        faqApiService: mockFaq,
      );

      final ticket = await supportController.createTicket(
        title: 'Ban Kempes',
        category: TicketCategory.kendaraan,
        description: 'Ban belakang kiri kempes di Bandara Mopah',
      );

      expect(ticket.handledBy, equals('AI'));
      expect(ticket.isHandledByHuman, isFalse);

      final ticketKey = 'ticket_${ticket.id}';
      expect(supportController.isAiHandoffToAdminFor(ticketKey), isFalse);

      // Tunggu inisialisasi AI asinkron
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(mockAi.kirimPesanCount, greaterThanOrEqualTo(1));
      final messages = supportController.getMessages(ticketKey);
      expect(messages.any((m) => m.isAI), isTrue);
    });

    test('Eskalasi otomatis terpicu saat putaran percakapan mencapai ambang batas retensi', () async {
      final mockAi = MockAiApiService();
      final mockTicket = MockTicketApiService();
      final mockFaq = MockFaqApiService();

      final supportController = SupportController(
        aiApiService: mockAi,
        ticketApiService: mockTicket,
        faqApiService: mockFaq,
      );

      final ticket = await supportController.createTicket(
        title: 'AC Tidak Dingin',
        category: TicketCategory.kendaraan,
        description: 'AC kabin mobil panas',
      );

      final ticketKey = 'ticket_${ticket.id}';
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Putaran 1 sudah selesai pada inisialisasi tiket
      expect(supportController.getTicketTurnCount(ticketKey), equals(1));
      expect(supportController.isAiHandoffToAdminFor(ticketKey), isFalse);

      // Kirim pesan ke-2
      supportController.sendUserMessage(text: 'Sudah saya coba atur suhunya tetap panas', conversationKey: ticketKey);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(supportController.getTicketTurnCount(ticketKey), equals(2));
      expect(supportController.isAiHandoffToAdminFor(ticketKey), isFalse);

      // Kirim pesan ke-3 (mencapai batas retensi default = 3)
      supportController.sendUserMessage(text: 'Masih belum dingin juga', conversationKey: ticketKey);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(supportController.getTicketTurnCount(ticketKey), equals(3));

      // Harus otomatis memicu handover ke staf
      expect(mockTicket.handoverCount, greaterThanOrEqualTo(1));
      expect(supportController.isAiHandoffToAdminFor(ticketKey), isTrue);
    });
  });

  group('ChatSupportScreen - UI Verifikasi & Tanpa Tombol Panggil Staf Manual', () {
    testWidgets('Tidak menampilkan tombol Panggil Staf di AppBar dan menampilkan kartu prompt retensi', (tester) async {
      final mockAi = MockAiApiService();
      final mockTicket = MockTicketApiService();
      final mockFaq = MockFaqApiService();

      final supportController = MockSupportControllerForChat(
        aiApiService: mockAi,
        ticketApiService: mockTicket,
        faqApiService: mockFaq,
      );

      final ticket = SupportTicketModel(
        id: 'tck-ui-test',
        ticketNumber: 'TKT-20261026-0002',
        title: 'Kunci Tertinggal',
        category: TicketCategory.kendaraan,
        description: 'Kunci mobil tertinggal di dalam',
        status: 'Menunggu',
        handledBy: 'AI',
        createdAt: DateTime.now(),
      );

      // Simulasikan pesan awal dari user dan AI
      final ticketKey = 'ticket_${ticket.id}';
      supportController.sendUserMessage(text: 'Kunci mobil tertinggal', conversationKey: ticketKey);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SupportController>.value(value: supportController),
              ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
            ],
            child: ChatSupportScreen(ticket: ticket),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Pastikan tombol manual "Panggil Staf" TIDAK ADA di AppBar
      expect(find.widgetWithText(OutlinedButton, 'Panggil Staf'), findsNothing);

      // Pastikan status penanganan AI ditampilkan
      expect(find.text('Asisten AI'), findsOneWidget);

      // Pastikan kartu prompt retensi muncul
      expect(find.text('Apakah solusi AI membantu kendala Anda?'), findsOneWidget);
      expect(find.text('Teratasi'), findsOneWidget);
      expect(find.text('Minta Staf'), findsOneWidget);
    });
  });
}
