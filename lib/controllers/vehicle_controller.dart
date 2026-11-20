import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/preferences/app_settings_service.dart';
import '../data/repositories/vehicle_repository.dart';
import '../models/vehicle_model.dart';

/// Controller untuk mengelola katalog armada, filter kategori, pencarian,
/// dan status favorit kendaraan secara reaktif dari database Drift lokal
/// (Offline-First).
///
/// Penanda favorit sekarang milik akun, bukan milik perangkat, sehingga
/// controller ikut memperhatikan pemilik sesi yang aktif. Saat pemilik berganti,
/// langganan stream dipasang ulang agar status favorit yang tampil selalu milik
/// akun yang sedang masuk.
class VehicleController extends ChangeNotifier {
  final VehicleRepository? repository;
  final AppSettingsService? settingsService;

  List<VehicleModel> _vehicles = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isSyncing = false;
  StreamSubscription<List<VehicleModel>>? _vehiclesSubscription;

  /// Pemilik sesi yang sedang dipakai untuk membaca status favorit.
  String? _userId;

  /// Daftar kategori yang tersedia untuk filter (termasuk filter interaktif Favorit)
  static const List<String> availableCategories = [
    'Semua',
    'Favorit',
    'MPV',
    'SUV',
    'Pickup',
    'Commercial',
  ];

  VehicleController({
    this.repository,
    this.settingsService,
    String? idPemilik,
  }) : _userId = idPemilik {
    _init();
  }

  Future<void> _init() async {
    // Muat preferensi filter kategori yang tersimpan di SharedPreferences
    final settings = settingsService;
    if (settings != null) {
      _selectedCategory = settings.getSelectedCategory();
    }

    final repo = repository;
    if (repo != null) {
      await _pasangLanggananArmada(repo);

      // Lakukan sinkronisasi background jika koneksi tersedia
      unawaited(refreshCatalog(force: true));
    }
  }

  /// Memasang langganan stream armada untuk pemilik aktif.
  ///
  /// Langganan lama dibatalkan lebih dulu supaya tidak ada dua stream yang
  /// saling menimpa daftar armada saat pemilik berganti.
  Future<void> _pasangLanggananArmada(VehicleRepository repo) async {
    await _vehiclesSubscription?.cancel();
    _vehiclesSubscription = repo
        .watchVehicles(userId: _userId)
        .listen((updatedVehicles) {
      if (updatedVehicles.isNotEmpty) {
        _vehicles = updatedVehicles;
        notifyListeners();
      }
    });
  }

  /// Pemilik sesi yang sedang dipakai controller ini.
  String? get userId => _userId;

  /// Menyesuaikan controller dengan pemilik sesi yang baru.
  ///
  /// Dipanggil dari `main.dart` setiap kali `AuthController` memberi tahu
  /// perubahan sesi. Kalau pemiliknya sama, tidak ada yang dikerjakan.
  Future<void> syncIfSessionChanged(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;

    final repo = repository;
    if (repo == null) {
      notifyListeners();
      return;
    }

    await repo.refreshSession();
    await _pasangLanggananArmada(repo);
    notifyListeners();
  }

  /// Daftar seluruh unit armada
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
    final millis = settingsService?.getLastSyncTime();
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  /// Daftar riwayat pencarian dari SharedPreferences
  List<String> get recentSearches => settingsService?.getSearchHistory() ?? [];

  /// Daftar kendaraan yang sudah disaring berdasarkan kategori, favorit, dan pencarian
  List<VehicleModel> get filteredVehicles {
    return _vehicles.where((vehicle) {
      final matchesCategory = _selectedCategory == 'Semua'
          ? true
          : (_selectedCategory == 'Favorit'
                ? vehicle.isFavorite
                : vehicle.category.toLowerCase() ==
                      _selectedCategory.toLowerCase());

      final matchesSearch =
          _searchQuery.isEmpty ||
          vehicle.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vehicle.plateNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

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
    settingsService?.setSelectedCategory(category);
    notifyListeners();
  }

  /// Mengubah kata kunci pencarian armada & menyimpan riwayat ke SharedPreferences
  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.trim().isNotEmpty) {
      settingsService?.addSearchQuery(query.trim());
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
  ///
  /// Perubahan disimpan ke Drift SQLite dan disiarkan ke seluruh layar secara
  /// instan. Penandanya diikat ke pemilik aktif, jadi akun lain di perangkat
  /// yang sama tidak ikut berubah.
  Future<void> toggleFavorite(String vehicleId) async {
    // Optimistic UI update lokal untuk responsivitas seketika
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final current = _vehicles[index];
      _vehicles[index] = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
    }

    // Persist ke Drift database lokal
    final repo = repository;
    if (repo != null) {
      await repo.toggleFavorite(vehicleId, userId: _userId);
    }
  }

  /// Sinkronisasi manual / pull-to-refresh dari backend
  Future<void> refreshCatalog({bool force = true}) async {
    final repo = repository;
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
