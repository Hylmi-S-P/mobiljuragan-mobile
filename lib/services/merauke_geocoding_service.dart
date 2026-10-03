import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Model titik penting / landmark lokal Merauke
class MeraukePoi {
  final String name;
  final String road;
  final String category;
  final LatLng coords;

  const MeraukePoi({
    required this.name,
    required this.road,
    required this.category,
    required this.coords,
  });
}

/// Layanan Reverse Geocoding khusus Merauke
/// Mengubah koordinat (latitude & longitude) menjadi nama toko, sekolah, gedung, atau jalan
/// Menggunakan pendekatan hybrid: OpenStreetMap Nominatim Online + Database POI Lokal Merauke
class MeraukeGeocodingService {
  // Database POI & Fasilitas Umum Populer di Merauke
  static const List<MeraukePoi> _localPois = [
    // Sekolah & Kampus
    MeraukePoi(
      name: 'SD Negeri 1 Merauke',
      road: 'Jl. Brawijaya',
      category: 'Sekolah',
      coords: LatLng(-8.4935, 140.4010),
    ),
    MeraukePoi(
      name: 'SMP Negeri 1 Merauke',
      road: 'Jl. Brawijaya',
      category: 'Sekolah',
      coords: LatLng(-8.4920, 140.4005),
    ),
    MeraukePoi(
      name: 'SMP Negeri 2 Merauke',
      road: 'Jl. TMP',
      category: 'Sekolah',
      coords: LatLng(-8.4870, 140.3950),
    ),
    MeraukePoi(
      name: 'SMA Negeri 1 Merauke',
      road: 'Jl. Pendidikan',
      category: 'Sekolah',
      coords: LatLng(-8.4815, 140.3920),
    ),
    MeraukePoi(
      name: 'SMA Negeri 2 Merauke',
      road: 'Jl. Spadem',
      category: 'Sekolah',
      coords: LatLng(-8.4750, 140.4100),
    ),
    MeraukePoi(
      name: 'SMK Negeri 1 Merauke',
      road: 'Jl. Ermasu',
      category: 'Sekolah',
      coords: LatLng(-8.4890, 140.3880),
    ),
    MeraukePoi(
      name: 'Universitas Musamus (Unmus)',
      road: 'Jl. Kamizaun Mopah Lama',
      category: 'Kampus',
      coords: LatLng(-8.5130, 140.4280),
    ),

    // Fasilitas Kesehatan
    MeraukePoi(
      name: 'RSUD Merauke',
      road: 'Jl. Soekarjo Viryopranoto',
      category: 'Rumah Sakit',
      coords: LatLng(-8.4880, 140.3895),
    ),
    MeraukePoi(
      name: 'RS Bunda Pengharapan',
      road: 'Jl. Tujuh Wali-Wali',
      category: 'Rumah Sakit',
      coords: LatLng(-8.5020, 140.4120),
    ),
    MeraukePoi(
      name: 'RSAL Merauke',
      road: 'Jl. Mayor Wiratno',
      category: 'Rumah Sakit',
      coords: LatLng(-8.4790, 140.3830),
    ),
    MeraukePoi(
      name: 'Puskesmas Rimba Jaya',
      road: 'Jl. Rimba Jaya',
      category: 'Puskesmas',
      coords: LatLng(-8.4720, 140.4050),
    ),

    // Transportasi & Akomodasi
    MeraukePoi(
      name: 'Bandara Mopah Merauke',
      road: 'Lobi Kedatangan Bandara Mopah',
      category: 'Bandara',
      coords: LatLng(-8.5202, 140.4180),
    ),
    MeraukePoi(
      name: 'Swiss-Belhotel Merauke',
      road: 'Jl. Raya Mandala No. 53',
      category: 'Hotel',
      coords: LatLng(-8.4845, 140.3878),
    ),
    MeraukePoi(
      name: 'Hotel Grand Merauke',
      road: 'Jl. Raya Mandala No. 12',
      category: 'Hotel',
      coords: LatLng(-8.4950, 140.4020),
    ),
    MeraukePoi(
      name: 'Pool Kantor MobilJuragan',
      road: 'Jl. Brawijaya No. 88',
      category: 'Pool Garasi',
      coords: LatLng(-8.4905, 140.3995),
    ),
    MeraukePoi(
      name: 'Pelabuhan Merauke',
      road: 'Jl. Yos Sudarso',
      category: 'Pelabuhan',
      coords: LatLng(-8.4680, 140.3800),
    ),

    // Tempat Belanja & Fasilitas Umum
    MeraukePoi(
      name: 'Pasar Wamanggu Merauke',
      road: 'Jl. Belakang Pasar',
      category: 'Pasar',
      coords: LatLng(-8.4830, 140.3860),
    ),
    MeraukePoi(
      name: 'Taman Kapsul Waktu Merauke',
      road: 'Jl. Raya Mandala',
      category: 'Monumen Publik',
      coords: LatLng(-8.4910, 140.3910),
    ),
    MeraukePoi(
      name: 'Tugu Lingkaran Brawijaya',
      road: 'Jl. Brawijaya Pusat Kota',
      category: 'Tugu Landmark',
      coords: LatLng(-8.4991, 140.4011),
    ),
    MeraukePoi(
      name: 'Masjid Raya Al-Aqsha Merauke',
      road: 'Jl. Raya Mandala',
      category: 'Tempat Ibadah',
      coords: LatLng(-8.4855, 140.3885),
    ),
    MeraukePoi(
      name: 'Katedral Santo Fransiskus Xaverius',
      road: 'Jl. Brawijaya',
      category: 'Tempat Ibadah',
      coords: LatLng(-8.4915, 140.4000),
    ),
    MeraukePoi(
      name: 'Kantor Bupati Merauke',
      road: 'Jl. Brawijaya',
      category: 'Kantor Pemerintahan',
      coords: LatLng(-8.4960, 140.4030),
    ),
    MeraukePoi(
      name: 'Pantai Lampu Satu',
      road: 'Kawasan Pesisir Lampu Satu',
      category: 'Wisata Pantai',
      coords: LatLng(-8.5280, 140.3700),
    ),
  ];

  // Koridor jalan utama di Merauke berdasarkan koordinat terdekat
  static const List<Map<String, dynamic>> _majorRoads = [
    {
      'name': 'Jl. Brawijaya',
      'coords': LatLng(-8.4940, 140.4010),
    },
    {
      'name': 'Jl. Raya Mandala',
      'coords': LatLng(-8.4870, 140.3920),
    },
    {
      'name': 'Jl. Ahmad Yani',
      'coords': LatLng(-8.4980, 140.3980),
    },
    {
      'name': 'Jl. Yos Sudarso',
      'coords': LatLng(-8.4730, 140.3820),
    },
    {
      'name': 'Jl. Mayor Wiratno',
      'coords': LatLng(-8.4800, 140.3840),
    },
    {
      'name': 'Jl. Ermasu',
      'coords': LatLng(-8.4900, 140.3870),
    },
    {
      'name': 'Jl. TMP (Trikora)',
      'coords': LatLng(-8.4850, 140.3960),
    },
    {
      'name': 'Jl. Polder',
      'coords': LatLng(-8.4780, 140.4020),
    },
    {
      'name': 'Jl. Spadem',
      'coords': LatLng(-8.4730, 140.4120),
    },
    {
      'name': 'Jl. Poros Mopah',
      'coords': LatLng(-8.5150, 140.4200),
    },
    {
      'name': 'Jl. Rimba Jaya',
      'coords': LatLng(-8.4700, 140.4070),
    },
  ];

  // Cache memori agar koordinat yang sama tidak di-request berulang
  static final Map<String, String> _cache = {};

  /// Mengubah koordinat LatLng menjadi nama lokasi manusiawi
  static Future<String> resolveLocationName(LatLng coords) async {
    final cacheKey = '${coords.latitude.toStringAsFixed(4)},${coords.longitude.toStringAsFixed(4)}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 1. Cek kecocokan instan dengan POI lokal Merauke jika jarak < 300 meter
    final nearestPoi = _findNearestPoi(coords);
    if (nearestPoi != null && nearestPoi.distanceMeters <= 300) {
      final poi = nearestPoi.poi;
      final resultName = '${poi.name}, ${poi.road}';
      _cache[cacheKey] = resultName;
      return resultName;
    }

    // 2. Coba Reverse Geocoding online via OpenStreetMap Nominatim
    try {
      final onlineName = await _fetchNominatimReverseGeocode(coords);
      if (onlineName != null && onlineName.isNotEmpty) {
        _cache[cacheKey] = onlineName;
        return onlineName;
      }
    } catch (_) {
      // Abaikan jika offline / timeout, lanjutkan ke fallback lokal
    }

    // 3. Fallback cerdas berbasis jarak POI terdekat (< 650m) atau koridor jalan Merauke
    if (nearestPoi != null && nearestPoi.distanceMeters <= 650) {
      final poi = nearestPoi.poi;
      final resultName = 'Dekat ${poi.name} (${poi.road})';
      _cache[cacheKey] = resultName;
      return resultName;
    }

    final nearestRoad = _findNearestRoad(coords);
    if (nearestRoad != null) {
      final resultName = 'Area $nearestRoad, Merauke';
      _cache[cacheKey] = resultName;
      return resultName;
    }

    // 4. Fallback umum Merauke Kota
    final fallback = 'Merauke Kota (${coords.latitude.toStringAsFixed(3)}, ${coords.longitude.toStringAsFixed(3)})';
    _cache[cacheKey] = fallback;
    return fallback;
  }

  /// Panggilan HTTP ke OpenStreetMap Nominatim dengan batas waktu 2.5 detik
  static Future<String?> _fetchNominatimReverseGeocode(LatLng coords) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 2);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coords.latitude}&lon=${coords.longitude}&zoom=18&addressdetails=1',
      );

      final request = await client.getUrl(uri).timeout(const Duration(seconds: 2));
      request.headers.set('User-Agent', 'MobilJuragan-Mobile/1.0 (contact@mobiljuragan.com)');
      request.headers.set('Accept-Language', 'id');

      final response = await request.close().timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;

        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          // Cari nama tempat / gedung khusus (sekolah, toko, hotel, fasilitas)
          final buildingOrAmenity = address['amenity'] ??
              address['shop'] ??
              address['building'] ??
              address['school'] ??
              address['hotel'] ??
              address['tourism'] ??
              address['hospital'];

          final road = address['road'] ?? address['residential'] ?? address['pedestrian'];
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['village'] ?? address['city'];

          if (buildingOrAmenity != null && road != null) {
            return '$buildingOrAmenity, $road';
          } else if (buildingOrAmenity != null) {
            return '$buildingOrAmenity, Merauke';
          } else if (road != null && suburb != null) {
            return '$road, $suburb';
          } else if (road != null) {
            return '$road, Merauke';
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          // Ambil 2 bagian pertama dari display_name agar ringkas
          final parts = displayName.split(',').map((p) => p.trim()).toList();
          if (parts.length >= 2) {
            return '${parts[0]}, ${parts[1]}';
          }
          return parts[0];
        }
      }
    } finally {
      client.close();
    }

    return null;
  }

  /// Menghitung jarak perkiraan (Haversine formula dalam meter)
  static double _calculateDistanceMeters(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0; // meter
    final dLat = (p2.latitude - p1.latitude) * pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * pi / 180.0;

    final lat1 = p1.latitude * pi / 180.0;
    final lat2 = p2.latitude * pi / 180.0;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static ({MeraukePoi poi, double distanceMeters})? _findNearestPoi(LatLng point) {
    MeraukePoi? bestPoi;
    double minDistance = double.infinity;

    for (final poi in _localPois) {
      final dist = _calculateDistanceMeters(point, poi.coords);
      if (dist < minDistance) {
        minDistance = dist;
        bestPoi = poi;
      }
    }

    if (bestPoi != null) {
      return (poi: bestPoi, distanceMeters: minDistance);
    }
    return null;
  }

  static String? _findNearestRoad(LatLng point) {
    String? bestRoad;
    double minDistance = double.infinity;

    for (final road in _majorRoads) {
      final coords = road['coords'] as LatLng;
      final dist = _calculateDistanceMeters(point, coords);
      if (dist < minDistance) {
        minDistance = dist;
        bestRoad = road['name'] as String;
      }
    }

    // Jika dalam radius 1.5 km dari koridor jalan
    if (minDistance <= 1500) {
      return bestRoad;
    }
    return null;
  }
}
