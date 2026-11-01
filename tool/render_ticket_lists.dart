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
import 'package:mobiljuragan_mobile/screens/help_center_screen.dart';
import 'package:mobiljuragan_mobile/screens/ticket_history_screen.dart';
import 'package:provider/provider.dart';

/// Merender daftar tiket (Beranda bantuan dan Riwayat) ke berkas PNG.
///
/// Emulator setempat sedang tidak stabil, jadi bukti visual diambil dari render
/// Flutter langsung dengan font Inter + Material Icons asli.
class _Api extends TicketApiService {
  _Api(this.tiket);
  final List<Map<String, dynamic>> tiket;

  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async => tiket;

  @override
  Future<Map<String, dynamic>> fetchTicketDetail({required String ticketId}) async =>
      {'id': ticketId, 'status': 'OPEN', 'handledBy': 'AI', 'messages': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    String? category,
  }) async => {};
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
  _Support(List<Map<String, dynamic>> tiket)
      : super(
          aiApiService: _Ai(),
          ticketApiService: _Api(tiket),
          faqApiService: _Faq(),
        );

  @override
  Future<void> dengarkanTiket({
    required String ticketId,
    required void Function() onPesanBaru,
    void Function(String status)? onStatusBerubah,
    void Function(String galat)? onGalat,
  }) async {}

  @override
  Future<void> muatRiwayatTiket({required String ticketId}) async {}
}

Future<void> _muatFont() async {
  final inter = FontLoader('Inter');
  for (final berkas in [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ]) {
    inter.addFont(File(berkas).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await inter.load();

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

Map<String, dynamic> _tiket(String nomor, String judul, String status, {int pesan = 3}) => {
      'id': 'id-$nomor',
      'ticketNumber': nomor,
      'title': judul,
      'category': 'VEHICLE_ISSUE',
      'description': 'Deskripsi $judul',
      'status': status,
      'handledBy': 'AI',
      'createdAt': '2026-11-01T08:00:00.000Z',
      'updatedAt': '2026-11-01T09:00:00.000Z',
      '_count': {'messages': pesan},
    };

void main() {
  /* Satu tiket aktif, satu berstatus RESOLVED, satu CLOSED. Dulu ketiganya
     memakai label berbeda untuk dua keadaan akhir yang sama. */
  final data = [
    _tiket('TKT-20261101-0008', 'Cek tarif sewa tiga hari', 'OPEN'),
    _tiket('TKT-20261101-0002', 'Uji RESOLVED', 'RESOLVED'),
    _tiket('TKT-20261101-0001', 'Uji guard tiket', 'CLOSED'),
  ];

  testWidgets('render daftar tiket dan riwayat', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(_muatFont);

    final support = _Support(data);
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
            child: const TicketHistoryScreen(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _simpan(tester, boundaryKey, '08-riwayat-satu-status.png');

    // Beranda bantuan: yang muncul hanya tiket yang masih menerima pesan.
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SupportController>.value(value: _Support(data)),
              ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
            ],
            child: const HelpCenterScreen(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _simpan(tester, boundaryKey, '09-beranda-hanya-aktif.png');
  });
}
