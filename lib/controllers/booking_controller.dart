import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';

/// Controller terpusat untuk mengelola seluruh siklus pemesanan kendaraan pelanggan
class BookingController extends ChangeNotifier {
  // Data formulir wizard pemesanan
  VehicleModel? _selectedVehicle = VehicleModel.sampleVehicles.first;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09.00 WIT';
  int _durationDays = 2;
  bool _withDriver = false;
  String _pickupLocation = 'Bandara Mopah Merauke';
  double? _pickupLatitude = -8.5202;
  double? _pickupLongitude = 140.4180;
  String _customerNote = '';
  bool _agreementChecked = true;

  // Tarif layanan tetap sistem operasional MobilJuragan
  static const int driverCostPerDay = 150000;
  static const int standardServiceFee = 25000;

  // Status pesanan aktif dan daftar riwayat pesanan
  BookingModel? _activeBooking;
  final List<BookingModel> _bookingHistory = [];

  BookingController() {
    _initSampleData();
  }

  void _initSampleData() {
    _bookingHistory.clear();
    final samples = BookingModel.initialSampleBookings;
    _bookingHistory.addAll(samples);
    // Pesanan aktif dan riwayat pesanan diatur 0 / kosong pada awal aplikasi
    _activeBooking = null;
  }

  // Getters Formulir Pemesanan
  VehicleModel? get selectedVehicle => _selectedVehicle;
  DateTime get selectedDate => _selectedDate;
  String get selectedTime => _selectedTime;
  int get durationDays => _durationDays;
  bool get withDriver => _withDriver;
  String get pickupLocation => _pickupLocation;
  double? get pickupLatitude => _pickupLatitude;
  double? get pickupLongitude => _pickupLongitude;
  String get customerNote => _customerNote;
  bool get agreementChecked => _agreementChecked;

  // Getters Status & Riwayat
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
      .where((b) =>
          b.status != BookingStatus.selesai && b.status != BookingStatus.dibatalkan)
      .toList();

  List<BookingModel> get completedBookings => _bookingHistory
      .where((b) =>
          b.status == BookingStatus.selesai || b.status == BookingStatus.dibatalkan)
      .toList();

  // Kalkulasi Biaya Terhitung Resmi (Sistem Dashboard Admin)
  int get dailyRate => _selectedVehicle?.pricePerDay ?? 400000;
  int get vehicleSubtotal => dailyRate * _durationDays;
  int get driverSubtotal => _withDriver ? (driverCostPerDay * _durationDays) : 0;
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
    _durationDays = durationDays.clamp(1, 30);
    notifyListeners();
  }

  void setDurationDays(int days) {
    _durationDays = days.clamp(1, 30);
    notifyListeners();
  }

  void toggleDriver(bool value) {
    if (_withDriver == value) return;
    _withDriver = value;
    notifyListeners();
  }

  void setPickupLocation(String location, [double? lat, double? lng]) {
    _pickupLocation = location;
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
  BookingModel submitBooking() {
    final newOrderCode = 'MBJ-2026-${(43 + _bookingHistory.length).toString().padLeft(4, '0')}';
    final vehicle = _selectedVehicle ?? VehicleModel.sampleVehicles.first;

    // Alokasi staf sopir internal jika memilih Dengan Sopir
    final assignedDriver = _withDriver
        ? const DriverAssignment(
            driverName: 'Bung Yohanes Mahuze',
            staffId: 'STF-DRV-014',
            phoneNumber: '0812-4822-9901',
            operationalRole: 'Staf Pengemudi Tetap MobilJuragan Merauke',
          )
        : null;

    final newBooking = BookingModel(
      id: newOrderCode,
      vehicle: vehicle,
      startDate: _selectedDate,
      startTime: _selectedTime,
      durationDays: _durationDays,
      withDriver: _withDriver,
      pickupLocation: _pickupLocation,
      pickupLatitude: _pickupLatitude,
      pickupLongitude: _pickupLongitude,
      assignedDriver: assignedDriver,
      note: _customerNote.isNotEmpty ? _customerNote : null,
      status: BookingStatus.menungguTarifFinal,
      createdAt: DateTime.now(),
      dailyRate: vehicle.pricePerDay,
      serviceFee: standardServiceFee,
      adminAdjustments: const [],
      isFinalTariffConfirmed: false,
    );

    _bookingHistory.insert(0, newBooking);
    _activeBooking = newBooking;
    notifyListeners();
    return newBooking;
  }

  /// Simulasi konfirmasi rincian tarif final oleh admin dari dashboard website
  /// Menambahkan penyesuaian biaya operasional, deposit, dan diskon serta memindahkan status ke menungguPembayaran
  void confirmFinalTariffFromAdmin([List<BookingFeeAdjustment>? customAdjustments]) {
    if (_activeBooking == null) return;
    final adjustments = customAdjustments ?? BookingModel.standardAdminAdjustments;
    final updated = _activeBooking!.copyWith(
      status: BookingStatus.menungguPembayaran,
      adminAdjustments: adjustments,
      isFinalTariffConfirmed: true,
    );
    _activeBooking = updated;

    final index = _bookingHistory.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _bookingHistory[index] = updated;
    }

    notifyListeners();
  }

  /// Memproses pemilihan metode pembayaran Tunai di Tempat (COD)
  /// Status langsung beralih ke mobilSiapDigunakan dan E-Ticket terbit dengan tanda COD
  void confirmCodPayment(String bookingId) {
    final index = _bookingHistory.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final updated = _bookingHistory[index].copyWith(
        paymentMethodType: PaymentMethodType.tunaiDiTempat,
        status: BookingStatus.mobilSiapDigunakan,
      );
      _bookingHistory[index] = updated;
      if (_activeBooking?.id == bookingId) {
        _activeBooking = updated;
      }
      notifyListeners();
    }
  }

  /// Memproses pelunasan pembayaran online (QRIS / Virtual Account simulasi otomatis)
  /// Status beralih ke mobilSiapDigunakan dengan bukti referensi transaksi dan E-Ticket resmi
  void completeOnlinePayment({
    required String bookingId,
    required PaymentMethodType paymentMethod,
    String? referenceCode,
  }) {
    final index = _bookingHistory.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final ref = referenceCode ??
          'TRX-MBJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final updated = _bookingHistory[index].copyWith(
        paymentMethodType: paymentMethod,
        status: BookingStatus.mobilSiapDigunakan,
        paidAt: DateTime.now(),
        paymentReference: ref,
      );
      _bookingHistory[index] = updated;
      if (_activeBooking?.id == bookingId) {
        _activeBooking = updated;
      }
      notifyListeners();
    }
  }

  /// Simulasi konfirmasi pembayaran via WhatsApp admin (kompatibilitas alur manual)
  void confirmPaymentAndAdvance(String bookingId) {
    completeOnlinePayment(
      bookingId: bookingId,
      paymentMethod: PaymentMethodType.qrisOtomatis,
    );
  }

  /// Alias metode konfirmasi pemesanan untuk kompatibilitas alur terdahulu
  void confirmBooking() {
    submitBooking();
  }

  /// Mengubah status pesanan aktif untuk simulasi demonstrasi pengujian (Demo Tester UAS)
  void updateActiveBookingStatus(BookingStatus newStatus) {
    if (_activeBooking == null) return;
    final updated = _activeBooking!.copyWith(status: newStatus);
    _activeBooking = updated;

    final index = _bookingHistory.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _bookingHistory[index] = updated;
    }

    notifyListeners();
  }

  /// Memilih pesanan tertentu dari riwayat untuk dilihat detail statusnya
  void selectBookingForStatusView(BookingModel booking) {
    _activeBooking = booking;
    notifyListeners();
  }

  /// Membatalkan pesanan (baik pesanan aktif maupun pesanan spesifik berdasarkan ID)
  /// Menerapkan aturan pengembalian dana 85% untuk pesanan online yang telah dibayar.
  /// Untuk pesanan COD yang belum diserahkan uangnya, refund bernilai Rp 0 tanpa potongan penalti.
  void cancelBooking({
    required String bookingId,
    required String reason,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
  }) {
    final index = _bookingHistory.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    final target = _bookingHistory[index];
    final bool isCod = target.paymentMethodType == PaymentMethodType.tunaiDiTempat;
    final bool isPaidBooking = !isCod &&
        (target.status == BookingStatus.pembayaranSelesai ||
            target.status == BookingStatus.verifikasiKantor ||
            target.status == BookingStatus.mobilSiapDigunakan);

    final double refundRate = isPaidBooking ? 0.85 : 0.0;
    final int refundAmount = isPaidBooking ? (target.totalCost * 0.85).round() : 0;

    final updated = target.copyWith(
      status: BookingStatus.dibatalkan,
      cancellationReason: reason,
      cancelledAt: DateTime.now(),
      cancellationRefundRate: refundRate,
      cancellationRefundAmount: refundAmount,
      cancellationBank: isPaidBooking ? bankName : null,
      cancellationAccountNumber: isPaidBooking ? accountNumber : null,
      cancellationAccountName: isPaidBooking ? accountHolderName : null,
    );

    _bookingHistory[index] = updated;
    if (_activeBooking?.id == bookingId) {
      _activeBooking = updated;
    }
    notifyListeners();
  }

  /// Membatalkan pesanan aktif secara cepat
  void cancelActiveBooking([String reason = 'Dibatalkan oleh pelanggan']) {
    if (_activeBooking != null) {
      cancelBooking(
        bookingId: _activeBooking!.id,
        reason: reason,
      );
    }
  }

  /// Mengatur ulang pesanan aktif agar bernilai 0 / tidak ada
  void clearActiveBooking() {
    _activeBooking = null;
    notifyListeners();
  }

  /// Mengatur ulang seluruh riwayat dan pesanan aktif ke kondisi awal simulasi (0 pesanan aktif & 0 riwayat selesai)
  void resetToInitialState() {
    _bookingHistory.clear();
    _bookingHistory.addAll(BookingModel.initialSampleBookings);
    _activeBooking = null;
    resetForm();
    notifyListeners();
  }

  /// Mengembalikan nilai formulir wizard ke konfigurasi awal
  void resetForm() {
    _selectedVehicle = VehicleModel.sampleVehicles.first;
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = '09.00 WIT';
    _durationDays = 2;
    _withDriver = false;
    _pickupLocation = 'Bandara Mopah Merauke';
    _pickupLatitude = -8.5202;
    _pickupLongitude = 140.4180;
    _customerNote = '';
    _agreementChecked = true;
    notifyListeners();
  }
}
