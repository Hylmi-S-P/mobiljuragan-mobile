import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Layanan API untuk konsumsi endpoint katalog armada dari backend
class VehicleApiService {
  final ApiClient _client;

  VehicleApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Mengambil daftar katalog armada kendaraan dari backend dengan filter ketersediaan jadwal
  Future<List<Map<String, dynamic>>> fetchCatalog({
    String? category,
    String? search,
    String? operationalStatus,
    String? transmission,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'semua' && category.toLowerCase() != 'favorit') {
      query['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    if (operationalStatus != null) {
      query['operationalStatus'] = operationalStatus;
    }
    if (transmission != null && transmission.isNotEmpty) {
      query['transmission'] = transmission;
    }
    if (startDate != null && endDate != null) {
      query['startDate'] = startDate.toUtc().toIso8601String();
      query['endDate'] = endDate.toUtc().toIso8601String();
    }

    final response = await _client.get(
      ApiConstants.vehiclesEndpoint,
      queryParams: query.isNotEmpty ? query : null,
    );

    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  /// Mengambil daftar kategori unik dari backend
  Future<List<String>> fetchCategories() async {
    final response = await _client.get(ApiConstants.vehicleCategoriesEndpoint);
    if (response is List) {
      return response.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// Mengambil detail armada by ID
  Future<Map<String, dynamic>?> fetchDetail(String id) async {
    final response = await _client.get('${ApiConstants.vehiclesEndpoint}/$id');
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }
}
