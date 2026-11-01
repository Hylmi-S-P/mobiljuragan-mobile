import '../network/api_client.dart';

/// Satu titik serah terima resmi dari backend.
class PickupPoint {
  final String id;
  final String label;
  final String? address;
  final double latitude;
  final double longitude;
  final bool isFree;

  const PickupPoint({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isFree,
  });

  factory PickupPoint.fromJson(Map<String, dynamic> json) {
    return PickupPoint(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Titik serah terima',
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isFree: json['isFree'] == true,
    );
  }
}

/// Layanan daftar titik serah terima.
///
/// Daftar ini berasal dari backend (`GET /pickup-points`) supaya mobile dan
/// dashboard memakai nama tempat yang sama. Sebelumnya mobile menyimpan daftar
/// sendiri lengkap dengan alamat karangan, dan label peta hasil reverse
/// geocoding bisa berbeda dari yang dipakai admin.
class PickupPointApiService {
  final ApiClient _client;

  PickupPointApiService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<List<PickupPoint>> fetchPickupPoints() async {
    final response = await _client.get('/pickup-points');
    if (response is Map) {
      final items = response['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((item) => PickupPoint.fromJson(Map<String, dynamic>.from(item)))
            .where((point) => point.label.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }
}
