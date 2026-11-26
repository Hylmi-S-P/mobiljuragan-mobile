import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../util/pesan_galat.dart';
import '../../data/local/secure/secure_storage_service.dart';

/// Exception khusus untuk kegagalan komunikasi API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Klien HTTP terpusat dengan injeksi token aman & timeout handling
class ApiClient {
  static final http.Client _sharedClient = http.Client();
  static final math.Random _random = math.Random();

  /// Klien HTTP bersama agar socket TLS (keep-alive) dipakai ulang lintas layanan.
  static http.Client get sharedHttpClient => _sharedClient;

  static bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  final http.Client _client;
  final bool _usesSharedClient;
  final SecureStorageService _secureStorage;
  final int _maxGetRetries;

  ApiClient({
    http.Client? client,
    SecureStorageService? secureStorage,
    int? maxGetRetries,
  }) : _usesSharedClient = client == null,
       _client = client ?? _sharedClient,
       _secureStorage = secureStorage ?? SecureStorageService(),
       _maxGetRetries = maxGetRetries ?? ((client == null && !_isFlutterTest) ? 2 : 0);

  Future<void> _tungguRetry(int attempt) {
    final baseMs = attempt == 0 ? 400 : 1200;
    final jitterMs = _random.nextInt(151);
    return Future<void>.delayed(Duration(milliseconds: baseMs + jitterMs));
  }

  /// Penangan terpusat untuk sesi yang ditolak server (HTTP 401/403).
  static Future<void> Function()? onUnauthorized;

  /// Penangan terpusat yang membawa kode status dan pesan penolakan server.
  static Future<void> Function(
    int statusCode,
    String? errorCode,
    String? errorMessage,
  )? onSessionRejected;

  /// Menghindari pemanggilan berulang saat beberapa permintaan gagal bersamaan.
  static bool _sedangMenanganiTolak = false;

  void _laporTidakBerwenang({
    required int statusCode,
    String? errorCode,
    String? errorMessage,
  }) {
    final detailedHandler = onSessionRejected;
    final legacyHandler = onUnauthorized;
    if ((detailedHandler == null && legacyHandler == null) ||
        _sedangMenanganiTolak) {
      return;
    }

    /* Handler sengaja tidak ditunggu: pemanggilnya sedang menerima galat dan
       harus tetap mendapat [ApiException] yang sama seperti sebelumnya. */
    _sedangMenanganiTolak = true;
    final Future<void> kerja = detailedHandler != null
        ? detailedHandler(statusCode, errorCode, errorMessage)
        : legacyHandler!();
    unawaited(
      kerja
          .catchError((Object galat) {
            if (kDebugMode) {
              debugPrint('Gagal membersihkan sesi yang ditolak: ${galat.runtimeType}');
            }
          })
          .whenComplete(() => _sedangMenanganiTolak = false),
    );
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Request GET terstandar dengan retry terbatas untuk gangguan jaringan sementara.
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams, bool requiresAuth = false}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path').replace(
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
    );

    for (var attempt = 0; attempt <= _maxGetRetries; attempt++) {
      try {
        final headers = await _buildHeaders(requiresAuth: requiresAuth);

        final response = await _client
            .get(uri, headers: headers)
            .timeout(ApiConstants.timeoutDuration);

        return _handleResponse(response, requiresAuth: requiresAuth);
      } on SocketException {
        if (attempt < _maxGetRetries) {
          await _tungguRetry(attempt);
          continue;
        }
        throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
      } on TimeoutException {
        if (attempt < _maxGetRetries) {
          await _tungguRetry(attempt);
          continue;
        }
        throw ApiException('Koneksi waktu habis (Timeout).');
      } on http.ClientException catch (e) {
        if (attempt < _maxGetRetries) {
          await _tungguRetry(attempt);
          continue;
        }
        throw ApiException(PesanGalat.ramah('Permintaan tidak dapat diselesaikan', galat: e));
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(PesanGalat.ramah('Permintaan tidak dapat diselesaikan', galat: e));
      }
    }
    throw ApiException('Permintaan tidak dapat diselesaikan.');
  }

  /// Request POST multipart (unggahan berkas).
  ///
  /// Header `Content-Type` sengaja tidak diisi manual: `MultipartRequest`
  /// menuliskan boundary-nya sendiri, dan menimpanya membuat body tidak terbaca
  /// server.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, http.MultipartFile> files,
    Map<String, String> fields = const {},
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll(fields)
        ..files.addAll(files.values);

      request.headers['Accept'] = 'application/json';
      if (requiresAuth) {
        final token = await _secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      final streamed = await _client
          .send(request)
          .timeout(timeout ?? ApiConstants.uploadTimeoutDuration);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
    } on TimeoutException {
      throw ApiException('Koneksi waktu habis (Timeout).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(PesanGalat.ramah('Permintaan tidak dapat diselesaikan', galat: e));
    }
  }

  /// Request POST terstandar
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(timeout ?? ApiConstants.timeoutDuration);

      return _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
    } on TimeoutException {
      throw ApiException('Koneksi waktu habis (Timeout).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(PesanGalat.ramah('Permintaan tidak dapat diselesaikan', galat: e));
    }
  }

  /// Request PATCH terstandar
  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool requiresAuth = false}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConstants.timeoutDuration);

      return _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
    } on TimeoutException {
      throw ApiException('Koneksi waktu habis (Timeout).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(PesanGalat.ramah('Permintaan tidak dapat diselesaikan', galat: e));
    }
  }

  dynamic _handleResponse(http.Response response, {bool requiresAuth = false}) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } else {
      String? errorCode;
      String? serverMessage;
      if (decoded is Map<String, dynamic>) {
        final rawError = decoded['error'];
        if (rawError is Map && rawError['code'] != null) {
          errorCode = rawError['code'].toString();
        } else if (decoded['code'] != null) {
          errorCode = decoded['code'].toString();
        }

        if (decoded.containsKey('message') && decoded['message'] != null) {
          serverMessage = decoded['message'].toString();
        } else if (rawError is Map && rawError['message'] != null) {
          serverMessage = rawError['message'].toString();
        }
      }

      if (requiresAuth && (response.statusCode == 401 || response.statusCode == 403)) {
        _laporTidakBerwenang(
          statusCode: response.statusCode,
          errorCode: errorCode,
          errorMessage: serverMessage,
        );
      }

      final errorMessage = serverMessage ?? 'Permintaan gagal (${response.statusCode})';
      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
        details: decoded,
      );
    }
  }

  void dispose() {
    if (!_usesSharedClient) {
      _client.close();
    }
  }
}
