import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_document_model.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/payment_model.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';
import 'package:mobiljuragan_mobile/theme/app_colors.dart';

void main() {
  Widget createTestWidget({
    required BookingModel booking,
    BookingDocumentModel? initialDocument,
    PaymentModel? initialPayment,
  }) {
    return ChangeNotifierProvider<BookingController>(
      create: (_) => BookingController(),
      child: MaterialApp(
        home: OrderStatusScreen(
          booking: booking,
          initialDocument: initialDocument,
          initialPayment: initialPayment,
        ),
      ),
    );
  }

  final completedBooking = BookingModel(
    id: 'MJ-TEST-COMPLETED',
    vehicle: VehicleModel.sampleVehicles.first,
    startDate: DateTime(2026, 10, 20),
    startTime: '09.00 WIT',
    durationDays: 3,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.selesai,
    createdAt: DateTime(2026, 10, 19),
    dailyRate: 450000,
    isFinalTariffConfirmed: true,
  );

  final inProgressBooking = BookingModel(
    id: 'MJ-TEST-INPROGRESS',
    vehicle: VehicleModel.sampleVehicles.first,
    startDate: DateTime(2026, 10, 20),
    startTime: '09.00 WIT',
    durationDays: 3,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.mobilSiapDigunakan,
    createdAt: DateTime(2026, 10, 19),
    dailyRate: 450000,
    isFinalTariffConfirmed: true,
  );

  group('OrderStatusScreen Completion UI Tests', () {
    testWidgets('Merender banner Sewa Selesai dan tombol Kembali ke Beranda saat booking selesai', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: completedBooking));
      await tester.pumpAndSettle();

      // Banner Penyewaan Selesai
      expect(find.text('Penyewaan Selesai'), findsOneWidget);
      expect(find.text('TUNTAS'), findsOneWidget);

      // Badge SELESAI pada tahapan ke-5
      expect(find.text('SELESAI'), findsAtLeastNWidgets(1));

      // Tombol aksi utama Kembali ke Beranda
      expect(find.text('Kembali ke Beranda'), findsOneWidget);

      // Tidak menampilkan tombol batalkan
      expect(find.text('Batalkan Pesanan Ini'), findsNothing);
      expect(find.text('Ajukan Pembatalan & Refund'), findsNothing);
    });

    testWidgets('Merender status Sewa Berjalan dan aksi koordinasi saat masa sewa aktif', (tester) async {
      await tester.pumpWidget(createTestWidget(booking: inProgressBooking));
      await tester.pumpAndSettle();

      // Status sewa aktif
      expect(find.text('Sewa Berjalan'), findsAtLeastNWidgets(1));
      expect(find.text('Penyewaan Selesai'), findsNothing);

      // E-Ticket Reservasi tampil dengan format resmi
      expect(find.text('E-TICKET RESERVASI MOBILJURAGAN'), findsOneWidget);

      // Stepper menampilkan seluruh tahapan proses pesanan secara terbuka (tanpa toggle riwayat)
      expect(find.text('Tahapan Proses Pesanan'), findsOneWidget);
      expect(find.text('Permintaan Masuk'), findsOneWidget);
      expect(find.text('Konfirmasi Tarif & Armada'), findsOneWidget);
      expect(find.text('Pembayaran Diterima'), findsOneWidget);
      expect(find.text('Sewa Berjalan'), findsAtLeastNWidgets(1));
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Lihat riwayat ▼'), findsNothing);
      expect(find.text('Tutup riwayat ▲'), findsNothing);

      // Tombol koordinasi tim lapangan
      expect(find.text('Koordinasi Penjemputan via Chat CS'), findsOneWidget);

      // Tombol pembatalan diubah menjadi tautan bantuan elegan, bukan tombol merah mencolok
      expect(find.text('Butuh bantuan pembatalan atau perubahan jadwal? Ajukan di sini'), findsOneWidget);
      expect(find.text('Batalkan Pesanan Ini'), findsNothing);
    });

    testWidgets('Merender ringkasan unit dan tombol batalkan saat status belum lunas / baru diajukan', (tester) async {
      final requestedBooking = inProgressBooking.copyWith(
        status: BookingStatus.permintaanDiterima,
        isFinalTariffConfirmed: false,
        withDriver: true,
      );

      await tester.pumpWidget(createTestWidget(booking: requestedBooking));
      await tester.pumpAndSettle();

      // Unified Hero Card berada di bagian atas dengan judul peninjauan admin untuk layanan bersupir
      expect(find.text('Pengajuan Sedang Ditinjau Admin'), findsOneWidget);
      expect(find.text('Formulir pengajuan sewa berhasil dikirim'), findsOneWidget);

      // Kartu ringkasan unit tetap muncul saat belum lunas dengan estimasi biaya
      expect(find.text('Estimasi Total Biaya'), findsOneWidget);

      // Tombol pembatalan berupa teks link Batalkan Pengajuan Sewa Ini (bukan tombol merah raksasa)
      expect(find.text('Batalkan Pengajuan Sewa Ini'), findsOneWidget);
      expect(find.text('Periksa Status Terbaru'), findsNothing);
      expect(find.text('Kembali ke Beranda'), findsNothing);
    });

    testWidgets('Merender kartu Menunggu Pembayaran di atas dengan tombol Bayar Sekarang pada Tahap 3', (tester) async {
      final waitingPaymentBooking = inProgressBooking.copyWith(
        status: BookingStatus.menungguPembayaran,
        isFinalTariffConfirmed: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(booking: waitingPaymentBooking));
      await tester.pumpAndSettle();

      // Unified Hero Card menampilkan ajakan pembayaran, kode reservasi utuh, dan rincian tarif
      expect(find.text('Selesaikan Pembayaran'), findsOneWidget);
      expect(find.text(waitingPaymentBooking.id), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsAtLeastNWidgets(1));
      expect(find.text('Total Pembayaran'), findsAtLeastNWidgets(1));
      expect(find.text('Lihat Rincian Tarif'), findsOneWidget);

      // Tombol Bayar Sekarang bersih tanpa mengulang nominal harga di label
      expect(find.text('Bayar Sekarang'), findsOneWidget);

      // Stepper menampilkan batas waktu pelunasan
      expect(find.text('Batas pelunasan hingga 12 jam ke depan'), findsOneWidget);

      // Tombol bawah: Butuh Bantuan? Chat CS MobilJuragan dan Batalkan Pengajuan Sewa Ini
      expect(find.text('Butuh Bantuan? Chat CS MobilJuragan'), findsOneWidget);
      expect(find.text('Batalkan Pengajuan Sewa Ini'), findsOneWidget);
      expect(find.text('Periksa Status Terbaru'), findsNothing);
      expect(find.text('Kembali ke Beranda'), findsNothing);
    });

    testWidgets('Tidak menampilkan card supir saat status permintaanDiterima (Tahap 1), dan menampilkannya setelah dikonfirmasi (Tahap 2 atau 3)', (tester) async {
      final driverBookingTahap1 = inProgressBooking.copyWith(
        withDriver: true,
        status: BookingStatus.permintaanDiterima,
        isFinalTariffConfirmed: false,
      );

      await tester.pumpWidget(createTestWidget(booking: driverBookingTahap1));
      await tester.pumpAndSettle();

      // Card supir tidak boleh muncul pada Tahap 1
      expect(find.text('Pengemudi Anda'), findsNothing);

      final driverBookingTahap3 = inProgressBooking.copyWith(
        withDriver: true,
        status: BookingStatus.menungguPembayaran,
        isFinalTariffConfirmed: true,
      );

      await tester.pumpWidget(createTestWidget(booking: driverBookingTahap3));
      await tester.pumpAndSettle();

      // Card supir muncul pada Tahap 3 (setelah diterima atau dikonfirmasi)
      expect(find.text('Pengemudi Anda'), findsOneWidget);
    });

    testWidgets('Merender Card Kelengkapan Dokumen Wajib Lepas Kunci dengan 3 berkas saat withDriver false', (tester) async {
      final lepasKunciBooking = inProgressBooking.copyWith(
        withDriver: false,
        status: BookingStatus.menungguPembayaran,
      );

      await tester.pumpWidget(createTestWidget(booking: lepasKunciBooking));
      await tester.pumpAndSettle();

      // Memastikan kartu dokumen wajib lepas kunci muncul di posisi atas
      expect(find.text('Dokumen Wajib Lepas Kunci'), findsOneWidget);
      expect(find.text('1. Foto e-KTP Asli'), findsOneWidget);
      expect(find.text('2. Foto SIM A Aktif'), findsOneWidget);
      expect(find.text('3. Surat Pernyataan Penyewa'), findsOneWidget);
      expect(find.text('Unduh PDF'), findsOneWidget);
      expect(find.text('Unggah TTD'), findsOneWidget);

      // Memastikan catatan ketiadaan printer telah dihapus dan diganti catatan syarat resmi
      expect(find.textContaining('Tidak ada akses printer'), findsNothing);
      expect(find.textContaining('Wajib dilengkapi sebelum serah terima unit di lokasi'), findsOneWidget);
    });

    testWidgets('Menampilkan kode serah terima dan QR code aktif pada E-Ticket saat pembayaran lunas tanpa banner terkunci', (tester) async {
      final activeLepasKunciBooking = inProgressBooking.copyWith(
        withDriver: false,
        status: BookingStatus.pembayaranSelesai,
      );

      await tester.pumpWidget(createTestWidget(booking: activeLepasKunciBooking));
      await tester.pumpAndSettle();

      // Memastikan E-Ticket QR Code dan kode serah terima aktif tanpa banner terkunci
      expect(find.text('Kode Serah Terima Terkunci'), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.textContaining('Kode Serah Terima: MBJ-'), findsOneWidget);
    });

    testWidgets('Membuka modal Rincian Tarif saat teks Lihat Rincian Tarif pada Sticky Bottom Bar diketuk', (tester) async {
      final waitingBooking = inProgressBooking.copyWith(
        status: BookingStatus.menungguPembayaran,
        isFinalTariffConfirmed: true,
        withDriver: true,
      );

      await tester.pumpWidget(createTestWidget(booking: waitingBooking));
      await tester.pumpAndSettle();

      // Memastikan tombol Lihat Rincian Tarif ada di Sticky Bar
      final rincianTarifFinder = find.text('Lihat Rincian Tarif');
      expect(rincianTarifFinder, findsOneWidget);

      await tester.tap(rincianTarifFinder);
      await tester.pumpAndSettle();

      // Memastikan modal bottom sheet rincian tarif terbuka
      expect(find.text('Rincian Tarif Final'), findsOneWidget);
      expect(find.textContaining('Sewa Unit'), findsOneWidget);
      expect(find.textContaining('Layanan Sopir'), findsOneWidget);
      expect(find.text('Total Pembayaran'), findsAtLeastNWidgets(1));
      expect(find.text('Tutup Rincian'), findsOneWidget);

      // Tutup modal
      await tester.tap(find.text('Tutup Rincian'));
      await tester.pumpAndSettle();

      expect(find.text('Rincian Tarif Final'), findsNothing);
    });

    testWidgets('Menciutkan kartu dokumen lepas kunci saat 3 berkas lengkap pada Tahap 3 dan dapat dibuka-tutup', (tester) async {
      final completedDocsBooking = inProgressBooking.copyWith(
        withDriver: false,
        status: BookingStatus.menungguPembayaran,
      );

      final mockDoc = BookingDocumentModel(
        id: 'DOC-123',
        bookingId: completedDocsBooking.id,
        ktpUrl: 'https://example.com/ktp.jpg',
        simUrl: 'https://example.com/sim.jpg',
        statementLetterUrl: 'https://example.com/statement.pdf',
        status: DocumentStatus.pendingVerification,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        booking: completedDocsBooking,
        initialDocument: mockDoc,
      ));
      await tester.pumpAndSettle();

      // Memastikan banner ciut (collapsed) muncul dengan status 3/3 Menunggu Cek
      expect(find.text('3/3 Menunggu Cek'), findsOneWidget);
      expect(find.text('Lihat'), findsOneWidget);
      expect(find.text('1. Foto e-KTP Asli'), findsNothing);

      // Verifikasi kartu ciut membentang lebar penuh dan bukan setengah sisi
      final collapsedFinder = find.ancestor(
        of: find.text('Dokumen Lepas Kunci'),
        matching: find.byType(Container),
      ).first;
      expect(tester.getSize(collapsedFinder).width, greaterThan(300.0));

      // Verifikasi warna badge Tahap 3 adalah hijau/teal (AppColors.primaryTeal) bukan kuning
      expect(find.text('MENUNGGU BAYAR'), findsOneWidget);
      final step3Badge = tester.widget<Text>(find.text('MENUNGGU BAYAR'));
      expect(step3Badge.style?.color, equals(AppColors.primaryTeal));

      // Ketuk tombol Lihat untuk mengekspansi
      await tester.tap(find.text('Lihat'));
      await tester.pumpAndSettle();

      // Sekarang berkas terlihat dan tombol berubah menjadi Sembunyikan
      expect(find.text('Sembunyikan'), findsOneWidget);
      expect(find.text('1. Foto e-KTP Asli'), findsOneWidget);
      expect(find.text('2. Foto SIM A Aktif'), findsOneWidget);

      // Ketuk Sembunyikan untuk kembali menciutkan
      await tester.tap(find.text('Sembunyikan'));
      await tester.pumpAndSettle();

      expect(find.text('Lihat'), findsOneWidget);
      expect(find.text('1. Foto e-KTP Asli'), findsNothing);
    });

    testWidgets('Merender Sub-State 3B (Sudah Upload Bukti) dengan badge Sedang Diverifikasi dan tombol Ganti Bukti', (tester) async {
      final waitingBooking = inProgressBooking.copyWith(
        status: BookingStatus.menungguPembayaran,
        isFinalTariffConfirmed: true,
      );

      final mockPayment = PaymentModel(
        id: 'PAY-123',
        bookingId: waitingBooking.id,
        baseAmount: 450000,
        uniqueCode: 123,
        totalAmount: 450123,
        method: PaymentMethod.bankTransfer,
        status: PaymentStatus.pendingVerification,
        proofImageUrl: 'data:image/jpeg;base64,mock',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        booking: waitingBooking,
        initialPayment: mockPayment,
      ));
      await tester.pumpAndSettle();

      // Card 1 menampilkan Menunggu Verifikasi Pembayaran dan badge Sedang Diverifikasi
      expect(find.text('Menunggu Verifikasi Pembayaran'), findsOneWidget);
      expect(find.text('Sedang Diverifikasi'), findsOneWidget);

      // Stepper Step 3 menampilkan badge VERIFIKASI ADMIN
      expect(find.text('VERIFIKASI ADMIN'), findsOneWidget);

      // Sticky Bottom Bar menampilkan tombol Ganti Bukti dan Bukti Terkirim
      expect(find.text('Ganti Bukti'), findsOneWidget);
      expect(find.text('Bukti Terkirim'), findsOneWidget);
    });

    testWidgets('Merender status Ditolak (Perlu Revisi) dengan Smart Targeting dokumen dan guard submit berkas', (tester) async {
      final lepasKunciBooking = inProgressBooking.copyWith(
        id: 'MJ-LK-REJECTED',
        withDriver: false,
        status: BookingStatus.permintaanDiterima,
        isFinalTariffConfirmed: false,
      );

      final rejectedDoc = BookingDocumentModel(
        id: 'DOC-REJ-01',
        bookingId: lepasKunciBooking.id,
        ktpUrl: 'https://example.com/ktp.jpg',
        simUrl: 'https://example.com/sim.jpg',
        statementLetterUrl: 'https://example.com/statement.jpg',
        status: DocumentStatus.rejected,
        rejectionReason: '[Foto SIM A]: Foto SIM buram pada bagian masa berlaku',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        booking: lepasKunciBooking,
        initialDocument: rejectedDoc,
      ));
      await tester.pumpAndSettle();

      // Header badge menampilkan Perlu Revisi
      expect(find.text('Perlu Revisi'), findsOneWidget);

      // Callout peringatan staf tampil
      expect(find.textContaining('Catatan Staf:'), findsOneWidget);
      expect(find.textContaining('Foto SIM buram pada bagian masa berlaku'), findsOneWidget);

      // Smart targeting: SIM A targeted, KTP tidak targeted
      expect(find.text('Ditolak • Perlu foto ulang'), findsOneWidget);
      expect(find.text('ktp_pemesan.jpg • Telah diunggah'), findsOneWidget);

      // Tombol submit terkunci jika belum ada draft baru dipilih
      expect(find.text('Pilih Berkas Baru Terlebih Dahulu'), findsOneWidget);

      // Simulasikan pengguna memilih berkas baru untuk SIM A
      final uploadButton = find.widgetWithText(OutlinedButton, 'Unggah Ulang');
      await tester.ensureVisible(uploadButton);
      await tester.pumpAndSettle();
      await tester.tap(uploadButton);
      await tester.pumpAndSettle();

      // Feedback draft baru dipilih
      expect(find.text('✓ File baru dipilih (Siap dikirim)'), findsOneWidget);

      // Tombol submit sekarang aktif
      expect(find.text('Kirim Pembaruan Dokumen'), findsOneWidget);
    });
  });
}
