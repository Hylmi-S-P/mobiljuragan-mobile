import '../network/api_client.dart';

/// Pengaturan publik dari backend (`GET /config`).
///
/// Angka tarif jasa supir berlaku global dan bisa diubah admin. Aplikasi tidak
/// boleh mengarang angka sendiri: perkiraan di layar pelanggan harus memakai
/// tarif yang sama dengan yang dipakai server saat menagih.
class AppConfig {
  /// Tarif jasa supir per hari.
  final int driverDailyRate;

  /// Jam buka layanan dalam menit sejak tengah malam (06.00 WIT).
  final int serviceOpenMinute;

  /// Jam tutup layanan dalam menit sejak tengah malam (22.00 WIT).
  final int serviceCloseMinute;

  const AppConfig({
    required this.driverDailyRate,
    required this.serviceOpenMinute,
    required this.serviceCloseMinute,
  });

  /// Nilai cadangan saat server belum sempat dihubungi.
  ///
  /// Dipakai hanya supaya layar tidak menampilkan nol; angka ini tidak pernah
  /// dikirim ke server, jadi tagihan tetap dihitung server.
  static const AppConfig fallback = AppConfig(
    driverDailyRate: 150000,
    serviceOpenMinute: 6 * 60,
    serviceCloseMinute: 22 * 60,
  );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final jam = json['serviceHours'];
    final jamMap = jam is Map ? Map<String, dynamic>.from(jam) : const <String, dynamic>{};

    return AppConfig(
      driverDailyRate:
          (json['driverDailyRate'] as num?)?.toInt() ?? fallback.driverDailyRate,
      serviceOpenMinute:
          (jamMap['openMinute'] as num?)?.toInt() ?? fallback.serviceOpenMinute,
      serviceCloseMinute:
          (jamMap['closeMinute'] as num?)?.toInt() ?? fallback.serviceCloseMinute,
    );
  }
}

/// Layanan pembaca pengaturan publik.
class AppConfigApiService {
  final ApiClient _client;

  AppConfigApiService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<AppConfig> fetchConfig() async {
    final response = await _client.get('/config');
    if (response is Map) {
      return AppConfig.fromJson(Map<String, dynamic>.from(response));
    }
    return AppConfig.fallback;
  }
}
