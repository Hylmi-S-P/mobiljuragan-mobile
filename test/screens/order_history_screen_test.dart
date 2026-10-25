import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/order_history_screen.dart';
import 'package:mobiljuragan_mobile/screens/order_status_screen.dart';

void main() {
  final sampleVehicle = VehicleModel.sampleVehicles.first;

  final bookingKonfirmasi = BookingModel(
    id: 'MJ-TEST-KONFIRMASI',
    vehicle: sampleVehicle,
    startDate: DateTime(2026, 10, 20),
    startTime: '09.00 WIT',
    durationDays: 2,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.permintaanDiterima,
    createdAt: DateTime(2026, 10, 19),
    dailyRate: 400000,
    isFinalTariffConfirmed: false,
  );

  final bookingBayar = BookingModel(
    id: 'MJ-TEST-BAYAR',
    vehicle: sampleVehicle,
    startDate: DateTime(2026, 10, 21),
    startTime: '09.00 WIT',
    durationDays: 3,
    withDriver: true,
    pickupLocation: 'Hotel Swiss-Belhotel Merauke',
    status: BookingStatus.menungguPembayaran,
    createdAt: DateTime(2026, 10, 19),
    dailyRate: 400000,
    isFinalTariffConfirmed: true,
  );

  final bookingSiap = BookingModel(
    id: 'MJ-TEST-SIAP',
    vehicle: sampleVehicle,
    startDate: DateTime(2026, 10, 22),
    startTime: '09.00 WIT',
    durationDays: 1,
    withDriver: false,
    pickupLocation: 'Pelabuhan Merauke',
    status: BookingStatus.mobilSiapDigunakan,
    createdAt: DateTime(2026, 10, 19),
    dailyRate: 400000,
    isFinalTariffConfirmed: true,
  );

  final bookingSelesai = BookingModel(
    id: 'MJ-TEST-SELESAI',
    vehicle: sampleVehicle,
    startDate: DateTime(2026, 10, 15),
    startTime: '09.00 WIT',
    durationDays: 2,
    withDriver: false,
    pickupLocation: 'Bandara Mopah Merauke',
    status: BookingStatus.selesai,
    createdAt: DateTime(2026, 10, 14),
    dailyRate: 400000,
    isFinalTariffConfirmed: true,
  );

  final allTestBookings = [
    bookingKonfirmasi,
    bookingBayar,
    bookingSiap,
    bookingSelesai,
  ];

  Widget createTestWidget({List<BookingModel>? bookings}) {
    final controller = BookingController();
    if (bookings != null) {
      controller.setBookingsForTesting(bookings);
    }

    return ChangeNotifierProvider<BookingController>.value(
      value: controller,
      child: const MaterialApp(
        home: OrderHistoryScreen(),
      ),
    );
  }

  group('OrderHistoryScreen UI & Layout Tests', () {
    testWidgets('Merender segmented control tanpa sub-header redundan Pesanan Aktif', (tester) async {
      await tester.pumpWidget(createTestWidget(bookings: allTestBookings));
      await tester.pumpAndSettle();

      // Judul App Bar & Deskripsi
      expect(find.text('Riwayat Pesanan'), findsOneWidget);
      expect(find.text('Lacak Status Armada & Transaksi'), findsOneWidget);

      // Segmented control tab
      expect(find.text('Pesanan Berjalan'), findsOneWidget);
      expect(find.text('Riwayat Selesai'), findsOneWidget);

      // Sub-header redundan di bawah tab harus hilang
      expect(find.text('Pesanan Aktif'), findsNothing);
      expect(find.text('Pembaruan real-time'), findsNothing);
      expect(find.text('Riwayat Sewa Sebelumnya'), findsNothing);
    });

    testWidgets('Merender badge semantik yang konsisten dan tombol aksi sesuai urgensi', (tester) async {
      await tester.pumpWidget(createTestWidget(bookings: allTestBookings));
      await tester.pumpAndSettle();

      // Menunggu Konfirmasi (menggantikan Pengajuan Diterima)
      expect(find.text('Menunggu Konfirmasi'), findsOneWidget);

      // Menunggu Pembayaran
      expect(find.text('Menunggu Pembayaran'), findsOneWidget);

      // Mobil Siap Digunakan (menggantikan Armada Siap Jalan)
      expect(find.text('Mobil Siap Digunakan'), findsOneWidget);

      // Tombol aksi prioritas: Bayar Sekarang untuk Menunggu Pembayaran
      expect(find.text('Bayar Sekarang'), findsOneWidget);

      // Tombol aksi informatif: Lihat Detail untuk status non-pembayaran
      expect(find.text('Lihat Detail'), findsAtLeastNWidgets(2));
    });

    testWidgets('Beralih ke tab Riwayat Selesai menampilkan status Selesai dan tombol Sewa Lagi', (tester) async {
      await tester.pumpWidget(createTestWidget(bookings: allTestBookings));
      await tester.pumpAndSettle();

      // Ketuk tab Riwayat Selesai
      await tester.tap(find.text('Riwayat Selesai'));
      await tester.pumpAndSettle();

      // Menampilkan badge Selesai
      expect(find.text('Selesai'), findsOneWidget);

      // Tombol aksi Sewa Lagi untuk pesanan rampung
      expect(find.text('Sewa Lagi'), findsOneWidget);

      // Sub-header duplikat tidak muncul
      expect(find.text('Riwayat Sewa Sebelumnya'), findsNothing);
    });

    testWidgets('Mengetuk kartu pesanan membuka halaman OrderStatusScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(bookings: allTestBookings));
      await tester.pumpAndSettle();

      // Ketuk salah satu kartu pesanan aktif (atau tombol Lihat Detail)
      final detailBtn = find.text('Lihat Detail').first;
      await tester.ensureVisible(detailBtn);
      await tester.tap(detailBtn);
      await tester.pumpAndSettle();

      // Membuka halaman detail Status Pesanan
      expect(find.byType(OrderStatusScreen), findsOneWidget);
      expect(find.text('Status Pesanan'), findsOneWidget);
    });
  });
}