import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../local/secure/secure_storage_service.dart';

/// Peristiwa yang datang dari saluran tiket.
///
/// Bentuknya sengaja dibuat sederhana: hanya jenis dan isi mentah. Pemetaan ke
/// model dilakukan pemanggil, supaya layar tetap yang memutuskan apa arti sebuah
/// peristiwa bagi tampilannya.
class TicketEvent {
  const TicketEvent({required this.jenis, required this.data});

  /// `siap`, `pesan`, `status`, atau `handover`.
  final String jenis;
  final Map<String, dynamic> data;

  int? get jumlahPesan => data['jumlahPesan'] as int?;
  String? get status => data['status'] as String?;
}

/// Pendengar peristiwa tiket lewat SSE.
///
/// Sebelum ini tidak ada klien yang berlangganan sama sekali. Backend sudah
/// mengirim peristiwa, tetapi tidak ada yang mendengarkan, sehingga balasan
/// staf baru terlihat setelah layar dimuat ulang manual.
///
/// Pemilihan SSE mengikuti backend: arahnya satu, server memberi tahu klien.
/// Mengirim pesan tetap lewat POST yang sudah ada.
class TicketEventStream {
  TicketEventStream({http.Client? client, SecureStorageService? secureStorage})
      : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorageService();

  final http.Client _client;
  final SecureStorageService _secureStorage;

  StreamSubscription<String>? _langganan;
  Timer? _penyambungUlang;
  bool _dihentikan = false;
  int _percobaan = 0;

  /// Sambungan diputus dan disambung lagi setelah jeda ini kalau terputus.
  ///
  /// Nilainya naik bertahap supaya server yang sedang bermasalah tidak dibanjiri
  /// percobaan sambung. Batas atasnya 30 detik agar pemulihan tidak terlalu lama.
  static const int _jedaDasarMs = 2000;
  static const int _jedaMaksimalMs = 30000;

  /// Mulai mendengarkan satu tiket.
  ///
  /// [onEvent] dipanggil untuk setiap peristiwa. [onError] dipanggil sekali per
  /// kegagalan sambung, bukan untuk setiap percobaan ulang, supaya layar tidak
  /// menampilkan pesan galat berulang-ulang.
  Future<void> mulai({
    required String ticketId,
    required void Function(TicketEvent) onEvent,
    void Function(String pesan)? onError,
  }) async {
    _dihentikan = false;
    _percobaan = 0;
    await _sambung(ticketId: ticketId, onEvent: onEvent, onError: onError);
  }

  Future<void> _sambung({
    required String ticketId,
    required void Function(TicketEvent) onEvent,
    void Function(String pesan)? onError,
  }) async {
    if (_dihentikan) return;

    try {
      final token = await _secureStorage.getAccessToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/tickets/$ticketId/events');
      final permintaan = http.Request('GET', uri)
        ..headers.addAll({
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        });

      final respons = await _client.send(permintaan);

      if (respons.statusCode != 200) {
        onError?.call('Saluran peristiwa ditolak server (${respons.statusCode}).');
        _jadwalkanSambungUlang(ticketId: ticketId, onEvent: onEvent, onError: onError);
        return;
      }

      _percobaan = 0;

      /* Isi dibaca baris demi baris. Format SSE memisahkan peristiwa dengan baris
         kosong, jadi satu peristiwa bisa terdiri dari beberapa baris `data:`. */
      var jenisSekarang = 'pesan';
      final penampungData = <String>[];

      _langganan = respons.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (baris) {
          if (baris.isEmpty) {
            if (penampungData.isNotEmpty) {
              final mentah = penampungData.join('\n');
              penampungData.clear();
              try {
                final isi = jsonDecode(mentah);
                if (isi is Map<String, dynamic>) {
                  onEvent(TicketEvent(jenis: jenisSekarang, data: isi));
                }
              } catch (_) {
                /* Satu peristiwa rusak tidak boleh menghentikan sambungan. */
              }
            }
            jenisSekarang = 'pesan';
            return;
          }

          if (baris.startsWith('event:')) {
            jenisSekarang = baris.substring(6).trim();
          } else if (baris.startsWith('data:')) {
            penampungData.add(baris.substring(5).trimLeft());
          }
          /* Baris `:` adalah komentar detak untuk menjaga sambungan tetap hidup.
             Tidak perlu ditangani. */
        },
        onError: (Object _) {
          onError?.call('Saluran peristiwa terputus. Mencoba menyambung lagi.');
          _jadwalkanSambungUlang(ticketId: ticketId, onEvent: onEvent, onError: onError);
        },
        onDone: () {
          /* Server menutup sambungan setelah batas umurnya. Ini normal, bukan
             kesalahan, jadi disambung lagi tanpa pesan galat. */
          _jadwalkanSambungUlang(ticketId: ticketId, onEvent: onEvent, onError: onError);
        },
        cancelOnError: true,
      );
    } catch (_) {
      onError?.call('Tidak bisa menyambung ke saluran peristiwa.');
      _jadwalkanSambungUlang(ticketId: ticketId, onEvent: onEvent, onError: onError);
    }
  }

  void _jadwalkanSambungUlang({
    required String ticketId,
    required void Function(TicketEvent) onEvent,
    void Function(String pesan)? onError,
  }) {
    if (_dihentikan) return;

    _penyambungUlang?.cancel();
    _percobaan += 1;

    /* Jeda naik dua kali lipat tiap kegagalan, dibatasi 30 detik. */
    final jeda = (_jedaDasarMs * (1 << (_percobaan - 1).clamp(0, 4))).clamp(
      _jedaDasarMs,
      _jedaMaksimalMs,
    );

    _penyambungUlang = Timer(Duration(milliseconds: jeda), () {
      _sambung(ticketId: ticketId, onEvent: onEvent, onError: onError);
    });
  }

  /// Menghentikan sambungan dan membatalkan semua percobaan sambung ulang.
  ///
  /// Wajib dipanggil saat layar ditutup. Tanpa ini, sambungan tetap hidup di
  /// latar belakang dan terus memakai baterai serta kuota.
  void berhenti() {
    _dihentikan = true;
    _penyambungUlang?.cancel();
    _penyambungUlang = null;
    _langganan?.cancel();
    _langganan = null;
  }
}
