import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobiljuragan_mobile/services/merauke_geocoding_service.dart';

void main() {
  // Koordinat di RSUD Merauke: cukup dekat dengan POI lokal sehingga
  // penyelesaian nama tidak menyentuh jaringan dan tes tetap deterministik.
  const rsudMerauke = LatLng(-8.4880, 140.3895);

  test('ketukan beruntun hanya menyelesaikan ketukan terakhir', () async {
    final futures = <Future<String?>>[];
    for (var i = 0; i < 5; i++) {
      futures.add(
        MeraukeGeocodingService.resolveLocationNameDebounced(
          LatLng(rsudMerauke.latitude + i * 0.0001, rsudMerauke.longitude),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    final results = await Future.wait(futures);

    expect(
      results.sublist(0, 4),
      everyElement(isNull),
      reason: 'ketukan yang tersusul harus berhenti menunggu, bukan ikut memanggil Nominatim',
    );
    expect(
      results.last,
      contains('RSUD Merauke'),
      reason: 'ketukan terakhir tetap harus menghasilkan nama lokasi',
    );
  });

  test('ketukan tunggal tetap menghasilkan nama lokasi', () async {
    final name = await MeraukeGeocodingService.resolveLocationNameDebounced(rsudMerauke);

    expect(name, contains('RSUD Merauke'));
  });

  test('ketukan yang berjarak lebih dari delay tidak saling membatalkan', () async {
    final first = MeraukeGeocodingService.resolveLocationNameDebounced(rsudMerauke);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final second = MeraukeGeocodingService.resolveLocationNameDebounced(
      const LatLng(-8.4935, 140.4010),
    );

    expect(await first, contains('RSUD Merauke'));
    expect(await second, contains('SD Negeri 1 Merauke'));
  });
}
