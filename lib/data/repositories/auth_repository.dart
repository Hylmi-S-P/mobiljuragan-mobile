import '../../models/user_model.dart';
import '../local/secure/secure_storage_service.dart';
import '../remote/auth_api_service.dart';

/// Repository autentikasi & sesi pengguna.
///
/// Satu aturan yang dijaga di seluruh berkas ini: **identitas hanya berasal dari
/// server**. Tidak ada id karangan, tidak ada token buatan sendiri, dan sesi yang
/// dipulihkan dari perangkat selalu diperiksa ulang ke backend.
class AuthRepository {
  final AuthApiService _apiService;
  final SecureStorageService _secureStorage;

  AuthRepository({
    AuthApiService? apiService,
    SecureStorageService? secureStorage,
  })  : _apiService = apiService ?? AuthApiService(),
        _secureStorage = secureStorage ?? SecureStorageService();

  /// Meminta kode verifikasi. Nama tidak ikut dikirim (lihat [AuthApiService]).
  Future<Map<String, dynamic>> requestOtp({
    required String phoneNumber,
    required NiatOtp niat,
  }) {
    return _apiService.requestOtp(phoneNumber: phoneNumber, niat: niat);
  }

  /// Masuk memakai kode verifikasi.
  Future<UserModel?> verifyLoginOtpAndSave({
    required String phoneNumber,
    required String otp,
    String? gender,
    String? idCardNumber,
  }) async {
    final res = await _apiService.verifyLoginOtp(phoneNumber: phoneNumber, otp: otp);
    return _simpanSesi(
      res,
      phoneNumber: phoneNumber,
      gender: gender,
      idCardNumber: idCardNumber,
    );
  }

  /// Menyelesaikan pendaftaran lalu menyimpan sesi.
  ///
  /// Server memverifikasi kode lebih dulu; akun baru lahir di permintaan ini.
  Future<UserModel?> daftarDanSimpan({
    required String phoneNumber,
    required String otp,
    required String fullName,
    required String password,
    String? gender,
    String? idCardNumber,
  }) async {
    final res = await _apiService.verifyRegisterOtp(
      phoneNumber: phoneNumber,
      otp: otp,
      fullName: fullName,
      password: password,
    );
    return _simpanSesi(
      res,
      phoneNumber: phoneNumber,
      gender: gender,
      idCardNumber: idCardNumber,
    );
  }

  /// Menyimpan token + identitas dari respons server yang sudah tervalidasi.
  Future<UserModel?> _simpanSesi(
    Map<String, dynamic> res, {
    required String phoneNumber,
    String? gender,
    String? idCardNumber,
  }) async {
    final token = res['token']?.toString();
    final userData = res['user'] as Map<String, dynamic>?;

    /* Tanpa token atau tanpa id, sesi tidak boleh dibentuk sama sekali.
     * Sebelumnya nilai karangan dipakai di sini, dan hasilnya adalah akun yang
     * tampil di aplikasi tetapi tidak ada di database. */
    final userId = userData?['id']?.toString();
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }

    await _secureStorage.saveAuthTokens(accessToken: token);

    final name = userData?['fullName']?.toString() ?? 'Pelanggan MobilJuragan';
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

  /// Memeriksa apakah ada sesi aktif di SecureStorage.
  Future<bool> hasActiveSession() async {
    return _secureStorage.hasValidToken();
  }

  /// Menghapus sesi dan kredensial pengguna dari SecureStorage.
  Future<void> logout() async {
    await _secureStorage.clearAuth();
  }

  /// Memulihkan sesi pengguna saat aplikasi dibuka.
  ///
  /// Token yang tersimpan di perangkat **diperiksa ke server**. Kalau server
  /// menolaknya (kedaluwarsa, akun dihapus, atau token tidak pernah diterbitkan
  /// server), sesi dibuang dan pengguna kembali sebagai tamu. Nama diambil dari
  /// server, bukan dari salinan lokal, supaya perubahan di server ikut terlihat.
  Future<UserModel?> restoreSession() async {
    final hasToken = await _secureStorage.hasValidToken();
    if (!hasToken) return null;

    final profil = await _apiService.ambilProfilSaya();
    if (profil == null) {
      await _secureStorage.clearAuth();
      return null;
    }

    final userId = profil['id']?.toString();
    final phone = profil['phoneNumber']?.toString();
    if (userId == null || userId.isEmpty || phone == null || phone.isEmpty) {
      await _secureStorage.clearAuth();
      return null;
    }

    final nama = profil['fullName']?.toString();
    final gender = await _secureStorage.getUserGender();
    final nik = await _secureStorage.getUserNik();

    final actualName = (nama != null && nama.isNotEmpty) ? nama : 'Pelanggan MobilJuragan';

    // Segarkan salinan lokal supaya layar yang belum sempat memuat profil tetap benar.
    await _secureStorage.saveUserIdentity(
      userId: userId,
      nik: nik,
      phoneNumber: phone,
      fullName: actualName,
      gender: gender,
    );

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
}
