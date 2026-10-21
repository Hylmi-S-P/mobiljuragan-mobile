import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../models/faq_model.dart';

/// Layanan API untuk konsumsi endpoint FAQ dari backend
class FaqApiService {
  final ApiClient _client;

  FaqApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Mengambil daftar FAQ aktif terurut dari backend
  Future<List<FaqModel>> fetchFaqs({String? category, String? search}) async {
    final query = <String, dynamic>{};
    if (category != null &&
        category.isNotEmpty &&
        category.toLowerCase() != 'semua') {
      query['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await _client.get(
      ApiConstants.faqsEndpoint,
      queryParams: query.isNotEmpty ? query : null,
    );

    final dynamic listData = response is List
        ? response
        : (response is Map && response['data'] is List ? response['data'] : null);

    if (listData is List) {
      return listData
          .map((item) => FaqModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }
}
