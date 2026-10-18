import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/local/preferences/app_settings_service.dart';
import '../data/repositories/vehicle_repository.dart';
import '../models/vehicle_model.dart';

/// Controller untuk mengelola katalog armada, filter kategori, pencarian,
/// dan status favorit kendaraan secara reaktif dari database Drift lokal (Offline-First).
class VehicleController extends ChangeNotifier {
  final VehicleRepository? _repository;
  final AppSettingsService? _settingsService;

  List<VehicleModel> _vehicles = VehicleModel.sampleVehicles;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isSyncing = false;
  StreamSubscription<List<VehicleModel>>? _vehiclesSubscription;

  /// Daftar kategori yang tersedia untuk filter (termasuk filter interaktif Favorit)
  static const List<String> availableCategories = [
    'Semua',
    'Favorit',
    'MPV',
    'SUV',
    'Pickup',
  ];

  VehicleController({
    VehicleRepository? repository,
    AppSettingsService? settingsService,
  })  : _repository = repository,
        _settingsService = settingsService {
    _init();
  }

  Future<void> _init() async {
    // Muat preferensi filter kategori yang tersimpan di SharedPreferences
    final settings = _settingsService;
    if (settings != null) {
      _selectedCategory = settings.getSelectedCategory();
    }

    final repo = _repository;
    if (repo != null) {
      // Pastikan database lokal memiliki seed awal
      await repo.ensureSeeded();

      // Berlangganan Stream reaktif Drift (.watch())
      // Setiap kali ada penulisan data di SQLite lokal (API sync / toggle favorit), UI langsung terupdate!
      _vehiclesSubscription = repo.watchVehicles().listen((updatedVehicles) {
        if (updatedVehicles.isNotEmpty) {
          _vehicles = updatedVehicles;
          notifyListeners();
        }
      });

      // Lakukan sinkronisasi background jika koneksi tersedia
      unawaited(refreshCatalog(force: false));
    }
  }

  /// Getter untuk seluruh armada
  List<VehicleModel> get vehicles => _vehicles;

  /// Jumlah total unit armada
  int get totalFleetCount => _vehicles.length;

  /// Jumlah armada yang ditandai favorit
  int get favoriteCount => _vehicles.where((v) => v.isFavorite).length;

  /// Kategori yang sedang dipilih
  String get selectedCategory => _selectedCategory;

  /// Kata kunci pencarian saat ini
  String get searchQuery => _searchQuery;

  /// Indikator sedang melakukan sinkronisasi backend
  bool get isSyncing => _isSyncing;

  /// Waktu sinkronisasi data terakhir
  DateTime? get lastSyncTime {
    final millis = _settingsService?.getLastSyncTime();
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  /// Daftar riwayat pencarian dari SharedPreferences
  List<String> get recentSearches => _settingsService?.getSearchHistory() ?? [];

  /// Daftar kendaraan yang sudah disaring berdasarkan kategori, favorit, dan pencarian
  List<VehicleModel> get filteredVehicles {
    return _vehicles.where((vehicle) {
      final matchesCategory = _selectedCategory == 'Semua'
          ? true
          : (_selectedCategory == 'Favorit'
              ? vehicle.isFavorite
              : vehicle.category.toLowerCase() == _selectedCategory.toLowerCase());

      final matchesSearch = _searchQuery.isEmpty ||
          vehicle.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vehicle.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Menghitung jumlah armada pilihan lainnya di luar armada yang sedang dipilih
  int getOtherVehiclesCount(String selectedId) {
    final count = _vehicles.where((v) => v.id != selectedId).length;
    return count > 0 ? count : 0;
  }

  /// Mengubah kategori armada aktif & menyimpannya ke SharedPreferences
  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _settingsService?.setSelectedCategory(category);
    notifyListeners();
  }

  /// Mengubah kata kunci pencarian armada & menyimpan riwayat ke SharedPreferences
  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.trim().isNotEmpty) {
      _settingsService?.addSearchQuery(query.trim());
    }
    notifyListeners();
  }

  /// Mencari data armada berdasarkan ID
  VehicleModel? getById(String id) {
    try {
      return _vehicles.firstWhere((vehicle) => vehicle.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fitur Interaktif Reaktif: Toggle bookmark / favorit armada
  /// Perubahan disimpan ke Drift SQLite dan disiarkan ke seluruh layar secara instan
  Future<void> toggleFavorite(String vehicleId) async {
    // Optimistic UI update lokal untuk responsivitas seketika
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final current = _vehicles[index];
      _vehicles[index] = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
    }

    // Persist ke Drift database lokal
    final repo = _repository;
    if (repo != null) {
      await repo.toggleFavorite(vehicleId);
    }
  }

  /// Sinkronisasi manual / pull-to-refresh dari backend
  Future<void> refreshCatalog({bool force = true}) async {
    final repo = _repository;
    if (repo == null) return;
    _isSyncing = true;
    notifyListeners();

    try {
      await repo.syncFromBackend(force: force);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Memperbarui daftar armada secara langsung (untuk keperluan testing / mock)
  void updateVehicles(List<VehicleModel> newVehicles) {
    _vehicles = newVehicles;
    notifyListeners();
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    super.dispose();
  }
}
