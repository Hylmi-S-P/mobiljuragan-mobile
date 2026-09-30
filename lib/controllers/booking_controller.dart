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
  String _customerNote = '';
  bool _agreementChecked = true;

  // Tarif layanan tetap sistem operasional MobilJuragan
  static const int driverCostPerDay = 150000;
  static const int standardServiceFee = 25000;

  // Status pesanan aktif dan daftar riwayat pesanan
  bool _hasActiveBooking = true;
  BookingModel? _activeBooking;
  final List<BookingModel> _bookingHistory = [];

  BookingController() {
    _initSampleData();
  }

  void _initSampleData() {
    final samples = BookingModel.initialSampleBookings;
    _bookingHistory.addAll(samples);
    if (_bookingHistory.isNotEmpty) {
      _activeBooking = _bookingHistory.first;
      _hasActiveBooking = _activeBooking?.status != BookingStatus.selesai &&
          _activeBooking?.status != BookingStatus.dibatalkan;
    }
  }

  // Getters Formulir Pemesanan
  VehicleModel? get selectedVehicle => _selectedVehicle;
  DateTime get selectedDate => _selectedDate;
  String get selectedTime => _selectedTime;
  int get durationDays => _durationDays;
  bool get withDriver => _withDriver;
  String get pickupLocation => _pickupLocation;
  String get customerNote => _customerNote;
  bool get agreementChecked => _agreementChecked;

  // Getters Status & Riwayat
  bool get hasActiveBooking => _hasActiveBooking;
  BookingModel? get activeBooking => _activeBooking;
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
  String get activeBookingCode => _activeBooking?.id ?? 'MBJ-2026-0042';

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

  void setPickupLocation(String location) {
    _pickupLocation = location;
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

    final newBooking = BookingModel(
      id: newOrderCode,
      vehicle: vehicle,
      startDate: _selectedDate,
      startTime: _selectedTime,
      durationDays: _durationDays,
      withDriver: _withDriver,
      pickupLocation: _pickupLocation,
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
    _hasActiveBooking = true;
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

  /// Simulasi konfirmasi pembayaran via WhatsApp admin
  /// Memindahkan status pesanan dari menungguPembayaran ke mobilSiapDigunakan (tahap selanjutnya)
  void confirmPaymentAndAdvance(String bookingId) {
    final index = _bookingHistory.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final updated = _bookingHistory[index].copyWith(
        status: BookingStatus.mobilSiapDigunakan,
      );
      _bookingHistory[index] = updated;
      if (_activeBooking?.id == bookingId) {
        _activeBooking = updated;
      }
      notifyListeners();
    }
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

    _hasActiveBooking = updated.status != BookingStatus.selesai &&
        updated.status != BookingStatus.dibatalkan;

    notifyListeners();
  }

  /// Memilih pesanan tertentu dari riwayat untuk dilihat detail statusnya
  void selectBookingForStatusView(BookingModel booking) {
    _activeBooking = booking;
    _hasActiveBooking = booking.status != BookingStatus.selesai &&
        booking.status != BookingStatus.dibatalkan;
    notifyListeners();
  }

  /// Membatalkan pesanan aktif
  void cancelActiveBooking() {
    if (_activeBooking != null) {
      updateActiveBookingStatus(BookingStatus.dibatalkan);
    }
    _hasActiveBooking = false;
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
    _customerNote = '';
    _agreementChecked = true;
    notifyListeners();
  }
}
