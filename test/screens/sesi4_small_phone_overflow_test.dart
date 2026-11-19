import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/auth_controller.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/support_controller.dart';
import 'package:mobiljuragan_mobile/controllers/vehicle_controller.dart';
import 'package:mobiljuragan_mobile/data/remote/ai_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/faq_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_api_service.dart';
import 'package:mobiljuragan_mobile/models/booking_document_model.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/faq_model.dart';
import 'package:mobiljuragan_mobile/models/payment_model.dart';
import 'package:mobiljuragan_mobile/models/support_ticket_model.dart';
import 'package:mobiljuragan_mobile/screens/chat_support_screen.dart';
import 'package:mobiljuragan_mobile/screens/create_ticket_screen.dart';
import 'package:mobiljuragan_mobile/screens/date_time_screen.dart';
import 'package:mobiljuragan_mobile/screens/help_center_screen.dart';
import 'package:mobiljuragan_mobile/screens/home_screen.dart';
import 'package:mobiljuragan_mobile/screens/order_history_screen.dart';
import 'package:mobiljuragan_mobile/screens/order_review_screen.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';
import 'package:mobiljuragan_mobile/screens/profile_screen.dart';
import 'package:mobiljuragan_mobile/screens/rental_options_screen.dart';
import 'package:mobiljuragan_mobile/screens/ticket_history_screen.dart';
import 'package:mobiljuragan_mobile/screens/vehicle_detail_screen.dart';
import 'package:mobiljuragan_mobile/screens/vehicle_selection_screen.dart';
import 'package:provider/provider.dart';

import '../support/armada_uji.dart';

class _StubAiApi extends AiApiService {
  @override
  Future<AiChatResult> kirimPesan({
    required String pesan,
    String? ticketId,
  }) async => const AiChatResult(balasan: 'Siap membantu', pakaiCadangan: false);
}

class _StubTicketApi extends TicketApiService {
  @override
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async => [];

  @override
  Future<Map<String, dynamic>> fetchTicketDetail({
    required String ticketId,
  }) async => {'id': ticketId, 'handledBy': 'HUMAN', 'messages': []};
}

class _StubFaqApi extends FaqApiService {
  @override
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async => [
    FaqModel(
      id: 'faq-1',
      category: 'Persyaratan',
      question: 'Apa saja dokumen wajib untuk sewa lepas kunci di Merauke?',
      answer:
          'Wajib mengunggah e-KTP asli, SIM A aktif, dan surat pernyataan bermeterai bertanda tangan basah.',
    ),
  ];
}

void main() {
  final vehicle = armadaUji.first;

  BookingController buildBookingController({
    List<BookingModel> bookings = const [],
  }) {
    final ctrl = BookingController();
    ctrl.selectVehicle(vehicle);
    if (bookings.isNotEmpty) {
      ctrl.setBookingsForTesting(bookings);
    }
    return ctrl;
  }

  Widget wrapSmallPhone(
    Widget child, {
    required Size viewport,
    double textScale = 1.3,
    BookingController? bookingCtrl,
    SupportController? supportCtrl,
  }) {
    final bookings = bookingCtrl ?? buildBookingController();
    final support =
        supportCtrl ??
        SupportController(
          aiApiService: _StubAiApi(),
          ticketApiService: _StubTicketApi(),
          faqApiService: _StubFaqApi(),
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
        ChangeNotifierProvider<BookingController>.value(value: bookings),
        ChangeNotifierProvider<VehicleController>(
          create: (_) => VehicleController(),
        ),
        ChangeNotifierProvider<SupportController>.value(value: support),
      ],
      child: MaterialApp(
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: viewport,
            textScaler: TextScaler.linear(textScale),
          ),
          child: widget!,
        ),
        home: child,
      ),
    );
  }

  Future<void> pumpAtViewport(
    WidgetTester tester,
    Widget screen, {
    Size viewport = const Size(320, 568),
    double textScale = 1.3,
    BookingController? bookingCtrl,
    SupportController? supportCtrl,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapSmallPhone(
        screen,
        viewport: viewport,
        textScale: textScale,
        bookingCtrl: bookingCtrl,
        supportCtrl: supportCtrl,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('Sesi 4 Small Phone (320x568 @ 1.3x font) Overflow Audit', () {
    testWidgets('HomeScreen, VehicleSelectionScreen, & VehicleDetailScreen aman di 320px @ 1.3x', (tester) async {
      await pumpAtViewport(tester, const HomeScreen());
      await pumpAtViewport(tester, const VehicleSelectionScreen());
      await pumpAtViewport(tester, VehicleDetailScreen(vehicle: vehicle));
    });

    testWidgets('RentalOptionsScreen, DateTimeScreen, & OrderReviewScreen aman di 320px @ 1.3x', (tester) async {
      await pumpAtViewport(tester, RentalOptionsScreen(vehicle: vehicle));
      await pumpAtViewport(tester, DateTimeScreen(vehicle: vehicle));
      await pumpAtViewport(tester, OrderReviewScreen(vehicle: vehicle));
    });

    testWidgets('OrderHistoryScreen (aktif & semua state riwayat selesai) aman di 320px @ 1.3x', (tester) async {
      final activePay = BookingModel(
        id: 'MJ-20261119-ACTV01',
        vehicle: vehicle,
        startDate: DateTime(2026, 11, 20),
        startTime: '08.00 WIT',
        durationDays: 2,
        withDriver: true,
        pickupLocation: 'Bandara Mopah Merauke Terminal Kedatangan Domestik',
        status: BookingStatus.menungguPembayaran,
        createdAt: DateTime(2026, 11, 19),
        dailyRate: 450000,
        isFinalTariffConfirmed: true,
      );
      final refundBooking = BookingModel(
        id: 'MJ-20261115-REF004',
        vehicle: vehicle,
        startDate: DateTime(2026, 11, 15),
        startTime: '08.00 WIT',
        durationDays: 3,
        withDriver: false,
        pickupLocation: 'Kantor Operasional MobilJuragan Merauke Jl. Brawijaya',
        status: BookingStatus.dibatalkan,
        createdAt: DateTime(2026, 11, 14),
        dailyRate: 400000,
        isFinalTariffConfirmed: true,
        cancellationReason: 'Unit masuk perawatan rem mendadak sebelum keberangkatan',
        cancellationRefundAmount: 1200000,
        refundStatus: 'SELESAI',
        danaTerverifikasi: true,
        cancellationBank: 'Bank BRI',
        cancellationAccountNumber: '005401009988501',
        cancellationAccountName: 'Harun Yahya Putra Merauke',
        refundProofUrl: '/api/v1/media/proof-1',
        cancelledBy: 'ADMIN',
        cancelledAt: DateTime(2026, 11, 15),
      );
      final rejectedDocBooking = BookingModel(
        id: 'MJ-20261118-REJ01',
        vehicle: vehicle,
        startDate: DateTime(2026, 11, 22),
        startTime: '09.00 WIT',
        durationDays: 2,
        withDriver: false,
        pickupLocation: 'Pelabuhan Merauke',
        status: BookingStatus.permintaanDiterima,
        createdAt: DateTime(2026, 11, 18),
        dailyRate: 400000,
        documentStatus: 'REJECTED',
        documentRejectionReason: 'Foto SIM A buram pada masa berlaku',
      );

      final ctrl = buildBookingController(
        bookings: [activePay, rejectedDocBooking, refundBooking],
      );
      await pumpAtViewport(tester, const OrderHistoryScreen(), bookingCtrl: ctrl);

      await tester.tap(find.text('Riwayat Selesai'));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('OrderStatusScreen aman di 320px @ 1.3x untuk dokumen ditolak, menunggu bayar, E-Ticket, & batal refund', (tester) async {
      final rejectedBooking = BookingModel(
        id: 'MJ-20261118-LK01',
        vehicle: vehicle,
        startDate: DateTime(2026, 11, 21),
        startTime: '08.00 WIT',
        durationDays: 2,
        withDriver: false,
        pickupLocation: 'Bandara Mopah Merauke',
        status: BookingStatus.menungguPembayaran,
        createdAt: DateTime(2026, 11, 18),
        dailyRate: 400000,
        isFinalTariffConfirmed: true,
        documentDeadline: const DocumentDeadline(
          state: DocumentDeadlineState.berjalan,
          remainingMs: 75 * 60 * 1000,
        ),
      );
      final rejectedDoc = BookingDocumentModel(
        id: 'DOC-LK01',
        bookingId: rejectedBooking.id,
        ktpUrl: '',
        simUrl: '',
        statementLetterUrl: '',
        status: DocumentStatus.rejected,
        rejectionReason: 'Foto SIM buram dan surat belum bermeterai',
        rejectionTargets: const ['SIM', 'STATEMENT'],
        createdAt: DateTime(2026, 11, 18),
        updatedAt: DateTime(2026, 11, 18),
      );

      await pumpAtViewport(
        tester,
        OrderStatusScreen(
          booking: rejectedBooking,
          initialDocument: rejectedDoc,
          initialPayment: PaymentModel(
            id: 'PAY-LK01',
            bookingId: rejectedBooking.id,
            baseAmount: 800000,
            uniqueCode: 123,
            totalAmount: 800123,
            method: PaymentMethod.bankTransfer,
            status: PaymentStatus.pendingVerification,
            proofImageUrl: 'data:image/jpeg;base64,abc',
            createdAt: DateTime(2026, 11, 18),
          ),
        ),
      );

      final paidBooking = rejectedBooking.copyWith(
        id: 'MJ-20261119-PAID99',
        status: BookingStatus.pembayaranSelesai,
        paymentStatus: 'PAID',
      );
      await pumpAtViewport(tester, OrderStatusScreen(booking: paidBooking));

      final refundBooking = rejectedBooking.copyWith(
        id: 'MJ-20261115-CXL09',
        status: BookingStatus.dibatalkan,
        cancellationReason: 'Jadwal penerbangan berubah ke minggu berikutnya',
        cancellationRefundAmount: 750000,
        refundStatus: 'MENUNGGU',
        danaTerverifikasi: false,
        cancelledBy: 'CUSTOMER',
        cancelledAt: DateTime(2026, 11, 15),
      );
      await pumpAtViewport(tester, OrderStatusScreen(booking: refundBooking));
    });

    testWidgets('HelpCenterScreen, CreateTicketScreen, TicketHistoryScreen, ChatSupportScreen, & ProfileScreen aman di 320px @ 1.3x', (tester) async {
      await pumpAtViewport(
        tester,
        const HelpCenterScreen(showBackButton: true),
      );
      await pumpAtViewport(tester, const CreateTicketScreen());

      final supportWithFinished = SupportController(
        aiApiService: _StubAiApi(),
        ticketApiService: _StubTicketApi(),
        faqApiService: _StubFaqApi(),
      );
      await pumpAtViewport(
        tester,
        const TicketHistoryScreen(),
        supportCtrl: supportWithFinished,
      );

      final ticket = SupportTicketModel(
        id: 'tck-320',
        ticketNumber: 'TKT-20261119-0001',
        title: 'Koordinasi Penjemputan Bandara Mopah Merauke Pagi',
        category: TicketCategory.reservasi,
        description: 'Mohon koordinasi lokasi penjemputan depan pintu keluar.',
        status: 'Diproses',
        handledBy: 'HUMAN',
        createdAt: DateTime(2026, 11, 19),
      );
      await pumpAtViewport(tester, ChatSupportScreen(ticket: ticket));
      await pumpAtViewport(tester, const ProfileScreen());
    });
  });
}
