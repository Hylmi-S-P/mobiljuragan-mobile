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
  /// [ticketId] wajib dikirim supaya backend menyimpan percakapan ke tiket yang
  /// sama. Tanpa itu, admin tidak akan melihat apa pun saat mengambil alih tiket.
  ///
  /// Hasil yang dikembalikan berisi [AiChatResult]. Kalau gateway sedang bermasalah,
  /// backend tetap membalas 200 dengan teks cadangan dan menandai `fallback`.
  Future<AiChatResult> kirimPesan({
    required String pesan,
    required String ticketId,
  }) async {
    final response = await _client.post(
      ApiConstants.aiChatEndpoint,
      requiresAuth: true,
      body: {
        'message': pesan,
        'ticketId': ticketId,
      },
    );

    if (response is Map) {
      final data = response['data'];
      if (data is Map) {
        return AiChatResult(
          balasan: (data['reply'] as String?)?.trim() ?? '',
          pakaiCadangan: data['fallback'] == true,
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
