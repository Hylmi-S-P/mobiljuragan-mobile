import '../network/app_config_api_service.dart';

/// Penyimpan pengaturan publik yang berlaku selama aplikasi berjalan.
///
/// Satu sumber untuk seluruh layar, supaya tarif jasa supir di layar pelanggan
/// sama dengan tarif yang dipakai server, dan tidak ada layar yang memakai angka
/// lama setelah admin mengubahnya.
class AppConfigStore {
  AppConfigStore._();

  static AppConfig _config = AppConfig.fallback;

  /// Pengaturan terakhir yang diketahui. Sebelum server dihubungi, nilainya
  /// cadangan dan hanya dipakai untuk tampilan; tagihan tetap dihitung server.
  static AppConfig get config => _config;

  static int get driverDailyRate => _config.driverDailyRate;

  static int get serviceOpenMinute => _config.serviceOpenMinute;

  static int get serviceCloseMinute => _config.serviceCloseMinute;

  /// Mengganti pengaturan yang berlaku.
  static void terapkan(AppConfig config) {
    _config = config;
  }

  /// Mengembalikan ke nilai cadangan. Dipakai pengujian supaya nilai dari satu
  /// kasus tidak merembes ke kasus berikutnya.
  static void reset() {
    _config = AppConfig.fallback;
  }
}
