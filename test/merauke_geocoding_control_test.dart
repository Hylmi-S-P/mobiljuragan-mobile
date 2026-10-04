import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobiljuragan_mobile/services/merauke_geocoding_service.dart';

void main() {
  // Pembanding: tanpa debounce, lima ketukan menghasilkan lima nama, bukan null.
  // Kalau hasilnya bukan null semua, berarti null di tes debounce memang
  // berasal dari mekanisme debounce dan bukan dari hal lain.
  test('tanpa debounce semua ketukan menghasilkan nama', () async {
    const rsudMerauke = LatLng(-8.4880, 140.3895);

    final results = await Future.wait([
      for (var i = 0; i < 5; i++)
        MeraukeGeocodingService.resolveLocationName(
          LatLng(rsudMerauke.latitude + i * 0.0001, rsudMerauke.longitude),
        ),
    ]);

    expect(results, everyElement(contains('RSUD Merauke')));
  });
}
