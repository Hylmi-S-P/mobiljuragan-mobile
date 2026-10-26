import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Layanan percakapan asisten AI pelanggan ke backend MobilJuragan.
///
/// Sebelumnya layar bantuan memakai balasan tiruan yang diketik di dalam aplikasi
/// (`Future.delayed`), sehingga jawaban yang dilihat pelanggan tidak pernah berasal
/// dari model AI dan tidak pernah tersimpan di server. Layanan ini menggantikan
/// tiruan itu dengan panggilan sungguhan ke `POST /ai/chat`.
class AiApiService {
  final ApiClient _client;

  AiApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Mengirim pertanyaan pelanggan ke asisten AI.
  ///
  /// [ticketId] opsional. Bila dikirim, backend menyimpan percakapan ke tiket yang
  /// sama sehingga staf admin dapat membacanya setelah mengambil alih. Bila tidak ada
  /// [ticketId], percakapan dilayani sebagai konsultasi umum 24 jam.
  ///
  /// Hasil yang dikembalikan berisi [AiChatResult]. Kalau gateway sedang bermasalah,
  /// backend tetap membalas 200 dengan teks cadangan dan menandai `fallback`.
  Future<AiChatResult> kirimPesan({
    required String pesan,
    String? ticketId,
  }) async {
    final body = <String, dynamic>{
      'message': pesan,
    };
    if (ticketId != null && ticketId.isNotEmpty) {
      body['ticketId'] = ticketId;
    }

    final response = await _client.post(
      ApiConstants.aiChatEndpoint,
      requiresAuth: false,
      timeout: ApiConstants.aiTimeoutDuration,
      body: body,
    );

    if (response is Map) {
      final data = response['data'];
      if (data is Map) {
        return AiChatResult(
          balasan: (data['reply'] as String?)?.trim() ?? '',
          pakaiCadangan: data['fallback'] == true,
        );
      }
      final directReply = response['reply'];
      if (directReply is String && directReply.trim().isNotEmpty) {
        return AiChatResult(
          balasan: directReply.trim(),
          pakaiCadangan: response['fallback'] == true,
        );
      }
    }

    throw Exception('Balasan asisten AI tidak dikenali.');
  }
}

/// Hasil satu pertukaran pesan dengan asisten AI.
class AiChatResult {
  /// Teks balasan yang ditampilkan ke pelanggan.
  final String balasan;

  /// Benar bila backend memakai teks cadangan karena gateway AI tidak merespons.
  ///
  /// Layar bisa memakai penanda ini untuk menampilkan keterangan tambahan, tanpa
  /// berpura-pura bahwa jawaban itu datang dari model.
  final bool pakaiCadangan;

  const AiChatResult({required this.balasan, this.pakaiCadangan = false});

  bool get kosong => balasan.isEmpty;
}
