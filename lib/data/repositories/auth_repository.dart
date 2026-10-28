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
    String? gender,
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
        final userGender = gender ?? 'Laki-laki';

        await _secureStorage.saveUserIdentity(
          userId: userId,
          nik: idCardNumber,
          phoneNumber: phoneNumber,
          fullName: name,
          gender: userGender,
        );

        return UserModel(
          id: userId,
          name: name,
          phoneNumber: phoneNumber,
          gender: userGender,
          idCardNumber: idCardNumber ?? '',
          city: 'Merauke, Papua Selatan',
          avatarInitials: UserModel.computeInitials(name),
          isVerified: true,
        );
      }
    } catch (_) {
      // Offline fallback: abaikan error jaringan dan return null
    }
    return null;
  }

  /// Memeriksa apakah ada sesi aktif di SecureStorage
  Future<bool> hasActiveSession() async {
    return await _secureStorage.hasValidToken();
  }

  /// Menghapus sesi dan kredensial pengguna dari SecureStorage
  Future<void> logout() async {
    await _secureStorage.clearAuth();
  }

  /// Memulihkan sesi pengguna dari Secure Storage saat aplikasi pertama dibuka
  Future<UserModel?> restoreSession() async {
    final hasToken = await _secureStorage.hasValidToken();
    if (!hasToken) return null;

    final userId = await _secureStorage.getUserId();
    final phone = await _secureStorage.getUserPhone();
    final name = await _secureStorage.getUserName();
    final gender = await _secureStorage.getUserGender();
    final nik = await _secureStorage.getUserNik();

    if (userId != null && phone != null) {
      final actualName = (name != null && name.isNotEmpty) ? name : 'Pelanggan MobilJuragan';
      return UserModel(
        id: userId,
        name: actualName,
        phoneNumber: phone,
        gender: gender ?? 'Laki-laki',
        idCardNumber: nik ?? '',
        city: 'Merauke, Papua Selatan',
        avatarInitials: UserModel.computeInitials(actualName),
        isVerified: true,
      );
    }
    return null;
  }
}
