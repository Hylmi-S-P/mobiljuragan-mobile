import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../models/payment_model.dart';

/// Layanan jaringan REST API untuk pemrosesan pembayaran & QRIS Dinamis
class PaymentApiService {
  final ApiClient _client;

  PaymentApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Membuat tagihan pembayaran baru (QRIS Dinamis atau Transfer Bank)
  Future<PaymentModel> createPayment({
    required String bookingId,
    PaymentMethod method = PaymentMethod.qris,
    String? notes,
  }) async {
    final response = await _client.post(
      ApiConstants.paymentsEndpoint,
      requiresAuth: true,
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
        requiresAuth: true,
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
        requiresAuth: true,
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

  /// Mengunggah foto bukti transfer ke `/api/v1/media` sebagai multipart dan
  /// mengembalikan ID media yang siap dikirim ke endpoint bukti pembayaran.
  Future<String> uploadPaymentProofMedia(XFile file) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isEmpty ? 'bukti_pembayaran.jpg' : file.name;
    final multipart = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    );

    final response = await _client.postMultipart(
      ApiConstants.mediaEndpoint,
      files: {'file': multipart},
      fields: const {'kategori': 'PAYMENT_PROOF'},
      requiresAuth: true,
      timeout: ApiConstants.uploadTimeoutDuration,
    );

    if (response is Map && response['id'] != null) {
      final mediaId = response['id'].toString().trim();
      if (mediaId.isNotEmpty) return mediaId;
    }
    throw ApiException('Server tidak mengembalikan ID media bukti pembayaran.');
  }

  /// Mengunggah ID media hasil `/api/v1/media` atau tautan/base64 bukti transfer.
  Future<PaymentModel> uploadPaymentProof({
    required String paymentId,
    String? proofImageUrl,
    String? proofMediaId,
    String? senderAccount,
    String? bankName,
  }) async {
    final trimmedMediaId = proofMediaId?.trim();
    final trimmedImageUrl = proofImageUrl?.trim();
    if ((trimmedMediaId == null || trimmedMediaId.isEmpty) &&
        (trimmedImageUrl == null || trimmedImageUrl.isEmpty)) {
      throw ApiException('Bukti pembayaran wajib disertakan.');
    }

    final payload = <String, dynamic>{
      if (trimmedMediaId != null && trimmedMediaId.isNotEmpty)
        'proofMediaId': trimmedMediaId,
      if (trimmedImageUrl != null && trimmedImageUrl.isNotEmpty)
        'proofImageUrl': trimmedImageUrl,
      if (senderAccount != null && senderAccount.trim().isNotEmpty)
        'senderAccount': senderAccount.trim(),
      if (bankName != null && bankName.trim().isNotEmpty)
        'bankName': bankName.trim(),
    };

    final response = await _client.post(
      '${ApiConstants.paymentsEndpoint}/$paymentId/proof',
      requiresAuth: true,
      timeout: ApiConstants.uploadTimeoutDuration,
      body: payload,
    );

    if (response is Map) {
      return PaymentModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw ApiException('Gagal memproses unggahan bukti transfer.');
  }

}
