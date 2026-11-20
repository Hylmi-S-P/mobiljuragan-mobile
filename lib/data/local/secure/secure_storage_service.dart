import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Layanan penyimpanan kredensial rahasia & token autentikasi (Hardware Keystore / iOS Keychain)
///
/// PERINGATAN KEAMANAN:
/// Kelas ini khusus mengelola data rahasia (secrets).
/// Dilarang keras memindahkan penyimpanan token atau kredensial ini ke SharedPreferences!
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _keyAccessToken = 'sec_access_token';
  static const String _keyRefreshToken = 'sec_refresh_token';
  static const String _keyUserId = 'sec_user_id';
  static const String _keyUserNik = 'sec_user_nik';
  static const String _keyUserPhone = 'sec_user_phone';
  static const String _keyUserName = 'sec_user_name';
  static const String _keyUserGender = 'sec_user_gender';

  /// Jurnal keluar akun yang belum tuntas.
  ///
  /// Ditulis sebelum langkah pembersihan pertama dan baru dihapus setelah
  /// seluruh langkah selesai. Kalau aplikasi ditutup paksa di tengah proses,
  /// penanda ini masih ada saat aplikasi dibuka lagi sehingga sisa pembersihan
  /// bisa dituntaskan sebelum sesi apa pun dipulihkan. Tanpa jurnal ini, token
  /// yang sudah terlanjur dihapus bisa berpasangan dengan cache pesanan yang
  /// masih utuh — persis kondisi yang membuat riwayat pemilik lama muncul lagi.
  static const String _keyWipePending = 'sec_wipe_pending';

  /// Nilai penanda jurnal. Versi disertakan supaya bentuk jurnal bisa berubah
  /// tanpa salah membaca penanda dari versi aplikasi yang lebih lama.
  static const String _wipePendingValue = 'v1';

  /// Menyimpan token autentikasi JWT
  Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  /// Mengambil access token aktif
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Mengambil refresh token aktif
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Menyimpan data identitas pengguna asli (User ID, No HP, Nama Lengkap, Gender, NIK)
  Future<void> saveUserIdentity({
    required String userId,
    String? nik,
    required String phoneNumber,
    String? fullName,
    String? gender,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    if (nik != null && nik.isNotEmpty) {
      await _storage.write(key: _keyUserNik, value: nik);
    }
    await _storage.write(key: _keyUserPhone, value: phoneNumber);
    if (fullName != null && fullName.isNotEmpty) {
      await _storage.write(key: _keyUserName, value: fullName);
    }
    if (gender != null && gender.isNotEmpty) {
      await _storage.write(key: _keyUserGender, value: gender);
    }
  }

  Future<String?> getUserId() async => await _storage.read(key: _keyUserId);
  Future<String?> getUserNik() async => await _storage.read(key: _keyUserNik);
  Future<String?> getUserPhone() async => await _storage.read(key: _keyUserPhone);
  Future<String?> getUserName() async => await _storage.read(key: _keyUserName);
  Future<String?> getUserGender() async => await _storage.read(key: _keyUserGender);

  /// Mengecek apakah terdapat sesi token aktif
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Menandai bahwa pembersihan sesi sedang berjalan.
  ///
  /// Dipanggil sebelum langkah destruktif pertama. Penanda ini sengaja tidak
  /// ikut dihapus oleh [clearAuth] supaya tetap terbaca saat aplikasi dibuka
  /// kembali setelah ditutup paksa di tengah proses keluar akun.
  Future<void> markWipePending() async {
    await _storage.write(key: _keyWipePending, value: _wipePendingValue);
  }

  /// Membaca apakah ada pembersihan sesi yang belum tuntas.
  Future<bool> isWipePending() async {
    final nilai = await _storage.read(key: _keyWipePending);
    return nilai != null && nilai.isNotEmpty;
  }

  /// Menghapus penanda jurnal setelah seluruh pembersihan selesai.
  Future<void> clearWipePending() async {
    await _storage.delete(key: _keyWipePending);
  }

  /// Menghapus seluruh kredensial rahasia saat keluar (Logout)
  Future<void> clearAuth() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserNik);
    await _storage.delete(key: _keyUserPhone);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserGender);
  }
}
