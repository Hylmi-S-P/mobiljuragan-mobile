import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../models/payment_model.dart';

/// Layanan jaringan REST API untuk pemrosesan pembayaran & QRIS Dinamis
class PaymentApiService {
  final ApiClient _client;

  PaymentApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Membuat tagihan pembayaran baru (QRIS Dinamis, Transfer Bank, atau Tunai COD)
  Future<PaymentModel> createPayment({
    required String bookingId,
    PaymentMethod method = PaymentMethod.qris,
    String? notes,
  }) async {
    final response = await _client.post(
      ApiConstants.paymentsEndpoint,
      body: {
        'bookingId': bookingId,
        'method': method.toBackendString(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (response is Map) {
      return PaymentModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw ApiException('Format data tagihan pembayaran tidak valid.');
  }

  /// Mengambil data tagihan pembayaran berdasarkan ID pemesanan atau booking code
  Future<PaymentModel?> getPaymentByBooking(String bookingId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.paymentsBookingEndpoint}/$bookingId',
      );

      if (response is Map) {
        return PaymentModel.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Mengambil data tagihan pembayaran berdasarkan ID pembayaran
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.paymentsEndpoint}/$paymentId',
      );

      if (response is Map) {
        return PaymentModel.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Mengunggah URL atau referensi bukti transfer bank pelanggan
  Future<PaymentModel> uploadPaymentProof({
    required String paymentId,
    required String proofImageUrl,
    String? senderAccount,
    String? bankName,
  }) async {
    final payload = <String, dynamic>{
      'proofImageUrl': proofImageUrl,
      if (senderAccount != null && senderAccount.trim().isNotEmpty)
        'senderAccount': senderAccount.trim(),
      if (bankName != null && bankName.trim().isNotEmpty)
        'bankName': bankName.trim(),
    };

    final response = await _client.post(
      '${ApiConstants.paymentsEndpoint}/$paymentId/proof',
      body: payload,
    );

    if (response is Map) {
      return PaymentModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw ApiException('Gagal memproses unggahan bukti transfer.');
  }

}
