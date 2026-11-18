import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/secure/secure_storage_service.dart';
import 'package:mobiljuragan_mobile/data/remote/ticket_socket.dart';

/// Penyimpanan palsu: hanya token yang dibutuhkan saluran peristiwa.
class _PenyimpananPalsu extends SecureStorageService {
  _PenyimpananPalsu(this.token);

  final String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

/// Server SSE kecil yang meniru endpoint `GET /api/v1/tickets/:id/events`:
/// menerima langganan dengan header Bearer, lalu mendorong peristiwa SSE.
class _ServerUji {
  _ServerUji(this._server);

  final HttpServer _server;
  final List<Map<String, String>> permintaanDiterima = [];
  HttpResponse? _aliranAktif;

  static Future<_ServerUji> mulai() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final uji = _ServerUji(server);
    unawaited(uji._layani());
    return uji;
  }

  String get alamat => 'http://127.0.0.1:${_server.port}/api/v1';

  Future<void> _layani() async {
    await for (final permintaan in _server) {
      permintaanDiterima.add({
        'method': permintaan.method,
        'path': permintaan.uri.path,
        'auth': permintaan.headers.value(HttpHeaders.authorizationHeader) ?? '',
        'accept': permintaan.headers.value(HttpHeaders.acceptHeader) ?? '',
      });

      final res = permintaan.response;
      res.statusCode = HttpStatus.ok;
      res.bufferOutput = false;
      res.headers.set(
        HttpHeaders.contentTypeHeader,
        'text/event-stream; charset=utf-8',
      );
      res.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      _aliranAktif = res;
      res.write('event: siap\ndata: {"jenis":"siap"}\n\n');
    }
  }

  void kirim(Map<String, dynamic> isi) {
    final res = _aliranAktif;
    if (res == null) return;
    final jenis = isi['jenis'] ?? 'pesan';
    res.write('event: $jenis\n');
    res.write('data: ${jsonEncode(isi)}\n\n');
  }

  Future<void> tutup() async {
    try {
      await _aliranAktif?.close();
    } catch (_) {}
    await _server.close(force: true);
  }
}

void main() {
  group('TicketSocket (SSE)', () {
    test('membuka aliran SSE dengan token Bearer dan meneruskan peristiwa pesan',
        () async {
      final server = await _ServerUji.mulai();
      addTearDown(server.tutup);

      final peristiwa = <TicketEvent>[];
      final soket = TicketSocket(
        secureStorage: _PenyimpananPalsu('token-uji'),
        alamatDasar: server.alamat,
      );
      addTearDown(soket.berhenti);

      await soket.mulai(ticketId: 'tiket-1', onEvent: peristiwa.add);

      for (var i = 0; i < 50 && server.permintaanDiterima.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(server.permintaanDiterima.first['method'], 'GET');
      expect(
        server.permintaanDiterima.first['path'],
        '/api/v1/tickets/tiket-1/events',
      );
      expect(server.permintaanDiterima.first['auth'], 'Bearer token-uji');

      server.kirim({
        'jenis': 'pesan',
        'ticketId': 'tiket-1',
        'sequence': 3,
        'jumlahPesan': 3,
      });

      for (var i = 0; i < 50 &&
              !peristiwa.any((p) => p.jenis == 'pesan');
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(peristiwa.map((p) => p.jenis), contains('pesan'));
      expect(peristiwa.last.sequence, 3);
    });

    test('membuang peristiwa pesan dengan nomor urut yang sudah lewat', () async {
      final server = await _ServerUji.mulai();
      addTearDown(server.tutup);

      final peristiwa = <TicketEvent>[];
      final soket = TicketSocket(
        secureStorage: _PenyimpananPalsu('token-uji'),
        alamatDasar: server.alamat,
      );
      addTearDown(soket.berhenti);

      await soket.mulai(ticketId: 'tiket-1', onEvent: peristiwa.add);

      for (var i = 0; i < 50 && server.permintaanDiterima.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      server.kirim({'jenis': 'pesan', 'ticketId': 'tiket-1', 'sequence': 5});
      server.kirim({'jenis': 'pesan', 'ticketId': 'tiket-1', 'sequence': 5});
      server.kirim({'jenis': 'pesan', 'ticketId': 'tiket-1', 'sequence': 4});

      for (var i = 0; i < 50 &&
              !peristiwa.any((p) => p.jenis == 'pesan');
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      /* Beri waktu peristiwa ganda sempat diproses kalau dedup gagal. */
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final pesan = peristiwa.where((p) => p.jenis == 'pesan').toList();
      expect(pesan.length, 1, reason: 'pesan dengan nomor urut sama harus dibuang');
      expect(pesan.single.sequence, 5);
    });

    test('melaporkan galat saat token tidak ada', () async {
      final galat = <String>[];
      final soket = TicketSocket(
        secureStorage: _PenyimpananPalsu(null),
        alamatDasar: 'http://127.0.0.1:1',
      );
      addTearDown(soket.berhenti);

      await soket.mulai(
        ticketId: 'tiket-1',
        onEvent: (_) {},
        onError: galat.add,
      );

      expect(galat, isNotEmpty);
      expect(galat.first, contains('Sesi'));
    });
  });
}
