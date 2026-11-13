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

/// Server WebSocket kecil yang meniru backend: menerima langganan, lalu
/// mengirim peristiwa yang sudah disiapkan.
class _ServerUji {
  _ServerUji(this._server);

  final HttpServer _server;
  final List<Map<String, dynamic>> diterima = [];
  WebSocket? _soket;

  static Future<_ServerUji> mulai() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final uji = _ServerUji(server);
    unawaited(uji._layani());
    return uji;
  }

  String get alamat => 'http://127.0.0.1:${_server.port}';

  Future<void> _layani() async {
    await for (final permintaan in _server) {
      final soket = await WebSocketTransformer.upgrade(permintaan);
      _soket = soket;
      soket.listen((mentah) {
        diterima.add(jsonDecode(mentah as String) as Map<String, dynamic>);
      });
    }
  }

  void kirim(Map<String, dynamic> isi) {
    _soket?.add(jsonEncode(isi));
  }

  Future<void> tutup() async {
    await _soket?.close();
    await _server.close(force: true);
  }
}

void main() {
  group('TicketSocket', () {
    test('mengirim langganan dan meneruskan peristiwa pesan', () async {
      final server = await _ServerUji.mulai();
      addTearDown(server.tutup);

      final peristiwa = <TicketEvent>[];
      final soket = TicketSocket(
        secureStorage: _PenyimpananPalsu('token-uji'),
        alamatDasar: server.alamat,
      );
      addTearDown(soket.berhenti);

      await soket.mulai(ticketId: 'tiket-1', onEvent: peristiwa.add);

      /* Tunggu langganan terkirim sebelum server membalas. */
      for (var i = 0; i < 50 && server.diterima.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(server.diterima.first['aksi'], 'langganan');
      expect(server.diterima.first['ticketId'], 'tiket-1');

      server.kirim({'jenis': 'siap', 'ticketId': 'tiket-1'});
      server.kirim({
        'jenis': 'pesan',
        'ticketId': 'tiket-1',
        'sequence': 3,
        'jumlahPesan': 3,
      });

      for (var i = 0; i < 50 && peristiwa.isEmpty; i++) {
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

      for (var i = 0; i < 50 && server.diterima.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      server.kirim({'jenis': 'pesan', 'ticketId': 'tiket-1', 'sequence': 5});
      server.kirim({'jenis': 'pesan', 'ticketId': 'tiket-1', 'sequence': 5});
      server.kirim({'jenis': 'pesan', 'ticketId': 'tiket-1', 'sequence': 4});

      for (var i = 0; i < 50 && peristiwa.isEmpty; i++) {
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
