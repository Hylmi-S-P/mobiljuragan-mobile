import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  final http.Client _client;
  final SecureStorageService _secureStorage;

  ApiClient({
    http.Client? client,
    SecureStorageService? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorageService();

  /// Penangan terpusat untuk sesi yang ditolak server (HTTP 401/403).
  ///
  /// Dipasang sekali oleh [AuthController] saat aplikasi dimulai. Sebelum ini,
  /// token yang sudah kedaluwarsa hanya membuat setiap layar gagal satu per
  /// satu: pengguna tetap terlihat "masuk" padahal seluruh permintaannya
  /// ditolak, dan tidak pernah dikembalikan ke Guest Mode.
  static Future<void> Function()? onUnauthorized;

  /// Menghindari pemanggilan berulang saat beberapa permintaan gagal bersamaan.
  static bool _sedangMenanganiTolak = false;

  void _laporTidakBerwenang() {
    final handler = onUnauthorized;
    if (handler == null || _sedangMenanganiTolak) return;

    /* Handler sengaja tidak ditunggu: pemanggilnya sedang menerima galat dan
       harus tetap mendapat [ApiException] yang sama seperti sebelumnya. */
    _sedangMenanganiTolak = true;
    unawaited(
      handler()
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

  /// Request GET terstandar
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams, bool requiresAuth = false}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path').replace(
        queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
      );
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConstants.timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
    } on TimeoutException {
      throw ApiException('Koneksi waktu habis (Timeout).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(PesanGalat.ramah('Permintaan tidak dapat diselesaikan', galat: e));
    }
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

      final streamed = await _client.send(request).timeout(timeout ?? ApiConstants.timeoutDuration);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
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

      return _handleResponse(response);
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

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
    } on TimeoutException {
      throw ApiException('Koneksi waktu habis (Timeout).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(PesanGalat.ramah('Permintaan tidak dapat diselesaikan', galat: e));
    }
  }

  dynamic _handleResponse(http.Response response) {
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
      if (response.statusCode == 401 || response.statusCode == 403) {
        _laporTidakBerwenang();
      }

      String errorMessage = 'Permintaan gagal (${response.statusCode})';
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('message') && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        } else if (decoded['error'] is Map && decoded['error']['message'] != null) {
          errorMessage = decoded['error']['message'].toString();
        }
      }
      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
        details: decoded,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
