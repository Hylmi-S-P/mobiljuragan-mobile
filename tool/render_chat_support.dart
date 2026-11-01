import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/models/support_ticket_model.dart';
import 'package:mobiljuragan_mobile/screens/chat_support_screen.dart';
import 'package:provider/provider.dart';

/// Merender layar chat bantuan ke berkas PNG.
///
/// Emulator setempat sedang tidak stabil (System UI ANR berulang), jadi bukti
/// visual diambil dari render Flutter langsung dengan font Inter asli. Hasilnya
/// sama dengan yang dilukis aplikasi.
class _Api extends TicketApiService {
  @override
  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    String? category,
  }) async => {};

  /* Riwayat dikembalikan dari sini supaya layar memuat percakapan sungguhan:
     dua pesan pelanggan berurutan (membuktikan pengelompokan), lalu dua balasan
     asisten, dan satu penanda sistem. */
  @override
  Future<Map<String, dynamic>> fetchTicketDetail({required String ticketId}) async => {
        'id': ticketId,
        'status': 'OPEN',
        'handledBy': 'AI',
        'messages': [
          {
            'id': 'm1',
            'body': 'AC mobil hanya keluar angin hangat, terutama siang hari.',
            'isCustomer': true,
            'isAi': false,
            'sentAt': '2026-11-01T11:20:00.000Z',
          },
          {
            'id': 'm2',
            'body': 'Sudah saya coba putar ke tingkat paling dingin, tetap hangat.',
            'isCustomer': true,
            'isAi': false,
            'sentAt': '2026-11-01T11:21:00.000Z',
          },
          {
            'id': 'm3',
            'body': 'Terima kasih infonya. Untuk Avanza, AC yang hanya mengeluarkan '
                'angin hangat biasanya karena filter kabin kotor atau freon berkurang. '
                'Sudah pernah dibersihkan sebelumnya?',
            'isCustomer': false,
            'isAi': true,
            'sentAt': '2026-11-01T11:21:30.000Z',
          },
          {
            'id': 'm4',
            'body': 'Belum pernah. Apakah bisa diperiksa hari ini?',
            'isCustomer': true,
            'isAi': false,
            'sentAt': '2026-11-01T11:22:00.000Z',
          },
        ],
      };

  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async => [];

  /* Tanpa override ini, pengiriman pesan dan handoff memanggil jaringan
     sungguhan sehingga tes menggantung menunggu koneksi yang tidak pernah
     dijawab. */
  @override
  Future<Map<String, dynamic>> addMessage({
    required String ticketId,
    required String message,
  }) async => {'id': 'm-1', 'body': message};

  @override
  Future<bool> handover({required String ticketId}) async => true;

  @override
  Future<Map<String, dynamic>> closeTicket(String ticketId) async => {'status': 'CLOSED'};
}

class _Ai extends AiApiService {
  @override
  Future<AiChatResult> kirimPesan({required String pesan, String? ticketId}) async =>
      const AiChatResult(balasan: '', pakaiCadangan: false);
}

class _Faq extends FaqApiService {
  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async => [];
}

class _Support extends SupportController {
  _Support()
      : super(
          aiApiService: _Ai(),
          ticketApiService: _Api(),
          faqApiService: _Faq(),
        );

  @override
  Future<void> dengarkanTiket({
    required String ticketId,
    required void Function() onPesanBaru,
    void Function(String status)? onStatusBerubah,
    void Function(String galat)? onGalat,
  }) async {}

}

Future<void> _muatFont() async {
  final loader = FontLoader('Inter');
  for (final berkas in [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ]) {
    loader.addFont(File(berkas).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();

  /* Ikon akan tampil sebagai kotak kosong bila font Material Icons tidak
     didaftarkan; tes memakai font bawaan SDK Flutter, bukan aset aplikasi. */
  final ikon = FontLoader('MaterialIcons');
  ikon.addFont(
    File('C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf')
        .readAsBytes()
        .then((b) => ByteData.view(b.buffer)),
  );
  await ikon.load();
}

Future<void> _simpan(WidgetTester tester, GlobalKey key, String nama) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('../mobile-workspace/evidence/screenshots/wave-09/$nama');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render layar chat bantuan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(_muatFont);

    final support = _Support();
    final ticket = SupportTicketModel(
      id: 'tck-render-1',
      ticketNumber: 'TKT-20261101-0012',
      title: 'AC tidak dingin sejak kemarin',
      category: TicketCategory.kendaraan,
      description: 'AC hanya keluar angin hangat saat siang hari.',
      status: 'Menunggu',
      handledBy: 'AI',
      createdAt: DateTime.now(),
    );

    final key = 'ticket_${ticket.id}';
    support.sendUserMessage(
      text: 'AC mobil hanya keluar angin hangat, terutama siang hari.',
      conversationKey: key,
    );

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SupportController>.value(value: support),
              ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
            ],
            child: ChatSupportScreen(ticket: ticket),
          ),
        ),
      ),
    );

    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _simpan(tester, boundaryKey, '06-chat-ai.png');

    /* Kondisi setelah dialihkan ke staf: subjudul dan avatar header berubah,
       tanpa badge tambahan di kanan. */
    await support.handoffToAdmin(conversationKey: key);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _simpan(tester, boundaryKey, '07-chat-staf.png');
  });
}
