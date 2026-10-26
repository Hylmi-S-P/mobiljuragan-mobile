import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Layanan integrasi percakapan asisten AI (RAG Gateway) ke backend MobilJuragan
class AiChatApiService {
  final ApiClient _client;

  AiChatApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Mengirim pertanyaan pelanggan ke gateway RAG asisten AI backend
  Future<String?> sendChat({
    required String message,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.aiChatEndpoint,
        body: {
          'message': message,
          if (history != null && history.isNotEmpty) 'history': history,
        },
        timeout: ApiConstants.aiTimeoutDuration,
      );

      if (response is Map) {
        final data = response['data'];
        if (data is Map && data['reply'] != null) {
          final reply = data['reply'].toString().trim();
          if (reply.isNotEmpty) return reply;
        }
        final reply = response['reply'];
        if (reply != null && reply.toString().trim().isNotEmpty) {
          return reply.toString().trim();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
