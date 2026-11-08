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
