import 'package:shared_preferences/shared_preferences.dart';

/// Layanan penyimpanan preferensi & pengaturan aplikasi yang kecil dan tidak sensitif
///
/// PERINGATAN:
/// Kelas ini HANYA boleh digunakan untuk data konfigurasi/pengaturan ringan.
/// Dilarang keras menyimpan access token, refresh token, atau data kredensial di sini!
class AppSettingsService {
  final SharedPreferences _prefs;

  AppSettingsService(this._prefs);

  static const String _keySelectedCategory = 'pref_selected_category';
  static const String _keySearchHistory = 'pref_search_history';
  static const String _keyNotifications = 'pref_notifications_enabled';
  static const String _keyLastSyncTime = 'pref_last_sync_time';
  static const String _keyOnboardingDone = 'pref_onboarding_completed';

  /// Inisialisasi asinkron instance SharedPreferences
  static Future<AppSettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsService(prefs);
  }

  // Kategori filter armada
  String getSelectedCategory() {
    return _prefs.getString(_keySelectedCategory) ?? 'Semua';
  }

  Future<bool> setSelectedCategory(String category) async {
    return await _prefs.setString(_keySelectedCategory, category);
  }

  // Riwayat pencarian armada
  List<String> getSearchHistory() {
    return _prefs.getStringList(_keySearchHistory) ?? [];
  }

  Future<bool> addSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return false;

    final history = getSearchHistory();
    history.remove(clean);
    history.insert(0, clean);

    // Batasi maksimum 8 kata kunci pencarian terakhir
    if (history.length > 8) {
      history.removeRange(8, history.length);
    }

    return await _prefs.setStringList(_keySearchHistory, history);
  }

  Future<bool> clearSearchHistory() async {
    return await _prefs.remove(_keySearchHistory);
  }

  /// Membersihkan pengaturan yang terikat pada satu akun saat keluar (logout).
  ///
  /// Hanya data yang mencerminkan aktivitas pengguna yang dibuang: kategori
  /// terakhir dipilih, riwayat pencarian, dan waktu sinkronisasi terakhir.
  /// Penanda tingkat perangkat — status onboarding dan preferensi notifikasi —
  /// sengaja dipertahankan supaya pengguna tidak mengulang onboarding hanya
  /// karena berganti akun di perangkat yang sama.
  ///
  /// Kegagalan satu kunci tidak menghentikan pembersihan kunci lain: setiap
  /// langkah dibungkus sendiri-sendiri dan hasilnya dilaporkan sebagai satu
  /// nilai. Pemanggil boleh mengabaikan hasilnya, tetapi tetap mendapat
  /// kepastian bahwa seluruh kunci sudah dicoba.
  Future<bool> clearAllForLogout() async {
    var berhasil = true;
    for (final kunci in const [
      _keySearchHistory,
      _keySelectedCategory,
      _keyLastSyncTime,
    ]) {
      try {
        final terhapus = await _prefs.remove(kunci);
        // remove() mengembalikan false bila kunci memang tidak ada; itu bukan
        // kegagalan, jadi hasilnya tidak dipakai untuk menilai keberhasilan.
        berhasil = berhasil && (terhapus || !_prefs.containsKey(kunci));
      } catch (_) {
        berhasil = false;
      }
    }
    return berhasil;
  }

  // Preferensi notifikasi
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotifications) ?? true;
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await _prefs.setBool(_keyNotifications, enabled);
  }

  // Penanda waktu sinkronisasi terakhir (UTC)
  int? getLastSyncTime() {
    return _prefs.getInt(_keyLastSyncTime);
  }

  Future<bool> setLastSyncTime(int timestampMillis) async {
    return await _prefs.setInt(_keyLastSyncTime, timestampMillis);
  }

  // Status onboarding
  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<bool> setOnboardingCompleted(bool completed) async {
    return await _prefs.setBool(_keyOnboardingDone, completed);
  }
}
