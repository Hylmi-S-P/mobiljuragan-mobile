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
import 'package:mobiljuragan_mobile/screens/create_ticket_screen.dart';
import 'package:provider/provider.dart';

/// Merender formulir tiket ke berkas PNG.
///
/// Emulator di mesin pengembangan sedang tidak stabil (System UI kehabisan
/// waktu berulang kali), jadi bukti visual diambil dari render Flutter langsung.
/// Hasilnya sama dengan yang dilukis aplikasi, tanpa bergantung pada perangkat.
class _Api extends TicketApiService {
  /// Menentukan apakah server menerima tiketnya.
  bool gagal = false;

  @override
  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    String? category,
  }) async {
    if (gagal) throw Exception('jaringan mati');
    return {
      'id': 'tck-srv-1',
      'ticketNumber': 'TKT-20261101-0011',
      'title': title,
      'category': category ?? 'GENERAL',
      'status': 'OPEN',
      'handledBy': 'AI',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchTicketDetail({required String ticketId}) async =>
      {'id': ticketId, 'status': 'OPEN', 'messages': <dynamic>[]};

  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async => [];
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

Future<void> _muatFont() async {
  /* Tes memakai font Ahem (kotak hitam) bila font asli belum terdaftar, jadi
     seluruh teks akan tampil sebagai balok. Font Inter didaftarkan manual supaya
     berkas PNG benar-benar memperlihatkan tulisan yang dilihat pengguna. */
  final loader = FontLoader('Inter');
  for (final berkas in [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ]) {
    loader.addFont(
      File(berkas).readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
    );
  }
  await loader.load();
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
  testWidgets('render formulir tiket', (tester) async {
    /* Memuat berkas font adalah pekerjaan nyata (I/O), jadi harus di dalam
       runAsync; kalau tidak, Future-nya menunggu selamanya di zona tes. */
    await tester.runAsync(_muatFont);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final boundaryKey = GlobalKey();
    final api = _Api()..gagal = false;

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SupportController>(
                create: (_) => SupportController(
                  aiApiService: _Ai(),
                  ticketApiService: api,
                  faqApiService: _Faq(),
                ),
              ),
              ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
            ],
            child: const CreateTicketScreen(),
          ),
        ),
      ),
    );
    /* `pumpAndSettle` tidak dipakai: layar ini memuat data lewat provider yang
       punya timer berkala, jadi "tidak ada frame tersisa" tidak pernah tercapai
       dan tes menggantung. Tiga pump cukup untuk menyelesaikan tata letak. */
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    /* `toImage` menunggu pekerjaan di luar kerangka tes. Tanpa `runAsync`,
       Future-nya tidak pernah selesai dan tesnya menggantung sampai timeout. */
    await _simpan(tester, boundaryKey, '03-form-tiket-baru.png');

    // Kondisi terisi: tombol kirim aktif dan penghitung karakter bergerak.
    await tester.enterText(find.byType(TextFormField).first, 'Sewa tiga hari, bisa jemput di bandara?');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Saya berencana menyewa Avanza lepas kunci tanggal 5 sampai 7, '
      'apakah bisa dijemput di Bandara Mopah dan dokumen apa saja yang perlu disiapkan?',
    );
    await tester.pump();
    await _simpan(tester, boundaryKey, '04-form-terisi.png');

    /* Kondisi server menolak: formulir tetap terisi, alasannya dijelaskan, dan
       tombolnya menjadi kirim ulang. */
    api.gagal = true;
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _simpan(tester, boundaryKey, '05-kirim-gagal.png');
  });
}
