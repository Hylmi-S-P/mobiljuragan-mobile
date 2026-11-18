import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/remote/booking_api_service.dart';
import 'package:mobiljuragan_mobile/data/repositories/booking_repository.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';

import '../support/armada_uji.dart';

/// Test double: pembatalan mengembalikan catatan refund seperti server asli.
class FakeApiRefund extends BookingApiService {
  Map<String, dynamic>? balasan;
  Exception? galat;

  FakeApiRefund({this.balasan, this.galat});

  @override
  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
  }) async {
    rekeningTerkirim = {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
    };
    if (galat != null) throw galat!;
    return balasan ?? <String, dynamic>{};
  }

  /// Rekening yang benar-benar sampai ke lapisan API saat pembatalan dikirim.
  Map<String, String?>? rekeningTerkirim;

  /// Rekening yang dikirim lewat jalur klaim setelah pesanan batal.
  Map<String, String?>? rekeningDiklaim;

  /// Bila diisi, klaim rekening dianggap ditolak server.
  bool tolakKlaim = false;

  @override
  Future<Map<String, dynamic>> claimRefundAccount({
    required String bookingId,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    rekeningDiklaim = {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
    };
    if (tolakKlaim) {
      throw Exception('Pengembalian dana sudah ditutup kantor');
    }
    return {
      'refund': {
        'namaBank': bankName,
        'nomorRekening': accountNumber,
        'namaPemilik': accountHolderName,
        'status': 'MENUNGGU',
      },
    };
  }
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  BookingModel pesananTerbayar() => BookingModel(
    id: 'MJ-REFUND-1',
    vehicle: armadaUji.first,
    startDate: DateTime.utc(2026, 11, 20, 9, 0),
    startTime: '09.00 WIT',
    durationDays: 2,
    withDriver: false,
    pickupLocation: 'Kantor MobilJuragan',
    status: BookingStatus.pembayaranSelesai,
    createdAt: DateTime.now(),
    dailyRate: 450000,
    serviceFee: 0,
    quotedAmount: 900000,
  );

  Future<void> tungguRiwayat(BookingController controller) async {
    for (var i = 0; i < 50; i++) {
      if (controller.bookingHistory.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('nominal refund diambil dari server, bukan hitungan 85% di perangkat',
      () async {
    final api = FakeApiRefund(
      balasan: {
        'booking': {
          'id': 'MJ-REFUND-1',
          'status': 'CANCELLED',
          'refund': {
            'totalDibayar': 900000,
            'potongan': 50000,
            'nominal': 850000,
            'dibatalkanOleh': 'PELANGGAN',
          },
        },
      },
    );
    final repository = BookingRepository(database.bookingDao, api);
    await repository.saveBooking(pesananTerbayar());

    final controller = BookingController(repository: repository);
    await tungguRiwayat(controller);

    await controller.cancelBooking(
      bookingId: 'MJ-REFUND-1',
      reason: 'Rencana keluarga berubah',
    );

    final hasil = controller.bookingHistory
        .firstWhere((b) => b.id == 'MJ-REFUND-1');
    expect(hasil.status, equals(BookingStatus.dibatalkan));
    // 85% dari 900.000 adalah 765.000; server mengembalikan 850.000.
    expect(hasil.cancellationRefundAmount, equals(850000));

    controller.dispose();
  });

  test('bila server menolak atau tidak terjangkau, status lokal tidak dipaksa dibatalkan', () async {
    final api = FakeApiRefund(galat: Exception('Offline'));
    final repository = BookingRepository(database.bookingDao, api);
    await repository.saveBooking(pesananTerbayar());

    final controller = BookingController(repository: repository);
    await tungguRiwayat(controller);

    final galat = await controller.cancelBooking(
      bookingId: 'MJ-REFUND-1',
      reason: 'Tidak jadi sewa',
    );

    final hasil = controller.bookingHistory
        .firstWhere((b) => b.id == 'MJ-REFUND-1');
    expect(galat, isNotNull);
    expect(hasil.status, equals(BookingStatus.pembayaranSelesai));
    expect(hasil.cancellationRefundAmount, isNull);

    controller.dispose();
  });

  test('rekening tujuan refund ikut dikirim saat pelanggan membatalkan',
      () async {
    final api = FakeApiRefund(
      balasan: {
        'booking': {
          'id': 'MJ-REFUND-1',
          'status': 'CANCELLED',
          'refund': {
            'totalDibayar': 900000,
            'potongan': 50000,
            'nominal': 850000,
            'dibatalkanOleh': 'PELANGGAN',
          },
        },
      },
    );
    final repository = BookingRepository(database.bookingDao, api);
    await repository.saveBooking(pesananTerbayar());

    final controller = BookingController(repository: repository);
    await tungguRiwayat(controller);

    await controller.cancelBooking(
      bookingId: 'MJ-REFUND-1',
      reason: 'Rencana keluarga berubah',
      bankName: 'Bank Papua',
      accountNumber: '1234567890',
      accountHolderName: 'Yahya Pratama',
    );

    // Sebelumnya isian ini berhenti di perangkat dan kantor harus menelepon
    // pelanggan untuk menanyakan nomor rekening.
    expect(api.rekeningTerkirim?['bankName'], equals('Bank Papua'));
    expect(api.rekeningTerkirim?['accountNumber'], equals('1234567890'));
    expect(api.rekeningTerkirim?['accountHolderName'], equals('Yahya Pratama'));

    controller.dispose();
  });

  test('refund tetap tampil setelah kartu dibaca ulang dari penyimpanan lokal',
      () async {
    final api = FakeApiRefund(
      balasan: {
        'booking': {
          'id': 'MJ-REFUND-1',
          'status': 'CANCELLED',
          'refund': {
            'totalDibayar': 900000,
            'potongan': 50000,
            'nominal': 850000,
            'dibatalkanOleh': 'PELANGGAN',
            'namaBank': 'Bank Papua',
            'nomorRekening': '1234567890',
            'namaPemilik': 'Yahya Pratama',
            'status': 'MENUNGGU',
          },
        },
      },
    );
    final repository = BookingRepository(database.bookingDao, api);
    await repository.saveBooking(pesananTerbayar());

    final controller = BookingController(repository: repository);
    await tungguRiwayat(controller);

    await controller.cancelBooking(
      bookingId: 'MJ-REFUND-1',
      reason: 'Rencana keluarga berubah',
      bankName: 'Bank Papua',
      accountNumber: '1234567890',
      accountHolderName: 'Yahya Pratama',
    );
    controller.dispose();

    // Controller baru membaca ulang dari SQLite, seperti saat aplikasi dibuka.
    final controllerBaru = BookingController(repository: repository);
    await tungguRiwayat(controllerBaru);

    final hasil = controllerBaru.bookingHistory
        .firstWhere((b) => b.id == 'MJ-REFUND-1');
    expect(hasil.cancellationRefundAmount, equals(850000));
    expect(hasil.cancellationBank, equals('Bank Papua'));
    expect(hasil.cancellationAccountNumber, equals('1234567890'));
    expect(hasil.cancellationAccountName, equals('Yahya Pratama'));
    expect(hasil.refundStatus, equals('MENUNGGU'));
    expect(hasil.cancellationReason, contains('Rencana keluarga berubah'));

    controllerBaru.dispose();
  });

  test('rekening bisa diklaim setelah pesanan batal dan tersimpan di perangkat',
      () async {
    final api = FakeApiRefund(
      balasan: {
        'booking': {
          'id': 'MJ-REFUND-1',
          'status': 'CANCELLED',
          'refund': {
            'totalDibayar': 900000,
            'potongan': 50000,
            'nominal': 850000,
            'dibatalkanOleh': 'PELANGGAN',
            'status': 'MENUNGGU',
          },
        },
      },
    );
    final repository = BookingRepository(database.bookingDao, api);
    await repository.saveBooking(pesananTerbayar());

    final controller = BookingController(repository: repository);
    await tungguRiwayat(controller);

    // Pelanggan membatalkan tanpa mengisi rekening (versi aplikasi lama).
    await controller.cancelBooking(
      bookingId: 'MJ-REFUND-1',
      reason: 'Rencana keluarga berubah',
    );

    final berhasil = await controller.claimRefundAccount(
      bookingId: 'MJ-REFUND-1',
      bankName: 'Bank Papua',
      accountNumber: '9876543210',
      accountHolderName: 'Yahya Pratama',
    );

    expect(berhasil, isTrue);
    expect(api.rekeningDiklaim?['bankName'], equals('Bank Papua'));
    expect(api.rekeningDiklaim?['accountNumber'], equals('9876543210'));

    /* Riwayat di controller disegarkan oleh stream Drift, jadi tunggu sampai
       baris hasil tulis ulang benar-benar sampai ke daftar. */
    for (var i = 0; i < 50; i++) {
      final baris = controller.bookingHistory
          .firstWhere((b) => b.id == 'MJ-REFUND-1');
      if (baris.cancellationBank != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    final hasil = controller.bookingHistory
        .firstWhere((b) => b.id == 'MJ-REFUND-1');
    expect(hasil.cancellationBank, equals('Bank Papua'));
    expect(hasil.cancellationAccountNumber, equals('9876543210'));
    expect(hasil.cancellationAccountName, equals('Yahya Pratama'));

    controller.dispose();
  });

  test('klaim rekening yang ditolak server tidak mengubah data di perangkat',
      () async {
    final api = FakeApiRefund(
      balasan: {
        'booking': {
          'id': 'MJ-REFUND-1',
          'status': 'CANCELLED',
          'refund': {
            'totalDibayar': 900000,
            'potongan': 50000,
            'nominal': 850000,
            'dibatalkanOleh': 'PELANGGAN',
            'status': 'SELESAI',
          },
        },
      },
    )..tolakKlaim = true;
    final repository = BookingRepository(database.bookingDao, api);
    await repository.saveBooking(pesananTerbayar());

    final controller = BookingController(repository: repository);
    await tungguRiwayat(controller);

    await controller.cancelBooking(
      bookingId: 'MJ-REFUND-1',
      reason: 'Rencana keluarga berubah',
    );

    final berhasil = await controller.claimRefundAccount(
      bookingId: 'MJ-REFUND-1',
      bankName: 'Bank BRI',
      accountNumber: '111222333',
      accountHolderName: 'Yahya Pratama',
    );

    expect(berhasil, isFalse);
    final hasil = controller.bookingHistory
        .firstWhere((b) => b.id == 'MJ-REFUND-1');
    expect(hasil.cancellationBank, isNull);

    controller.dispose();
  });
}
