import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Layanan API tiket bantuan pelanggan ke backend MobilJuragan
class TicketApiService {
  final ApiClient _client;

  TicketApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Mengambil daftar tiket milik pelanggan yang sedang login
  Future<List<dynamic>> fetchCustomerTickets({String? status}) async {
    try {
      final response = await _client.get(
        ApiConstants.ticketsEndpoint,
        queryParams: status != null ? {'status': status} : null,
        requiresAuth: true,
      );
      if (response is List) {
        return response;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Membuat tiket kendala/bantuan baru
  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    String? category,
  }) async {
    final response = await _client.post(
      ApiConstants.ticketsEndpoint,
      requiresAuth: true,
      body: {
        'title': title,
        'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  /// Mengirim pesan balasan pelanggan pada thread tiket
  Future<Map<String, dynamic>> addMessage({
    required String ticketId,
    required String message,
  }) async {
    final response = await _client.post(
      '${ApiConstants.ticketsEndpoint}/$ticketId/messages',
      requiresAuth: true,
      body: {
        'body': message,
      },
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  /// Mengambil detail tiket beserta seluruh pesan percakapan dari backend
  Future<Map<String, dynamic>?> fetchTicketDetail(String ticketId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.ticketsEndpoint}/$ticketId',
        requiresAuth: true,
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}