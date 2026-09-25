import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';

/// Controller untuk mengelola katalog armada dan filter kategori kendaraan
class VehicleController extends ChangeNotifier {
  List<VehicleModel> _vehicles = VehicleModel.sampleVehicles;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  /// Daftar kategori yang tersedia untuk filter
  static const List<String> availableCategories = [
    'Semua',
    'MPV',
    'SUV',
    'Pickup',
  ];

  /// Getter untuk seluruh armada
  List<VehicleModel> get vehicles => _vehicles;

  /// Kategori yang sedang dipilih
  String get selectedCategory => _selectedCategory;

  /// Kata kunci pencarian saat ini
  String get searchQuery => _searchQuery;

  /// Daftar kendaraan yang sudah disaring berdasarkan kategori dan pencarian
  List<VehicleModel> get filteredVehicles {
    return _vehicles.where((vehicle) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          vehicle.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          vehicle.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vehicle.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Mengubah kategori armada aktif
  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  /// Mengubah kata kunci pencarian armada
  void setSearchQuery(String query) {
    _searchQuery = query;
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

  /// Memperbarui daftar armada dari sumber eksternal / API backend
  void updateVehicles(List<VehicleModel> newVehicles) {
    _vehicles = newVehicles;
    notifyListeners();
  }
}
