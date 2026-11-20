import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/app_config_store.dart';
import '../core/network/api_client.dart';
import '../core/util/rental_duration.dart';
import '../data/remote/booking_api_service.dart';
import '../data/repositories/booking_repository.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';

/// Controller terpusat untuk mengelola seluruh siklus pemesanan kendaraan pelanggan
class BookingController extends ChangeNotifier {
  final BookingRepository? repository;
  final BookingApiService _apiService = BookingApiService();

  // Data formulir wizard pemesanan.
  //
  // Kosong di awal: pelanggan memilih sendiri unit yang tersedia. Sebelumnya
  // formulir sudah terisi unit pertama dari daftar contoh, sehingga pesanan
  // bisa terkirim untuk mobil yang tidak pernah dipilih.
  VehicleModel? _selectedVehicle;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09.00 WIT';
  int _durationDays = 2;
  bool _withDriver = false;
  String _pickupLocation = 'Bandara Mopah Merauke';
  /* Alamat titik serah terima/jemput yang sedang dipilih. Diisi dari data titik
     resmi saat pelanggan memilih, dan sengaja tidak dikonstankan di layar
     ringkasan: titik yang dipilih bisa bandara, pelabuhan, atau hasil ketukan
     peta, jadi alamat kantor tidak boleh dipakai untuk semuanya. */
  String _pickupAddress = '';
  double? _pickupLatitude = -8.5202;
  double? _pickupLongitude = 140.4180;
  String _customerNote = '';
  /* Persetujuan syarat & ketentuan sengaja dimulai TIDAK tercentang: pelanggan
     harus menyatakan setuju sendiri, bukan mewarisi centang bawaan. */
  bool _agreementChecked = false;

  // Tarif layanan sistem operasional MobilJuragan. Tarif jasa supir tidak lagi
  // dikonstankan di sini: nilainya dibaca dari backend (`GET /config`) lewat
  // `AppConfigStore` supaya sama dengan yang dipakai server saat menagih.
  static const int standardServiceFee = 0;

  // Status pesanan aktif dan daftar riwayat pesanan
  BookingModel? _activeBooking;
  final List<BookingModel> _bookingHistory = [];
  StreamSubscription<List<BookingModel>>? _bookingsSubscription;

  BookingController({this.repository}) {
    _init();
  }

  /// Akun yang cache-nya sedang ditampilkan.
  ///
  /// Dipakai untuk mendeteksi pergantian akun: cache lama dibuang, lalu data
  /// akun baru diambil dari server. Tanpa ini, riwayat baru tidak pernah muncul
  /// setelah login karena sinkronisasi hanya berjalan saat aplikasi dibuka.
  String? _sessionUserId;

  /// Penanda urutan pemanggilan [syncIfSessionChanged].
  ///
  /// Setiap pemanggilan menaikkan angka ini. Setelah `await`, pemanggilan yang
  /// angkanya sudah tidak berlaku berhenti tanpa menulis apa pun: hasil sinkron
  /// sesi lama tidak boleh menimpa data sesi yang lebih baru.
  int _sessionGen = 0;

  /// Akun yang datanya sedang ditampilkan layar ini.
  ///
  /// Dipakai layar pesanan untuk memastikan notifikasi status hanya muncul
  /// selama sesi yang menampilkannya masih menjadi pemilik pesanan.
  String? get sessionUserId => _sessionUserId;

  /// Bereaksi terhadap perubahan sesi (login/logout/akun berbeda).
  Future<void> syncIfSessionChanged(String? userId) async {
    if (userId == _sessionUserId) return;
    _sessionUserId = userId;
    final gen = ++_sessionGen;

    /* Saat sesi berakhir, isian wizard yang sedang dikerjakan dibuang dari
       memori. Isian itu memuat alamat jemput, titik koordinat, dan catatan
       pelanggan — jejak aktivitas pemilik akun sebelumnya yang tidak boleh
       terlihat oleh akun berikutnya di perangkat yang sama. */
    if (userId == null) {
      _resetFormTanpaNotifikasi();
    }

    final repo = repository;
    if (repo == null) {
      notifyListeners();
      return;
    }

    await repo.refreshSession();
    if (gen != _sessionGen) return;

    if (userId != null) {
      await repo.purgeOtherAccounts();
      if (gen != _sessionGen) return;
    }
    await repo.syncAllBookingsFromRemote();
    if (gen != _sessionGen) return;

    final tersimpan = await repo.getAllBookings();
    if (gen != _sessionGen) return;

    _bookingHistory
      ..clear()
      ..addAll(tersimpan);
    _activeBooking = _bookingHistory
        .where((b) => b.status != BookingStatus.selesai && b.status != BookingStatus.dibatalkan)
        .cast<BookingModel?>()
        .firstWhere((_) => true, orElse: () => null);

    /* Langganan Drift dibuat saat aplikasi dibuka, ketika pemilik cache belum
       tentu terbaca. DAO menyaring baris di SQL dengan `userId` yang ditangkap
       saat langganan dibuat, jadi langganan lama tetap memakai filter tamu
       (`userId IS NULL`) walau sesi sudah diketahui. Setiap tulisan ke Drift
       sesudahnya — termasuk hasil polling status — memancarkan daftar kosong
       dan menghapus riwayat yang baru dimuat. Karena itu langganan dipasang
       ulang setelah sesi pasti. */
    _pasangLanggananRiwayat(repo);

    notifyListeners();
  }

  /// Membuat langganan stream riwayat memakai pemilik cache yang berlaku.
  ///
  /// Versi sebelumnya hanya dipanggil sekali di `_init`, sehingga filter
  /// `userId` membeku pada keadaan saat aplikasi dibuka.
  void _pasangLanggananRiwayat(BookingRepository repo) {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = repo.watchAllBookings().listen((updatedList) {
      final previousById = {for (final b in _bookingHistory) b.id: b};
      final mergedList = updatedList.map((entry) {
        final prev = previousById[entry.id];
        if (prev == null) return entry;
        return entry.copyWith(
          paymentStatus: entry.paymentStatus ?? prev.paymentStatus,
          documentStatus: entry.documentStatus ?? prev.documentStatus,
          documentRejectionReason:
              entry.documentRejectionReason ?? prev.documentRejectionReason,
          documentDeadline: entry.documentDeadline ?? prev.documentDeadline,
          paymentReference: entry.paymentReference ?? prev.paymentReference,
          paidAt: entry.paidAt ?? prev.paidAt,
        );
      }).toList();
      _bookingHistory
        ..clear()
        ..addAll(mergedList);
      final actives = _bookingHistory
          .where(
            (b) =>
                b.status != BookingStatus.selesai &&
                b.status != BookingStatus.dibatalkan,
          )
          .toList();
      _activeBooking = actives.isNotEmpty ? actives.first : null;
      notifyListeners();
    });
  }

  /* Mengambil tarif terbaru satu pesanan dari server.
   *
   * Mengembalikan null kalau server tidak bisa dihubungi, supaya pemanggil bisa
   * berhenti memantau tanpa menampilkan galat yang mengganggu. Yang penting:
   * angka yang ditampilkan berasal dari server, bukan dihitung sendiri.
   */
  Future<BookingModel?> ambilTarifTerbaru(String bookingId) async {
    try {
      final daftar = await _apiService.fetchBookings();
      for (final item in daftar) {
        if (item is! Map) continue;
        final json = Map<String, dynamic>.from(item);
        if (json['id'] != bookingId) continue;

        final quoted = json['quotedAmount'];
        final tarif = quoted == null ? null : int.tryParse(quoted.toString());

        /* Ambil model yang sudah ada di riwayat supaya data kendaraan dan jadwal
           tetap utuh; yang diperbarui hanya angka tarifnya. */
        final indeks = _bookingHistory.indexWhere((b) => b.id == bookingId);
        if (indeks == -1) return null;

        final diperbarui = _bookingHistory[indeks].copyWith(
          quotedAmount: tarif,
        );
        _bookingHistory[indeks] = diperbarui;
        if (_activeBooking?.id == bookingId) _activeBooking = diperbarui;

        notifyListeners();
        return diperbarui;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _init() async {
    final repo = repository;
    if (repo != null) {
      try {
        // Pastikan filter pemilik cache sudah terpasang sebelum membaca data.
        await repo.refreshSession();
        final saved = await repo.getAllBookings();
        _bookingHistory.clear();
        _bookingHistory.addAll(saved);
        final actives = _bookingHistory
            .where(
              (b) =>
                  b.status != BookingStatus.selesai &&
                  b.status != BookingStatus.dibatalkan,
            )
            .toList();
        _activeBooking = actives.isNotEmpty ? actives.first : null;
        notifyListeners();
      } catch (_) {}

      _pasangLanggananRiwayat(repo);

      // Lakukan sinkronisasi pesanan dari remote REST API ke Drift SQLite
      unawaited(repo.syncAllBookingsFromRemote());
    }
  }

  /// Menghapus seluruh data pemesanan di controller dan basis data lokal Drift
  Future<void> clearAllBookings() async {
    _bookingHistory.clear();
    _activeBooking = null;
    notifyListeners();
    final repo = repository;
    if (repo != null) {
      await repo.clearLocalBookings();
    }
  }

  /// Sinkronisasi manual seluruh pesanan pelanggan dari backend REST API
  Future<void> refreshFromRemote() async {
    final repo = repository;
    if (repo != null) {
      await repo.syncAllBookingsFromRemote();
    }
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  // Formulir pemesanan
  VehicleModel? get selectedVehicle => _selectedVehicle;
  DateTime get selectedDate => _selectedDate;
  String get selectedTime => _selectedTime;
  int get durationDays => _durationDays;
  bool get withDriver => _withDriver;
  String get pickupLocation => _pickupLocation;
  String get pickupAddress => _pickupAddress;
  double? get pickupLatitude => _pickupLatitude;
  double? get pickupLongitude => _pickupLongitude;
  String get customerNote => _customerNote;
  bool get agreementChecked => _agreementChecked;

  // Status dan riwayat pesanan
  bool get hasActiveBooking {
    if (_activeBooking != null &&
        _activeBooking!.status != BookingStatus.selesai &&
        _activeBooking!.status != BookingStatus.dibatalkan) {
      return true;
    }
    return activeBookings.isNotEmpty;
  }

  BookingModel? get activeBooking {
    if (_activeBooking != null &&
        _activeBooking!.status != BookingStatus.selesai &&
        _activeBooking!.status != BookingStatus.dibatalkan) {
      return _activeBooking;
    }
    final actives = activeBookings;
    if (actives.isNotEmpty) {
      _activeBooking = actives.first;
      return _activeBooking;
    }
    return null;
  }

  List<BookingModel> get bookingHistory => List.unmodifiable(_bookingHistory);

  List<BookingModel> get activeBookings => _bookingHistory
      .where(
        (b) =>
            b.status != BookingStatus.selesai &&
            b.status != BookingStatus.dibatalkan,
      )
      .toList();

  List<BookingModel> get completedBookings => _bookingHistory
      .where(
        (b) =>
            b.status == BookingStatus.selesai ||
            b.status == BookingStatus.dibatalkan,
      )
      .toList();

  // Kalkulasi Biaya Terhitung Resmi (Sistem Dashboard Admin)
  int get dailyRate => _selectedVehicle?.pricePerDay ?? 400000;
  int get vehicleSubtotal => dailyRate * _durationDays;
  int get driverSubtotal =>
      _withDriver ? (AppConfigStore.driverDailyRate * _durationDays) : 0;
  int get serviceFee => standardServiceFee;
  int get totalCalculatedCost => vehicleSubtotal + driverSubtotal + serviceFee;
  int get totalEstimatedCost => totalCalculatedCost;
  String get activeBookingCode => _activeBooking?.id ?? '-';

  // Mutator Formulir Pemesanan
  void selectVehicle(VehicleModel vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void setSchedule({
    required DateTime date,
    required String time,
    required int durationDays,
  }) {
    _selectedDate = date;
    _selectedTime = time;
    _durationDays = durationDays.clamp(1, maxBookingAdvanceDays);
    notifyListeners();
  }

  void setDurationDays(int days) {
    _durationDays = days.clamp(1, maxBookingAdvanceDays);
    notifyListeners();
  }

  void toggleDriver(bool value) {
    if (_withDriver == value) return;
    _withDriver = value;
    notifyListeners();
  }

  void setPickupLocation(
    String location, [
    double? lat,
    double? lng,
    String? address,
  ]) {
    _pickupLocation = location;
    _pickupAddress = address ?? '';
    if (lat != null && lng != null) {
      _pickupLatitude = lat;
      _pickupLongitude = lng;
    }
    notifyListeners();
  }

  void setPickupCoordinates(double lat, double lng) {
    _pickupLatitude = lat;
    _pickupLongitude = lng;
    notifyListeners();
  }

  void setCustomerNote(String note) {
    _customerNote = note;
    notifyListeners();
  }

  void setAgreementChecked(bool value) {
    _agreementChecked = value;
    notifyListeners();
  }

  /// Mengirim pengajuan sewa (Finalisasi dari Frame 06 Tinjau Pesanan)
  /// Mengarahkan pesanan ke tahap 3 Figma: Konfirmasi tarif final (sedang dihitung admin)
  Future<BookingModel> submitBooking() async {
    final vehicle = _selectedVehicle;
    if (vehicle == null) {
      throw StateError(
        'Pilih kendaraan terlebih dahulu sebelum mengirim pesanan.',
      );
    }

    final jadwalError = validasiJadwalSewa(
      tanggal: _selectedDate,
      labelJam: _selectedTime,
      now: DateTime.now(),
      leadTime: const Duration(minutes: 115),
    );
    if (jadwalError != null) {
      throw ApiException(jadwalError, statusCode: 400);
    }

    final repo = repository;
    if (repo == null) {
      /* Tanpa repository tidak ada jalur ke server, jadi pesanan tidak bisa
         dibuat. Dulu bagian ini mengarang kode pesanan `MBJ-2026-xxxx` dan
         memasukkannya ke riwayat seolah-olah pesanan sudah tercatat; kode itu
         tidak pernah ada di server sehingga tidak bisa dibayar maupun
         dibatalkan. Sekarang kegagalannya dilaporkan apa adanya. */
      throw ApiException(
        'Penyimpanan pesanan belum siap. Silakan buka ulang aplikasi.',
      );
    }

    final remoteBooking = await repo.createBookingRemote(
      vehicle: vehicle,
      startDate: _selectedDate,
      startTime: _selectedTime,
      durationDays: _durationDays,
      withDriver: _withDriver,
      pickupLocation: _pickupLocation,
      pickupLatitude: _pickupLatitude,
      pickupLongitude: _pickupLongitude,
      note: _customerNote.isNotEmpty ? _customerNote : null,
    );

    _bookingHistory.removeWhere((b) => b.id == remoteBooking.id);
    _bookingHistory.insert(0, remoteBooking);
    _activeBooking = remoteBooking;
    notifyListeners();
    return remoteBooking;
  }

  /// Sinkronisasi status pesanan aktif dari backend REST API
  /// Mengembalikan true jika status berubah atau tarif final baru saja terbit
  Future<bool> refreshActiveBookingStatus([String? bookingId]) async {
    final targetId = bookingId ?? _activeBooking?.id;
    final repo = repository;
    if (targetId == null || repo == null) return false;

    BookingModel? targetBooking;
    try {
      targetBooking = _bookingHistory.firstWhere((b) => b.id == targetId);
    } catch (_) {
      targetBooking = _activeBooking;
    }

    final previousStatus = targetBooking?.status;
    final previouslyConfirmed = targetBooking?.isFinalTariffConfirmed ?? false;

    final updated = await repo.syncBookingStatus(targetId);
    if (updated != null) {
      if (_activeBooking?.id == targetId) {
        _activeBooking = updated;
      }
      final index = _bookingHistory.indexWhere((b) => b.id == updated.id);
      if (index != -1) {
        _bookingHistory[index] = updated;
      } else {
        _bookingHistory.insert(0, updated);
      }
      notifyListeners();

      final justConfirmed =
          !previouslyConfirmed && updated.isFinalTariffConfirmed;
      final statusChanged = previousStatus != updated.status;
      return justConfirmed || statusChanged;
    }
    return false;
  }

  /// Mencatat tagihan sudah dibayar pada salinan lokal setelah bukti transfer
  /// terkirim, supaya layar langsung menampilkan keadaan menunggu verifikasi
  /// tanpa menunggu sinkronisasi. Status sebenarnya tetap ditentukan server.
  void completeOnlinePayment({
    required String bookingId,
    required PaymentMethodType paymentMethod,
    String? referenceCode,
  }) {
    final index = _bookingHistory.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      /* Nomor referensi hanya diisi kalau server memang mengirimkannya.
         Sebelumnya aplikasi mengarang `TRX-MBJ-xxxxxxx` sendiri, sehingga
         pelanggan melihat nomor transaksi yang tidak pernah dikenal backend. */
      final updated = _bookingHistory[index].copyWith(
        paymentMethodType: paymentMethod,
        status: BookingStatus.menungguPembayaran,
        paymentStatus: 'PENDING_VERIFICATION',
        paidAt: DateTime.now(),
        paymentReference: referenceCode,
      );
      _bookingHistory[index] = updated;
      if (_activeBooking?.id == bookingId) {
        _activeBooking = updated;
      }
      repository?.saveBooking(updated);
      notifyListeners();
    }
  }

  /// Alias metode konfirmasi pemesanan untuk kompatibilitas alur terdahulu
  void confirmBooking() {
    submitBooking();
  }

  /// Memilih pesanan tertentu dari riwayat untuk dilihat detail statusnya
  void selectBookingForStatusView(BookingModel booking) {
    _activeBooking = booking;
    notifyListeners();
  }

  /// Membatalkan pesanan (baik pesanan aktif maupun pesanan spesifik berdasarkan ID).
  ///
  /// Nominal pengembalian dana dihitung SERVER (potongan tetap Rp 50.000 untuk
  /// pembatalan oleh pelanggan setelah bayar, penuh bila dibatalkan kantor).
  /// Aplikasi hanya menampilkan angka yang dikirim balik; bila server tidak
  /// terjangkau, pesanan tetap ditandai batal di perangkat tanpa nominal karangan.
  Future<String?> cancelBooking({
    required String bookingId,
    required String reason,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
  }) async {
    final index = _bookingHistory.indexWhere((b) => b.id == bookingId);
    if (index == -1) return 'Pesanan tidak ditemukan.';

    final target = _bookingHistory[index];

    Map<String, dynamic>? hasilServer;
    if (repository != null) {
      try {
        hasilServer = await repository!.cancelBookingRemote(
          bookingId: bookingId,
          reason: reason,
          bankName: bankName,
          accountNumber: accountNumber,
          accountHolderName: accountHolderName,
        );
      } on ApiException catch (e) {
        return e.message;
      }

      if (hasilServer == null) {
        return 'Gagal terhubung ke server. Pembatalan pesanan membutuhkan koneksi ke server.';
      }
    }

    final BookingModel? dariServer = hasilServer != null
        ? BookingModel.fromJson(hasilServer, target.vehicle)
        : null;
    final adaCatatanRefund = dariServer?.refundStatus != null ||
        dariServer?.cancellationRefundAmount != null;

    final updated = target.copyWith(
      status: BookingStatus.dibatalkan,
      cancellationReason: dariServer?.cancellationReason ?? reason,
      cancelledAt: dariServer?.cancelledAt ?? DateTime.now(),
      cancellationRefundAmount: dariServer?.cancellationRefundAmount,
      cancellationBank: dariServer?.cancellationBank ??
          (adaCatatanRefund ? bankName : null),
      cancellationAccountNumber: dariServer?.cancellationAccountNumber ??
          (adaCatatanRefund ? accountNumber : null),
      cancellationAccountName: dariServer?.cancellationAccountName ??
          (adaCatatanRefund ? accountHolderName : null),
      refundStatus: dariServer?.refundStatus,
      quotedAmount: dariServer?.quotedAmount ?? target.quotedAmount,
      finalAmount: dariServer?.finalAmount ?? target.finalAmount,
    );

    _bookingHistory[index] = updated;
    if (_activeBooking?.id == bookingId) {
      _activeBooking = updated;
    }
    await repository?.saveBooking(updated);
    notifyListeners();
    return null;
  }

  /// Membatalkan pesanan aktif secara cepat
  void cancelActiveBooking([String reason = 'Dibatalkan oleh pelanggan']) {
    if (_activeBooking != null) {
      cancelBooking(bookingId: _activeBooking!.id, reason: reason);
    }
  }

  /// Melengkapi rekening tujuan pengembalian dana untuk pesanan yang sudah batal.
  ///
  /// Mengembalikan `true` hanya bila server menyimpan rekeningnya. Saat server
  /// menolak (mis. baris sudah ditutup kantor) atau tidak terjangkau, data lokal
  /// tidak diubah supaya layar tidak menampilkan rekening yang belum tercatat.
  Future<bool> claimRefundAccount({
    required String bookingId,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    final index = _bookingHistory.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final hasil = await repository?.claimRefundAccountRemote(
      bookingId: bookingId,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolderName: accountHolderName,
    );
    if (hasil == null) return false;

    final target = _bookingHistory[index];
    final updated = target.copyWith(
      cancellationBank: bankName,
      cancellationAccountNumber: accountNumber,
      cancellationAccountName: accountHolderName,
      refundStatus: hasil['status']?.toString() ?? target.refundStatus,
    );

    _bookingHistory[index] = updated;
    if (_activeBooking?.id == bookingId) {
      _activeBooking = updated;
    }
    await repository?.saveBooking(updated);
    notifyListeners();
    return true;
  }

  /// Mengatur ulang pesanan aktif agar bernilai 0 / tidak ada
  void clearActiveBooking() {
    _activeBooking = null;
    notifyListeners();
  }

  /// Mengatur ulang seluruh riwayat dan pesanan aktif ke kondisi awal simulasi (0 pesanan aktif & 0 riwayat selesai)
  void resetToInitialState() {
    _bookingHistory.clear();
    _activeBooking = null;
    resetForm();
    notifyListeners();
  }

  /// Mengembalikan nilai formulir wizard ke konfigurasi awal
  void resetForm() {
    _resetFormTanpaNotifikasi();
    notifyListeners();
  }

  /// Isi [resetForm] tanpa memberi tahu pendengar.
  ///
  /// Dipakai saat sesi berakhir: pemanggilnya masih akan memberi tahu pendengar
  /// setelah seluruh pembaruan selesai, sehingga satu pergantian sesi tidak
  /// memicu dua pembangunan ulang layar yang sama.
  void _resetFormTanpaNotifikasi() {
    _selectedVehicle = null;
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = '09.00 WIT';
    _durationDays = 2;
    _withDriver = false;
    _pickupLocation = 'Bandara Mopah Merauke';
    _pickupAddress = '';
    _pickupLatitude = -8.5202;
    _pickupLongitude = 140.4180;
    _customerNote = '';
    _agreementChecked = false;
  }

  /// Khusus pengujian unit & widget: mengatur daftar riwayat pesanan secara eksplisit
  void setBookingsForTesting(List<BookingModel> bookings) {
    _bookingHistory.clear();
    _bookingHistory.addAll(bookings);
    notifyListeners();
  }
}
