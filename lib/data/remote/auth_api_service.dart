import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Layanan API autentikasi berbasis OTP customer dari backend
class AuthApiService {
  final ApiClient _client;

  AuthApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Mengirim permintaan kode OTP ke nomor telepon pelanggan
  Future<Map<String, dynamic>> requestOtp({
    required String phoneNumber,
    String? fullName,
  }) async {
    final response = await _client.post(
      ApiConstants.requestOtpEndpoint,
      body: {
        'phoneNumber': phoneNumber,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        'purpose': 'CUSTOMER_LOGIN',
      },
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  /// Verifikasi kode OTP customer dan menerima token JWT
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _client.post(
      ApiConstants.verifyOtpEndpoint,
      body: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'purpose': 'CUSTOMER_LOGIN',
      },
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }
}
