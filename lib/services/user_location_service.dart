import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'merauke_geocoding_service.dart';

/// Hasil pengambilan lokasi perangkat, sekaligus alasan kegagalannya.
/// Pemanggil memakai [status] untuk memutuskan pesan yang ditampilkan,
/// sehingga widget tidak perlu menebak dari nilai null.
enum UserLocationStatus {
  success,

  /// GPS mati di tingkat sistem.
  serviceDisabled,

  /// Pengguna menolak izin, tetapi masih bisa diminta ulang.
  permissionDenied,

  /// Pengguna menolak permanen; hanya bisa dibuka lewat Setelan.
  permissionDeniedForever,

  /// Izin ada, tetapi koordinat gagal didapat (misalnya di dalam gedung).
  unavailable,

  /// Koordinat didapat, tetapi di luar area layanan Merauke.
  outsideServiceArea,
}

class UserLocationResult {
  final UserLocationStatus status;
  final LatLng? coords;

  const UserLocationResult(this.status, {this.coords});

  bool get isSuccess => status == UserLocationStatus.success;
}

class UserLocationService {
  // Membatasi waktu tunggu supaya tombol tidak menggantung tanpa akhir
  // saat perangkat tidak kunjung memberi fix lokasi.
  static const Duration _timeout = Duration(seconds: 10);

  static Future<UserLocationResult> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const UserLocationResult(UserLocationStatus.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const UserLocationResult(UserLocationStatus.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const UserLocationResult(UserLocationStatus.permissionDeniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );

      final coords = LatLng(position.latitude, position.longitude);
      if (!MeraukeGeocodingService.isInsideMerauke(coords)) {
        return UserLocationResult(UserLocationStatus.outsideServiceArea, coords: coords);
      }

      return UserLocationResult(UserLocationStatus.success, coords: coords);
    } catch (_) {
      return const UserLocationResult(UserLocationStatus.unavailable);
    }
  }

  /// Membuka halaman Setelan aplikasi, dipakai saat izin ditolak permanen.
  static Future<void> openAppSettings() => Geolocator.openAppSettings();
}
