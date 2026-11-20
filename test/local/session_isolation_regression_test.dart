import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/auth_controller.dart';
import 'package:mobiljuragan_mobile/data/local/database/app_database.dart';
import 'package:mobiljuragan_mobile/data/local/preferences/app_settings_service.dart';
import 'package:mobiljuragan_mobile/data/local/secure/secure_storage_service.dart';
import 'package:mobiljuragan_mobile/data/remote/auth_api_service.dart';
import 'package:mobiljuragan_mobile/data/remote/booking_api_service.dart';
import 'package:mobiljuragan_mobile/data/repositories/auth_repository.dart';
import 'package:mobiljuragan_mobile/data/repositories/booking_repository.dart';
import 'package:mobiljuragan_mobile/models/booking_model.dart';
import 'package:mobiljuragan_mobile/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/armada_uji.dart';

/// Penyimpanan kredensial palsu yang bisa berganti pemilik di tengah operasi.
///
/// Dipakai untuk meniru pergantian akun ketika sebuah operasi jaringan masih
/// berjalan: `getUserId()` sudah menjawab akun baru sementara data yang sedang
/// diolah masih milik akun lama.
class _PenyimpananUji extends SecureStorageService {
  _PenyimpananUji({this.userId, this.wipePending = false});

  String? userId;
  bool wipePending;

  /// Kegagalan yang disengaja pada salah satu langkah pembersihan.
  bool gagalSaatHapusToken = false;

  int jumlahHapusToken = 0;
  int jumlahHapusJurnal = 0;

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<bool> hasValidToken() async => userId != null;

  @override
  Future<bool> isWipePending() async => wipePending;

  @override
  Future<void> markWipePending() async {
    wipePending = true;
  }

  @override
  Future<void> clearWipePending() async {
    jumlahHapusJurnal++;
    wipePending = false;
  }

  @override
  Future<void> clearAuth() async {
    jumlahHapusToken++;
    if (gagalSaatHapusToken) {
      throw const FormatException('Secure storage menolak dihapus');
    }
    userId = null;
  }
}

/// API pemesanan yang pengambilannya bisa ditahan sampai sesi berganti.
class _ApiPemesananUji extends BookingApiService {
  _ApiPemesananUji(this._saatDiambil);

  final Future<void> Function() _saatDiambil;

  int jumlahAmbil = 0;

  @override
  Future<List<dynamic>> fetchBookings() async {
    jumlahAmbil++;
    await _saatDiambil();
    return [];
  }

  @override
  Future<Map<String, dynamic>> createBooking({
    required String vehicleId,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool withDriver,
    String? pickupLocation,
    String? customerRequest,
    int? numberGuests,
  }) async {
    return {
      'id': 'bkg-uji',
      'bookingCode': 'MJ-20261120-UJI',
      'vehicleId': vehicleId,
    };
  }
}

/// API autentikasi palsu: pencabutan token tidak pernah mengenai jaringan nyata.
class _ApiAuthUji extends AuthApiService {
  int jumlahCabut = 0;

  @override
  Future<Map<String, dynamic>> logoutSemuaPerangkat() async {
    jumlahCabut++;
    return {'status': 'success'};
  }
}

/// Regresi isolasi sesi pada **berkas SQLite nyata**.
///
/// Seluruh test sebelumnya memakai `NativeDatabase.memory()`, sehingga tidak
/// pernah menyentuh perilaku berkas di cakram: pembukaan ulang, penulisan ulang
/// setelah aplikasi ditutup, maupun sisa pembersihan yang terputus. Empat
/// skenario di bawah adalah jalur yang dulu membocorkan data antar akun.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now().toUtc().millisecondsSinceEpoch;

  late Directory folderSementara;
  late File berkasDatabase;
  late AppDatabase database;

  BookingsCompanion barisPesanan(
    String id, {
    String? userId,
    String lokasi = 'Kantor MobilJuragan',
  }) {
    return BookingsCompanion(
      id: Value(id),
      userId: Value(userId),
      vehicleId: const Value('avanza-g-putih-ps1692b'),
      startDate: Value(now),
      startTime: const Value('09.00 WIT'),
      durationDays: const Value(1),
      pickupLocation: Value(lokasi),
      status: const Value('permintaanDiterima'),
      dailyRate: const Value(400000),
      serviceFee: const Value(0),
      paymentBank: const Value('BRI'),
      paymentAccountNumber: const Value('123'),
      createdAt: Value(now),
      lastFetched: Value(now),
    );
  }

  BookingModel modelPesanan(String id, {String lokasi = 'Kantor MobilJuragan'}) {
    return BookingModel(
      id: id,
      vehicle: armadaUji.first,
      startDate: DateTime.utc(2026, 11, 25, 8),
      startTime: '08.00 WIT',
      durationDays: 2,
      withDriver: false,
      pickupLocation: lokasi,
      status: BookingStatus.menungguTarifFinal,
      createdAt: DateTime.now(),
      dailyRate: 400000,
      serviceFee: 25000,
    );
  }

  setUp(() async {
    folderSementara = await Directory.systemTemp.createTemp('mobiljuragan_uji_');
    berkasDatabase = File('${folderSementara.path}/mobiljuragan_local_db.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(berkasDatabase));
    // Membuka koneksi lebih dulu supaya migrasi `onCreate` benar-benar berjalan
    // di atas berkas nyata, bukan pada basis data di memori.
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await database.close();
    if (folderSementara.existsSync()) {
      folderSementara.deleteSync(recursive: true);
    }
  });

  test('dua akun dengan kode pesanan sama tidak saling menimpa', () async {
    final penyimpanan = _PenyimpananUji(userId: 'user-A');
    final repo = BookingRepository(
      database.bookingDao,
      _ApiPemesananUji(() async {}),
      penyimpanan,
      database.vehicleDao,
    );

    repo.setActiveUserForTest('user-A');
    await repo.saveBooking(modelPesanan('SAMA-001', lokasi: 'Alamat akun A'));

    /* Sesi berganti ke akun B, lalu akun B menyimpan pesanan dengan kode yang
       kebetulan sama. Kunci utama tabel hanya `{id}`: tanpa pemeriksaan
       pemilik, penulisan ini mengganti baris akun A beserta kolom pemiliknya. */
    penyimpanan.userId = 'user-B';
    repo.setActiveUserForTest('user-B');
    await repo.saveBooking(modelPesanan('SAMA-001', lokasi: 'Alamat akun B'));

    final pemilik = await database.bookingDao.getOwnerOfBooking('SAMA-001');
    expect(pemilik, 'user-A');

    final barisA = await database.bookingDao.getBookingById(
      'SAMA-001',
      userId: 'user-A',
    );
    expect(barisA?.pickupLocation, 'Alamat akun A');

    final milikB = await database.bookingDao.getAllBookings(userId: 'user-B');
    expect(milikB, isEmpty);
  });

  test('pergantian sesi di tengah sinkronisasi tidak mencap data akun lama', () async {
    await database.bookingDao.upsertBookingsBatch([
      barisPesanan('book-a1', userId: 'user-A'),
      barisPesanan('book-b1', userId: 'user-B'),
    ]);

    final penyimpanan = _PenyimpananUji(userId: 'user-A');
    final pengambilSelesai = Completer<void>();
    final api = _ApiPemesananUji(() => pengambilSelesai.future);

    final repo = BookingRepository(
      database.bookingDao,
      api,
      penyimpanan,
      database.vehicleDao,
    );

    // Sinkronisasi dimulai sebagai akun A, lalu akun berganti ke B sementara
    // permintaan jaringan masih berjalan.
    final sinkronisasi = repo.syncAllBookingsFromRemote();
    await Future<void>.delayed(Duration.zero);
    penyimpanan.userId = 'user-B';
    await repo.refreshSession();
    pengambilSelesai.complete();

    final hasil = await sinkronisasi;
    expect(hasil, isEmpty);
    expect(api.jumlahAmbil, 1);

    // Baris akun A tetap milik A, baris akun B tidak ikut terhapus.
    final milikA = await database.bookingDao.getAllBookings(userId: 'user-A');
    expect(milikA.map((row) => row.id), ['book-a1']);

    final milikB = await database.bookingDao.getAllBookings(userId: 'user-B');
    expect(milikB.map((row) => row.id), ['book-b1']);
  });

  test('pembersihan yang terputus dituntaskan saat aplikasi dibuka kembali', () async {
    await database.bookingDao.upsertBookingsBatch([
      barisPesanan('book-a1', userId: 'user-A'),
      barisPesanan('book-b1', userId: 'user-B'),
    ]);

    // Keadaan setelah aplikasi ditutup paksa di tengah logout akun A.
    final penyimpanan = _PenyimpananUji(userId: 'user-A', wipePending: true);
    final authApi = _ApiAuthUji();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final pengaturan = await AppSettingsService.create();

    final controller = AuthController(
      repository: AuthRepository(apiService: authApi, secureStorage: penyimpanan),
      secureStorage: penyimpanan,
      bookingRepository: BookingRepository(
        database.bookingDao,
        _ApiPemesananUji(() async {}),
        penyimpanan,
        database.vehicleDao,
      ),
      settingsService: pengaturan,
    );

    await controller.initSession();

    expect(controller.bootState, StatusBootSesi.dipulihkan);
    expect(controller.isLoggedIn, isFalse);
    expect(penyimpanan.jumlahHapusToken, 1);
    expect(penyimpanan.jumlahHapusJurnal, 1);
    expect(penyimpanan.wipePending, isFalse);
    expect(authApi.jumlahCabut, 1);

    // Hanya baris akun yang sedang keluar yang dibuang.
    final milikA = await database.bookingDao.getAllBookings(userId: 'user-A');
    expect(milikA, isEmpty);

    final milikB = await database.bookingDao.getAllBookings(userId: 'user-B');
    expect(milikB.map((row) => row.id), ['book-b1']);
  });

  test('logout yang gagal di satu langkah tetap menyelesaikan sesi', () async {
    await database.bookingDao.upsertBookingsBatch([
      barisPesanan('book-a1', userId: 'user-A'),
    ]);

    final penyimpanan = _PenyimpananUji(userId: 'user-A')
      ..gagalSaatHapusToken = true;

    final controller = AuthController(
      repository: AuthRepository(
        apiService: _ApiAuthUji(),
        secureStorage: penyimpanan,
      ),
      secureStorage: penyimpanan,
      bookingRepository: BookingRepository(
        database.bookingDao,
        _ApiPemesananUji(() async {}),
        penyimpanan,
        database.vehicleDao,
      ),
    );

    controller.setSessionForTest(
      user: UserModel(
        id: 'user-A',
        name: 'Pelanggan Uji',
        phoneNumber: '081248002910',
        avatarInitials: 'PU',
      ),
    );

    var jumlahPemberitahuan = 0;
    controller.addListener(() => jumlahPemberitahuan++);

    await controller.logout();

    /* Penghapusan token sengaja dibuat gagal. Sesi di memori tetap harus
       selesai, seluruh lapisan lain tetap dibersihkan, dan penanda pembersihan
       tetap dicabut supaya aplikasi tidak mengulanginya terus-menerus. */
    expect(jumlahPemberitahuan, greaterThan(0));
    expect(controller.isLoggedIn, isFalse);
    expect(controller.currentUser, isNull);
    expect(controller.isLoggingOut, isFalse);
    expect(penyimpanan.jumlahHapusToken, 1);
    expect(penyimpanan.jumlahHapusJurnal, 1);
    expect(penyimpanan.wipePending, isFalse);

    final milikA = await database.bookingDao.getAllBookings(userId: 'user-A');
    expect(milikA, isEmpty);
  });
}
