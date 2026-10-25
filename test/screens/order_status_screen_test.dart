import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';

void main() {
  Widget createTestWidget({required BookingModel booking}) {
    return ChangeNotifierProvider<BookingController>(
      create: (_) => BookingController(),
      child: MaterialApp(
        home: OrderStatusScreen(booking: booking),
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
      );

      await tester.pumpWidget(createTestWidget(booking: requestedBooking));
      await tester.pumpAndSettle();

      // Unified Hero Card berada di bagian atas dengan judul peninjauan admin
      expect(find.text('Pengajuan Sedang Ditinjau Admin'), findsOneWidget);
      expect(find.text('Formulir pengajuan sewa berhasil dikirim'), findsOneWidget);

      // Kartu ringkasan unit tetap muncul saat belum lunas dengan estimasi biaya
      expect(find.text('Estimasi Total Biaya'), findsOneWidget);

      // Tombol pembatalan berupa teks link Batalkan Pengajuan Sewa (bukan tombol merah raksasa)
      expect(find.text('Batalkan Pengajuan Sewa'), findsOneWidget);
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

      // Tombol bawah: Hubungi CS dan Batalkan Pesanan Ini (tanpa tumpukan tombol berlebih)
      expect(find.text('Hubungi CS MobilJuragan'), findsOneWidget);
      expect(find.text('Batalkan Pesanan Ini'), findsOneWidget);
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
  });
}
