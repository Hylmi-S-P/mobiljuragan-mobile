import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Niat permintaan kode verifikasi.
///
/// `login` tidak pernah membuat akun; `register` menolak nomor yang sudah
/// terdaftar. Backend memakai nilai ini untuk memisahkan dua alur yang dulu
/// tercampur dalam satu endpoint — penyebab akun pelanggan bisa tertimpa.
enum NiatOtp { login, register }

/// Layanan API autentikasi pelanggan: kode verifikasi dan kata sandi.
class AuthApiService {
  final ApiClient _client;

  AuthApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Membersihkan format nomor telepon agar sesuai regex backend.
  static String sanitizePhoneNumber(String raw) {
    return raw.replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// Meminta kode verifikasi untuk nomor tertentu.
  ///
  /// Nama **tidak** dikirim di sini. Nama adalah data milik server dan hanya
  /// dikirim pada langkah pendaftaran, setelah nomor terbukti.
  Future<Map<String, dynamic>> requestOtp({
    required String phoneNumber,
    required NiatOtp niat,
  }) async {
    final response = await _client.post(
      ApiConstants.requestOtpEndpoint,
      body: {
        'phoneNumber': sanitizePhoneNumber(phoneNumber),
        'intent': niat == NiatOtp.register ? 'register' : 'login',
      },
    );

    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Masuk dengan kode verifikasi.
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _client.post(
      ApiConstants.verifyOtpEndpoint,
      body: {
        'phoneNumber': sanitizePhoneNumber(phoneNumber),
        'otp': otp,
      },
    );

    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Menyelesaikan pendaftaran: kode verifikasi + nama + kata sandi.
  ///
  /// Ini satu-satunya permintaan yang boleh melahirkan akun pelanggan. Server
  /// memverifikasi kode lebih dulu, baru menyimpan nama dan hash kata sandi.
  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String phoneNumber,
    required String otp,
    required String fullName,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.registerVerifyEndpoint,
      body: {
        'phoneNumber': sanitizePhoneNumber(phoneNumber),
        'otp': otp,
        'fullName': fullName.trim(),
        'password': password,
      },
    );

    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Masuk memakai kata sandi.
  Future<Map<String, dynamic>> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.passwordLoginEndpoint,
      body: {
        'phoneNumber': sanitizePhoneNumber(phoneNumber),
        'password': password,
      },
    );
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Meminta kode pemulihan kata sandi.
  Future<Map<String, dynamic>> requestPasswordReset({required String phoneNumber}) async {
    final response = await _client.post(
      ApiConstants.passwordResetRequestEndpoint,
      body: {'phoneNumber': sanitizePhoneNumber(phoneNumber)},
    );
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Menetapkan kata sandi baru setelah kode pemulihan terbukti.
  Future<Map<String, dynamic>> verifyPasswordReset({
    required String phoneNumber,
    required String otp,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.passwordResetVerifyEndpoint,
      body: {
        'phoneNumber': sanitizePhoneNumber(phoneNumber),
        'otp': otp,
        'password': password,
      },
    );
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Mengubah nama profil lewat jalur resmi (`PATCH /me`).
  ///
  /// `expectedUpdatedAt` dikirim bila tersedia supaya server bisa menolak
  /// penimpaan saat data sudah berubah di perangkat lain (HTTP 412).
  Future<Map<String, dynamic>> ubahNama({
    required String fullName,
    String? expectedUpdatedAt,
  }) async {
    final response = await _client.patch(
      ApiConstants.authMeEndpoint,
      requiresAuth: true,
      body: {
        'fullName': fullName.trim(),
        'expectedUpdatedAt': ?expectedUpdatedAt,
      },
    );
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Membuat atau mengganti kata sandi. Balasan memuat token baru.
  Future<Map<String, dynamic>> ubahKataSandi({
    required String newPassword,
    String? currentPassword,
  }) async {
    final response = await _client.patch(
      ApiConstants.ubahKataSandiEndpoint,
      requiresAuth: true,
      body: {
        'newPassword': newPassword,
        if (currentPassword != null && currentPassword.isNotEmpty)
          'currentPassword': currentPassword,
      },
    );
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Mengeluarkan semua perangkat (token lama tidak berlaku).
  Future<Map<String, dynamic>> logoutSemuaPerangkat() async {
    final response = await _client.post(
      ApiConstants.logoutAllEndpoint,
      requiresAuth: true,
    );
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  /// Jejak perubahan identitas milik sendiri.
  Future<List<dynamic>> riwayatIdentitas() async {
    final response = await _client.get(
      ApiConstants.riwayatIdentitasEndpoint,
      requiresAuth: true,
    );
    if (response is Map && response['items'] is List) {
      return response['items'] as List<dynamic>;
    }
    return const [];
  }

  /// Profil pemilik sesi; dipakai memastikan token tersimpan masih sah.
  Future<Map<String, dynamic>?> ambilProfilSaya() async {
    try {
      final response = await _client.get(
        ApiConstants.authMeEndpoint,
        requiresAuth: true,
      );
      if (response is Map) {
        final data = response['user'];
        if (data is Map) return Map<String, dynamic>.from(data);
        return Map<String, dynamic>.from(response);
      }
      return null;
    } on ApiException catch (e) {
      // 401/403 = sesi tidak sah; pemanggil memperlakukannya sebagai tamu.
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}
