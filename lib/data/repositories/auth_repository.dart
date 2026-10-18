import '../../models/user_model.dart';
import '../local/secure/secure_storage_service.dart';
import '../remote/auth_api_service.dart';

/// Repository autentikasi & sesi pengguna
///
/// Bertanggung jawab untuk autentikasi API dan penyimpanan token rahasia
/// di dalam FlutterSecureStorage (Keystore / Keychain).
class AuthRepository {
  final AuthApiService _apiService;
  final SecureStorageService _secureStorage;

  AuthRepository({
    AuthApiService? apiService,
    SecureStorageService? secureStorage,
  })  : _apiService = apiService ?? AuthApiService(),
        _secureStorage = secureStorage ?? SecureStorageService();

  /// Mengirim kode OTP ke nomor telepon pelanggan
  Future<Map<String, dynamic>> requestOtp({
    required String phoneNumber,
    String? fullName,
  }) async {
    return await _apiService.requestOtp(
      phoneNumber: phoneNumber,
      fullName: fullName,
    );
  }

  /// Verifikasi kode OTP dan simpan token ke Secure Storage
  Future<UserModel?> verifyOtpAndSave({
    required String phoneNumber,
    required String otp,
    String? fullName,
    String? idCardNumber,
  }) async {
    try {
      final res = await _apiService.verifyOtp(phoneNumber: phoneNumber, otp: otp);
      final token = res['token']?.toString();
      final userData = res['user'] as Map<String, dynamic>?;

      if (token != null && token.isNotEmpty) {
        // SIMPAN TOKEN KE HARDWARE-BACKED SECURE STORAGE (BUKAN SharedPreferences!)
        await _secureStorage.saveAuthTokens(accessToken: token);

        final userId = userData?['id']?.toString() ?? 'USR-MKQ-${DateTime.now().millisecondsSinceEpoch}';
        final name = userData?['fullName']?.toString() ?? fullName ?? 'Pelanggan MobilJuragan';
        final nik = idCardNumber ?? '9101012304980002';

        await _secureStorage.saveUserIdentity(
          userId: userId,
          nik: nik,
          phoneNumber: phoneNumber,
        );

        return UserModel(
          id: userId,
          name: name,
          phoneNumber: phoneNumber,
          email: '${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}@mobiljuragan.com',
          idCardNumber: nik,
          city: 'Merauke, Papua Selatan',
          avatarInitials: name.isNotEmpty
              ? (name.trim().split(' ').length > 1
                  ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'.toUpperCase()
                  : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase())
              : 'MJ',
          isVerified: true,
        );
      }
    } catch (_) {
      // Offline fallback: abaikan error jaringan dan return null
    }
    return null;
  }

  /// Memulihkan sesi pengguna dari Secure Storage saat aplikasi pertama dibuka
  Future<UserModel?> restoreSession() async {
    final hasToken = await _secureStorage.hasValidToken();
    if (!hasToken) return null;

    final userId = await _secureStorage.getUserId();
    final phone = await _secureStorage.getUserPhone();
    final nik = await _secureStorage.getUserNik();

    if (userId != null && phone != null) {
      return UserModel(
        id: userId,
        name: 'Harun',
        phoneNumber: phone,
        email: 'harun.merauke@gmail.com',
        idCardNumber: nik ?? '9101012304980002',
        city: 'Merauke, Papua Selatan',
        avatarInitials: 'HR',
        isVerified: true,
      );
    }
    return null;
  }

  /// Menghapus kredensial rahasia saat keluar akun (Logout)
  Future<void> logout() async {
    await _secureStorage.clearAuth();
  }

  /// Mengecek apakah token aktif tersimpan
  Future<bool> hasActiveSession() => _secureStorage.hasValidToken();

  /// Mendapatkan access token saat ini
  Future<String?> getAccessToken() => _secureStorage.getAccessToken();
}
