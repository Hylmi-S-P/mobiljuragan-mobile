import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/screens/create_ticket_screen.dart';
import 'package:provider/provider.dart';

class _TicketApi extends TicketApiService {
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
      'ticketNumber': 'TKT-20261101-0007',
      'title': title,
      'category': category ?? 'GENERAL',
      'status': 'OPEN',
      'handledBy': 'AI',
    };
  }

  @override
  Future<Map<String, dynamic>> fetchTicketDetail({required String ticketId}) async {
    return {'id': ticketId, 'handledBy': 'AI', 'status': 'OPEN', 'messages': <dynamic>[]};
  }

  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async => [];
}

class _AiApi extends AiApiService {
  @override
  Future<AiChatResult> kirimPesan({required String pesan, String? ticketId}) async {
    return const AiChatResult(balasan: '', pakaiCadangan: false);
  }
}

class _FaqApi extends FaqApiService {
  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async => [];
}

class _Support extends SupportController {
  _Support(TicketApiService api)
      : super(
          aiApiService: _AiApi(),
          ticketApiService: api,
          faqApiService: _FaqApi(),
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

/// Tombol kirim berada di ujung daftar, jadi harus digulir dulu. `ListView`
/// tidak membangun anak di luar layar, sehingga `find.byType` tidak menemukannya
/// sebelum gulir.
Future<ElevatedButton> _scrollToSubmit(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.byType(ElevatedButton), 300, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  return tester.widget<ElevatedButton>(find.byType(ElevatedButton));
}

Future<void> _pumpForm(WidgetTester tester, SupportController support) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<SupportController>.value(value: support),
          ChangeNotifierProvider<BookingController>(create: (_) => BookingController()),
        ],
        child: const CreateTicketScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Formulir tiket bantuan', () {
    testWidgets('tidak lagi meminta nomor booking, armada, atau lampiran foto', (tester) async {
      final api = _TicketApi();
      await _pumpForm(tester, _Support(api));

      /* Ketiga isian itu dihapus, bukan disembunyikan: pertanyaan pra-sewa tidak
         punya nomor booking, dan lampiran dulu hanya menyimpan nama berkas
         karangan tanpa ada gambar yang benar-benar terkirim. */
      expect(find.textContaining('Nomor Booking'), findsNothing);
      expect(find.textContaining('Armada Aktif'), findsNothing);
      expect(find.textContaining('Lampiran'), findsNothing);
      expect(find.textContaining('Lampirkan'), findsNothing);

      // Badge dukungan cepat dan kalimat penutup juga diminta hilang.
      expect(find.textContaining('Dukungan Cepat'), findsNothing);
      expect(find.textContaining('terhubung langsung'), findsNothing);
    });

    testWidgets('deskripsi tidak lagi mengklaim hanya untuk masa sewa', (tester) async {
      final api = _TicketApi();
      await _pumpForm(tester, _Support(api));

      expect(find.textContaining('selama masa sewa'), findsNothing);
      expect(find.textContaining('belum dipesan'), findsOneWidget);
    });

    testWidgets('judul dan detail punya batas karakter yang terlihat', (tester) async {
      final api = _TicketApi();
      await _pumpForm(tester, _Support(api));

      expect(find.text('0/100'), findsOneWidget);
      expect(find.text('0/2000'), findsOneWidget);

      /* InputFormatter memotong ketikan, jadi penghitung tidak akan pernah
         melewati batas yang sama dengan yang diperiksa server. */
      await tester.enterText(find.byType(TextFormField).first, 'a' * 130);
      await tester.pump();

      final titleField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(titleField.controller!.text.length, 100);
      expect(find.text('100/100'), findsOneWidget);
    });

    testWidgets('tombol kirim terkunci selama judul masih kosong', (tester) async {
      final api = _TicketApi();
      await _pumpForm(tester, _Support(api));

      expect((await _scrollToSubmit(tester)).onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'Minta jemput di bandara');
      await tester.pump();

      expect((await _scrollToSubmit(tester)).onPressed, isNotNull);
    });

    testWidgets('deskripsi terlalu pendek ditolak validasi, bukan dikirim', (tester) async {
      final api = _TicketApi();
      await _pumpForm(tester, _Support(api));

      await tester.enterText(find.byType(TextFormField).first, 'Minta jemput di bandara');
      await tester.enterText(find.byType(TextFormField).last, 'halo');
      await tester.pump();

      final tombol = await _scrollToSubmit(tester);
      expect(tombol.onPressed, isNotNull);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('terlalu pendek'), findsOneWidget);
    });

    testWidgets('kirim gagal: formulir tetap terisi dan alasan kegagalan dijelaskan', (tester) async {
      final api = _TicketApi()..gagal = true;
      final support = _Support(api);
      await _pumpForm(tester, support);

      await tester.enterText(find.byType(TextFormField).first, 'Minta jemput di bandara');
      await tester.enterText(
        find.byType(TextFormField).last,
        'Saya mendarat jam 9 pagi, mohon dijemput di lobi kedatangan.',
      );
      await tester.pump();

      await _scrollToSubmit(tester);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      /* Dulu kegagalan ditelan: layar langsung pindah ke ruang obrolan untuk tiket
         yang tidak ada di database. Sekarang pelanggan tetap di formulir, isian
         tidak hilang, dan tombolnya berubah jadi kirim ulang. */
      expect(find.byType(CreateTicketScreen), findsOneWidget);
      expect(find.textContaining('belum terkirim'), findsOneWidget);

      // Tombolnya berganti jadi kirim ulang, dan isian judul tidak dikosongkan.
      final tombol = await _scrollToSubmit(tester);
      expect(tombol.onPressed, isNotNull);
      expect(find.text('Kirim Ulang'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byType(TextFormField).first,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Minta jemput di bandara'), findsOneWidget);

      // Tidak ada tiket palsu yang tertinggal di daftar.
      expect(support.tickets, isEmpty);
    });
  });
}
