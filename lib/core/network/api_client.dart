import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
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
      throw ApiException('Terjadi kesalahan jaringan: $e');
    }
  }

  /// Request POST terstandar
  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool requiresAuth = false}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConstants.timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
    } on TimeoutException {
      throw ApiException('Koneksi waktu habis (Timeout).');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan jaringan: $e');
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
      String errorMessage = 'Permintaan gagal (${response.statusCode})';
      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        errorMessage = decoded['message'].toString();
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
