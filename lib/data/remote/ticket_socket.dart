import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../local/secure/secure_storage_service.dart';

/// Peristiwa yang datang dari saluran tiket (SSE).
///
/// Bentuknya sengaja dibuat sederhana: hanya jenis dan isi mentah. Pemetaan ke
/// model dilakukan pemanggil, supaya layar tetap yang memutuskan apa arti sebuah
/// peristiwa bagi tampilannya.
class TicketEvent {
  const TicketEvent({required this.jenis, required this.data});

  /// `siap`, `pesan`, `status`, `handover`, atau `galat`.
  final String jenis;
  final Map<String, dynamic> data;

  int? get jumlahPesan => data['jumlahPesan'] as int?;

  /// Nomor urut pesan terakhir. Dipakai untuk membuang peristiwa ganda setelah
  /// sambung ulang: server bisa mengirim ulang pesan yang sudah pernah diterima.
  int? get sequence => data['sequence'] as int?;

  String? get status => data['status'] as String?;
  String? get kode => data['kode'] as String?;
  String? get pesan => data['pesan'] as String?;
}

/// Pendengar peristiwa tiket real-time lewat Server-Sent Events (SSE).
///
/// Menyambung ke endpoint `GET /api/v1/tickets/:id/events` yang didorong langsung
/// oleh `EventEmitter` di backend (`ticketEvents.ts`) setiap kali pesan masuk,
/// status berubah, atau terjadi eskalasi ke staf operasional.
///
/// Satu sambungan melayani satu tiket. Memisahkannya membuat siklus hidup
/// sambungan sama dengan siklus hidup layar.
class TicketSocket {
  TicketSocket({
    SecureStorageService? secureStorage,
    this.alamatDasar,
    http.Client Function()? clientFactory,
  }) : _secureStorage = secureStorage ?? SecureStorageService(),
       _clientFactory = clientFactory ?? http.Client.new;

  final SecureStorageService _secureStorage;
  final http.Client Function() _clientFactory;

  /// Alamat dasar API. Bila null, diturunkan dari [ApiConstants.baseUrl].
  ///
  /// Diberi jalan masuk supaya pengujian bisa menunjuk server lokal tanpa
  /// mengubah konstanta aplikasi.
  final String? alamatDasar;

  http.Client? _klien;
  StreamSubscription<String>? _langganan;
  Timer? _penyambungUlang;
  bool _dihentikan = false;
  int _percobaan = 0;

  /// Nomor urut pesan terakhir yang sudah diserahkan ke pemanggil.
  ///
  /// Peristiwa `pesan` dengan nomor yang sama atau lebih kecil dibuang. Tanpa
  /// ini, sambung ulang bisa memunculkan pesan yang sama dua kali di layar.
  int _sequenceTerakhir = 0;

  /// Sambungan diputus dan disambung lagi setelah jeda ini kalau terputus.
  ///
  /// Nilainya naik bertahap supaya server yang sedang bermasalah tidak dibanjiri
  /// percobaan sambung. Batas atasnya 30 detik agar pemulihan tidak terlalu lama.
  static const int _jedaDasarMs = 2000;
  static const int _jedaMaksimalMs = 30000;

  /// Alamat endpoint SSE untuk satu tiket.
  Uri _alamatTiket(String ticketId) {
    final mentah = (alamatDasar ?? ApiConstants.baseUrl).replaceAll(
      RegExp(r'/+$'),
      '',
    );
    final basis = mentah.endsWith('/api/v1') ? mentah : '$mentah/api/v1';
    return Uri.parse(
      '$basis${ApiConstants.ticketsEndpoint}/${Uri.encodeComponent(ticketId)}/events',
    );
  }

  /// Mulai mendengarkan satu tiket lewat aliran SSE.
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
    _sequenceTerakhir = 0;
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
      if (token == null || token.isEmpty) {
        onError?.call('Sesi tidak ditemukan. Silakan masuk kembali.');
        return;
      }

      _klien?.close();
      final klien = _clientFactory();
      _klien = klien;

      final permintaan = http.Request('GET', _alamatTiket(ticketId))
        ..headers[HttpHeaders.authorizationHeader] = 'Bearer $token'
        ..headers[HttpHeaders.acceptHeader] = 'text/event-stream'
        ..headers[HttpHeaders.cacheControlHeader] = 'no-cache';

      final respons = await klien
          .send(permintaan)
          .timeout(const Duration(seconds: 10));

      if (_dihentikan) {
        klien.close();
        return;
      }

      if (respons.statusCode != 200) {
        klien.close();
        onError?.call('Saluran peristiwa menolak permintaan.');
        if (respons.statusCode >= 500) {
          _jadwalkanSambungUlang(
            ticketId: ticketId,
            onEvent: onEvent,
            onError: onError,
          );
        }
        return;
      }

      _percobaan = 0;

      String? namaEvent;
      final barisData = <String>[];

      void prosesBlok() {
        if (barisData.isEmpty) {
          namaEvent = null;
          return;
        }
        final mentah = barisData.join('\n').trim();
        final eventTertunda = namaEvent;
        barisData.clear();
        namaEvent = null;

        if (mentah.isEmpty) return;

        Map<String, dynamic> isi;
        try {
          final terurai = jsonDecode(mentah);
          if (terurai is! Map<String, dynamic>) return;
          isi = terurai;
        } catch (_) {
          /* Satu peristiwa rusak tidak boleh menghentikan sambungan. */
          return;
        }

        final jenis = isi['jenis'] as String? ?? eventTertunda ?? 'pesan';

        if (jenis == 'galat') {
          onError?.call(
            isi['pesan'] as String? ?? 'Saluran peristiwa menolak permintaan.',
          );
          return;
        }

        if (jenis == 'pesan') {
          final sequence = isi['sequence'];
          if (sequence is int) {
            if (sequence <= _sequenceTerakhir) return;
            _sequenceTerakhir = sequence;
          }
        }

        onEvent(TicketEvent(jenis: jenis, data: isi));
      }

      _langganan = respons.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (baris) {
              if (_dihentikan) return;

              if (baris.isEmpty) {
                prosesBlok();
                return;
              }

              // Komentar detak jantung SSE (`: detak`) diabaikan.
              if (baris.startsWith(':')) {
                return;
              }

              if (baris.startsWith('event:')) {
                namaEvent = baris.substring(6).trim();
                return;
              }

              if (baris.startsWith('data:')) {
                barisData.add(baris.substring(5).trimLeft());
              }
            },
            onError: (Object _) {
              if (_dihentikan) return;
              onError?.call('Saluran peristiwa terputus. Mencoba menyambung lagi.');
              _jadwalkanSambungUlang(
                ticketId: ticketId,
                onEvent: onEvent,
                onError: onError,
              );
            },
            onDone: () {
              if (_dihentikan) return;
              prosesBlok();
              /* Server menutup sambungan saat batas umur aliran tercapai atau
                 saat proses berhenti; sambung ulang dijadwalkan tanpa pesan galat. */
              _jadwalkanSambungUlang(
                ticketId: ticketId,
                onEvent: onEvent,
                onError: onError,
              );
            },
            cancelOnError: true,
          );
    } catch (_) {
      if (_dihentikan) return;
      onError?.call('Tidak bisa menyambung ke saluran peristiwa.');
      _jadwalkanSambungUlang(
        ticketId: ticketId,
        onEvent: onEvent,
        onError: onError,
      );
    }
  }

  void _jadwalkanSambungUlang({
    required String ticketId,
    required void Function(TicketEvent) onEvent,
    void Function(String pesan)? onError,
  }) {
    if (_dihentikan) return;

    _langganan?.cancel();
    _langganan = null;
    _klien?.close();
    _klien = null;
    _penyambungUlang?.cancel();
    _percobaan += 1;

    /* Jeda naik dua kali lipat tiap kegagalan ditambah jitter acak 0-499 ms
       supaya sambung ulang tidak serentak menghantam server. */
    final jedaBase = (_jedaDasarMs * (1 << (_percobaan - 1).clamp(0, 4))).clamp(
      _jedaDasarMs,
      _jedaMaksimalMs,
    );
    final jitterMs = math.Random().nextInt(500);

    _penyambungUlang = Timer(Duration(milliseconds: jedaBase + jitterMs), () {
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
    _klien?.close();
    _klien = null;
  }
}
