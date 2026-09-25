import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';

/// Controller terpusat untuk mengelola seluruh siklus pemesanan kendaraan
class BookingController extends ChangeNotifier {
  VehicleModel? _selectedVehicle = VehicleModel.sampleVehicles.first;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09.00 WIT';
  int _durationDays = 2;
  bool _withDriver = false;
  String _pickupLocation = 'Bandara Mopah Merauke';

  /// Status apakah ada pemesanan aktif yang sedang berlangsung
  bool _hasActiveBooking = false;
  String _activeBookingCode = 'MBJ-2026-0042';

  /// Tarif tambahan jasa pengemudi per hari di Merauke
  static const int driverCostPerDay = 150000;

  // Getters
  VehicleModel? get selectedVehicle => _selectedVehicle;
  DateTime get selectedDate => _selectedDate;
  String get selectedTime => _selectedTime;
  int get durationDays => _durationDays;
  bool get withDriver => _withDriver;
  String get pickupLocation => _pickupLocation;
  bool get hasActiveBooking => _hasActiveBooking;
  String get activeBookingCode => _activeBookingCode;

  /// Tarif harian unit mobil yang dipilih
  int get dailyRate => _selectedVehicle?.pricePerDay ?? 400000;

  /// Total biaya sewa mobil saja
  int get vehicleSubtotal => dailyRate * _durationDays;

  /// Total biaya tambahan jasa sopir
  int get driverSubtotal => _withDriver ? (driverCostPerDay * _durationDays) : 0;

  /// Total estimasi keseluruhan biaya rental
  int get totalEstimatedCost => vehicleSubtotal + driverSubtotal;

  /// Memilih armada kendaraan untuk disewa
  void selectVehicle(VehicleModel vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  /// Menentukan jadwal rental (tanggal, waktu penjemputan, durasi hari)
  void setSchedule({
    required DateTime date,
    required String time,
    required int durationDays,
  }) {
    _selectedDate = date;
    _selectedTime = time;
    _durationDays = durationDays;
    notifyListeners();
  }

  /// Mengubah opsi sopir (Lepas Kunci / Dengan Sopir)
  void toggleDriver(bool value) {
    if (_withDriver == value) return;
    _withDriver = value;
    notifyListeners();
  }

  /// Mengubah titik lokasi penjemputan armada
  void setPickupLocation(String location) {
    _pickupLocation = location;
    notifyListeners();
  }

  /// Melakukan konfirmasi pemesanan (mengaktifkan status sewa di Beranda)
  void confirmBooking({String? customCode}) {
    _hasActiveBooking = true;
    if (customCode != null && customCode.isNotEmpty) {
      _activeBookingCode = customCode;
    }
    notifyListeners();
  }

  /// Membatalkan atau menyelesaikan sewa aktif
  void cancelActiveBooking() {
    _hasActiveBooking = false;
    notifyListeners();
  }

  /// Mengembalikan state pemesanan ke kondisi awal
  void reset() {
    _selectedVehicle = VehicleModel.sampleVehicles.first;
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = '09.00 WIT';
    _durationDays = 2;
    _withDriver = false;
    _pickupLocation = 'Bandara Mopah Merauke';
    _hasActiveBooking = false;
    notifyListeners();
  }
}
