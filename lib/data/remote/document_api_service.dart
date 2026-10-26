import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../models/booking_document_model.dart';

/// Layanan API untuk pengelolaan berkas persyaratan sewa lepas kunci
class DocumentApiService {
  final ApiClient _client;
  final http.Client _httpClient;

  DocumentApiService([ApiClient? client, http.Client? httpClient])
      : _client = client ?? ApiClient(),
        _httpClient = httpClient ?? http.Client();

  /// Mengambil teks klausul resmi surat pernyataan untuk pratinjau in-app
  Future<Map<String, dynamic>> fetchStatementTemplateText() async {
    final response = await _client.get(
      ApiConstants.documentTemplateTextEndpoint,
      requiresAuth: false,
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  /// Mengunduh berkas biner PDF asli surat pernyataan resmi dari backend
  Future<Uint8List> downloadStatementTemplatePdf() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.documentTemplatePdfEndpoint}',
    );

    final response = await _httpClient
        .get(uri)
        .timeout(ApiConstants.timeoutDuration);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(
      'Gagal mengunduh berkas template surat pernyataan resmi (Status: ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  /// Mengunduh berkas biner PDF surat pernyataan yang sudah terisi otomatis data reservasi
  Future<Uint8List> downloadBookingStatementPdf(String bookingId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.bookingsEndpoint}/$bookingId/statement-pdf',
      );

      final response = await _httpClient
          .get(uri)
          .timeout(ApiConstants.timeoutDuration);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
    } catch (_) {
      // Fallback ke template standar bila jaringan bermasalah
    }
    return downloadStatementTemplatePdf();
  }

  /// Mengambil dokumen persyaratan yang terikat dengan pemesanan
  Future<BookingDocumentModel?> fetchBookingDocuments(String bookingId) async {
    final response = await _client.get(
      '${ApiConstants.bookingsEndpoint}/$bookingId/documents',
      requiresAuth: true,
    );

    if (response is Map) {
      return BookingDocumentModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return null;
  }

  /// Mengunggah dokumen persyaratan sewa lepas kunci (Surat pernyataan, KTP, SIM A)
  Future<BookingDocumentModel> uploadBookingDocuments({
    required String bookingId,
    String? statementLetterUrl,
    String? ktpUrl,
    String? simUrl,
  }) async {
    final response = await _client.post(
      '${ApiConstants.bookingsEndpoint}/$bookingId/documents',
      requiresAuth: true,
      body: {
        if (statementLetterUrl != null && statementLetterUrl.isNotEmpty)
          'statementLetterUrl': statementLetterUrl,
        if (ktpUrl != null && ktpUrl.isNotEmpty) 'ktpUrl': ktpUrl,
        if (simUrl != null && simUrl.isNotEmpty) 'simUrl': simUrl,
      },
    );

    if (response is Map) {
      return BookingDocumentModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    throw ApiException('Respons server tidak valid saat mengunggah dokumen.');
  }
}
