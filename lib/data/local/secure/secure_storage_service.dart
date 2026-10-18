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

  /// Menyimpan data identitas sensitif pengguna (User ID, NIK, No HP)
  Future<void> saveUserIdentity({
    required String userId,
    required String nik,
    required String phoneNumber,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserNik, value: nik);
    await _storage.write(key: _keyUserPhone, value: phoneNumber);
  }

  Future<String?> getUserId() async => await _storage.read(key: _keyUserId);
  Future<String?> getUserNik() async => await _storage.read(key: _keyUserNik);
  Future<String?> getUserPhone() async => await _storage.read(key: _keyUserPhone);

  /// Mengecek apakah terdapat sesi token aktif
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Menghapus seluruh kredensial rahasia saat keluar (Logout)
  Future<void> clearAuth() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserNik);
    await _storage.delete(key: _keyUserPhone);
  }
}
