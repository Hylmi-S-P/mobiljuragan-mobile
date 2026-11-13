import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import '../local/secure/secure_storage_service.dart';

/// Peristiwa yang datang dari saluran tiket.
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

/// Pendengar peristiwa tiket lewat WebSocket.
///
/// Menggantikan saluran SSE yang memeriksa database setiap dua detik. Di sini
/// server mendorong peristiwa saat perubahan terjadi, jadi tidak ada yang perlu
/// ditanyakan berulang dan biaya server tidak tumbuh sebanding jumlah penonton.
///
/// Satu sambungan melayani satu tiket. Aplikasi pelanggan memang hanya membuka
/// satu percakapan pada satu waktu, dan memisahkannya membuat siklus hidup
/// sambungan sama dengan siklus hidup layar.
class TicketSocket {
  TicketSocket({SecureStorageService? secureStorage, this.alamatDasar})
      : _secureStorage = secureStorage ?? SecureStorageService();

  final SecureStorageService _secureStorage;

  /// Alamat soket. Bila null, diturunkan dari [ApiConstants.baseUrl].
  ///
  /// Diberi jalan masuk supaya pengujian bisa menunjuk server lokal tanpa
  /// mengubah konstanta aplikasi.
  final String? alamatDasar;

  WebSocketChannel? _kanal;
  StreamSubscription<dynamic>? _langganan;
  Timer? _penyambungUlang;
  Timer? _detak;
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

  /// Jeda kirim detak. Server memutus soket yang tidak menjawab ping protokol,
  /// dan sebagian proxy memutus koneksi yang diam lebih lama dari ini.
  static const int _jedaDetakMs = 25000;

  /// Alamat soket diturunkan dari alamat API supaya hanya ada satu sumber.
  String get _alamat {
    final dasar = alamatDasar ?? ApiConstants.baseUrl;
    final ws = dasar.startsWith('https://')
        ? dasar.replaceFirst('https://', 'wss://')
        : dasar.replaceFirst('http://', 'ws://');
    return '$ws/ws/tickets';
  }

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

      final alamat = Uri.parse('$_alamat?token=${Uri.encodeComponent(token)}');
      final kanal = WebSocketChannel.connect(alamat);
      _kanal = kanal;

      await kanal.ready;

      if (_dihentikan) {
        await kanal.sink.close();
        return;
      }

      _percobaan = 0;

      kanal.sink.add(jsonEncode({'aksi': 'langganan', 'ticketId': ticketId}));

      _detak?.cancel();
      _detak = Timer.periodic(const Duration(milliseconds: _jedaDetakMs), (_) {
        if (_dihentikan) return;
        _kanal?.sink.add(jsonEncode({'aksi': 'detak'}));
      });

      _langganan = kanal.stream.listen(
        (mentah) {
          if (mentah is! String) return;

          Map<String, dynamic> isi;
          try {
            final terurai = jsonDecode(mentah);
            if (terurai is! Map<String, dynamic>) return;
            isi = terurai;
          } catch (_) {
            /* Satu peristiwa rusak tidak boleh menghentikan sambungan. */
            return;
          }

          final jenis = isi['jenis'] as String? ?? 'pesan';

          if (jenis == 'galat') {
            onError?.call(isi['pesan'] as String? ?? 'Saluran peristiwa menolak permintaan.');
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
        },
        onError: (Object _) {
          onError?.call('Saluran peristiwa terputus. Mencoba menyambung lagi.');
          _jadwalkanSambungUlang(ticketId: ticketId, onEvent: onEvent, onError: onError);
        },
        onDone: () {
          /* Server menutup sambungan saat tiket final atau saat proses berhenti.
             Keduanya bukan kesalahan, jadi disambung lagi tanpa pesan galat. */
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

    _detak?.cancel();
    _detak = null;
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
    _detak?.cancel();
    _detak = null;
    _langganan?.cancel();
    _langganan = null;
    _kanal?.sink.close();
    _kanal = null;
  }
}
