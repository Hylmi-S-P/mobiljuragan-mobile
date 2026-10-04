import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobiljuragan_mobile/services/merauke_geocoding_service.dart';

void main() {
  group('searchPois', () {
    test('kata kunci sebagian menemukan Bandara Mopah', () {
      final results = MeraukeGeocodingService.searchPois('bandara');

      expect(results, isNotEmpty);
      expect(results.first.name, 'Bandara Mopah Merauke');
    });

    test('kata kunci lengkap menempatkan hasil paling relevan di atas', () {
      final results = MeraukeGeocodingService.searchPois('bandara mopah');

      expect(results.first.name, 'Bandara Mopah Merauke');
    });

    test('pencarian tidak membedakan huruf besar dan kecil', () {
      final lower = MeraukeGeocodingService.searchPois('bandara');
      final upper = MeraukeGeocodingService.searchPois('BANDARA');

      expect(upper.map((p) => p.name), lower.map((p) => p.name));
    });

    test('alias bahasa Inggris tetap menemukan bandara', () {
      final results = MeraukeGeocodingService.searchPois('airport');

      expect(results.first.name, 'Bandara Mopah Merauke');
    });

    test('kata kunci yang tidak ada mengembalikan daftar kosong', () {
      expect(MeraukeGeocodingService.searchPois('stasiun luar angkasa'), isEmpty);
    });

    test('kata kunci kosong tidak mengembalikan seluruh daftar', () {
      expect(MeraukeGeocodingService.searchPois('   '), isEmpty);
    });

    test('semua kata kunci harus cocok, bukan sebagian saja', () {
      // 'bandara' ada, 'unmus' tidak: gabungan keduanya harus kosong,
      // supaya pencarian tidak diam-diam mengembalikan hasil yang salah.
      expect(MeraukeGeocodingService.searchPois('bandara unmus'), isEmpty);
    });
  });

  group('isInsideMerauke', () {
    test('titik pusat kota dianggap di dalam area', () {
      expect(MeraukeGeocodingService.isInsideMerauke(const LatLng(-8.4991, 140.4011)), isTrue);
    });

    test('Bandara Mopah masih di dalam area layanan', () {
      expect(MeraukeGeocodingService.isInsideMerauke(const LatLng(-8.5202, 140.4180)), isTrue);
    });

    test('Jakarta ditolak karena di luar area layanan', () {
      expect(MeraukeGeocodingService.isInsideMerauke(const LatLng(-6.2088, 106.8456)), isFalse);
    });

    test('titik di utara Merauke ditolak', () {
      expect(MeraukeGeocodingService.isInsideMerauke(const LatLng(-8.10, 140.40)), isFalse);
    });

    test('titik di selatan Merauke ditolak', () {
      expect(MeraukeGeocodingService.isInsideMerauke(const LatLng(-8.90, 140.40)), isFalse);
    });
  });
}
