import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/core/network/api_client.dart';
import 'package:mobiljuragan_mobile/data/local/secure/secure_storage_service.dart';
import 'package:mobiljuragan_mobile/data/remote/auth_api_service.dart';
import 'package:mobiljuragan_mobile/data/repositories/auth_repository.dart';

class FakeAuthApiService extends AuthApiService {
  int requestOtpCount = 0;
  int verifyOtpCount = 0;
  String? lastRequestedPhone;
  String? lastVerifiedPhone;
  String? lastVerifiedOtp;

  Map<String, dynamic>? mockVerifyResponse;

  FakeAuthApiService({this.mockVerifyResponse});

  NiatOtp? lastNiat;
  String? lastPassword;
  String? lastFullName;

  @override
  Future<Map<String, dynamic>> requestOtp({
    required String phoneNumber,
    required NiatOtp niat,
  }) async {
    requestOtpCount++;
    lastNiat = niat;
    lastRequestedPhone = AuthApiService.sanitizePhoneNumber(phoneNumber);
    return {'status': 'success', 'message': 'OTP sent'};
  }

  @override
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    verifyOtpCount++;
    lastVerifiedPhone = AuthApiService.sanitizePhoneNumber(phoneNumber);
    lastVerifiedOtp = otp;
    return mockVerifyResponse ??
        {
          'token': 'jwt_backend_token_sample_123',
          'user': {
            'id': 'user-db-001',
            'fullName': 'Budi Santoso',
            'phoneNumber': lastVerifiedPhone,
            'role': 'CUSTOMER',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String phoneNumber,
    required String otp,
    required String fullName,
    required String password,
  }) async {
    verifyOtpCount++;
    lastVerifiedPhone = AuthApiService.sanitizePhoneNumber(phoneNumber);
    lastVerifiedOtp = otp;
    lastFullName = fullName;
    lastPassword = password;
    return mockVerifyResponse ??
        {
          'token': 'jwt_backend_token_sample_123',
          'user': {
            'id': 'user-db-001',
            'fullName': fullName,
            'phoneNumber': lastVerifiedPhone,
            'role': 'CUSTOMER',
          },
        };
  }

  /// Jumlah permintaan pencabutan token yang sampai ke lapisan API.
  ///
  /// `AuthRepository.logout()` sekarang memanggil `POST /me/logout-all` sebelum
  /// menghapus salinan lokal. Tanpa override ini, test akan menembak HTTP
  /// sungguhan saat memverifikasi logout.
  int logoutSemuaPerangkatCount = 0;

  /// Bila `true`, pencabutan meniru jaringan yang putus.
  bool gagalSaatLogout = false;

  @override
  Future<Map<String, dynamic>> logoutSemuaPerangkat() async {
    logoutSemuaPerangkatCount++;
    if (gagalSaatLogout) {
      throw ApiException('Tidak dapat terhubung ke server backend (Offline).');
    }
    return {'status': 'success'};
  }
}

class FakeSecureStorageService extends SecureStorageService {
  String? _token;
  String? _userId;
  String? _nik;
  String? _phone;

  /// Batas waktu token dalam milidetik epoch, bila pemanggil mengirimkannya.
  int? _kedaluwarsa;

  @override
  Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? kedaluwarsa,
  }) async {
    _token = accessToken;
    if (kedaluwarsa != null) {
      _kedaluwarsa = kedaluwarsa.toUtc().millisecondsSinceEpoch;
    }
  }

  @override
  Future<void> saveUserIdentity({
    required String userId,
    String? nik,
    required String phoneNumber,
    String? fullName,
    String? gender,
  }) async {
    _userId = userId;
    _nik = nik;
    _phone = phoneNumber;
  }

  @override
  Future<bool> hasValidToken() async {
    if (_token == null || _token!.isEmpty) return false;
    if (_kedaluwarsa == null) return true;
    final batas = DateTime.fromMillisecondsSinceEpoch(_kedaluwarsa!, isUtc: true);
    return DateTime.now().toUtc().add(const Duration(seconds: 30)).isBefore(batas);
  }

  @override
  Future<String?> getAccessToken() async => _token;

  @override
  Future<String?> getUserId() async => _userId;

  @override
  Future<String?> getUserPhone() async => _phone;

  @override
  Future<String?> getUserNik() async => _nik;

  @override
  Future<void> clearAuth() async {
    _token = null;
    _userId = null;
    _nik = null;
    _phone = null;
  }
}

void main() {
  group('AuthRepository & AuthApiService Customer OTP Tests', () {
    test('sanitizePhoneNumber membersihkan spasi, tanda minus, dan menormalkan awalan +62 ke 08', () {
      expect(AuthApiService.sanitizePhoneNumber('+62 812-4800-2910'), equals('081248002910'));
      expect(AuthApiService.sanitizePhoneNumber('+62 0812-4800-2910'), equals('081248002910'));
      expect(AuthApiService.sanitizePhoneNumber('0812 4800 2910'), equals('081248002910'));
      expect(AuthApiService.sanitizePhoneNumber('0812-4800-2910'), equals('081248002910'));
    });

    test('requestOtp mengirim nomor telepon yang telah dibersihkan', () async {
      final fakeApi = FakeAuthApiService();
      final fakeStorage = FakeSecureStorageService();
      final repository = AuthRepository(apiService: fakeApi, secureStorage: fakeStorage);

      final res = await repository.requestOtp(
        phoneNumber: '+62 812-4800-2910',
        niat: NiatOtp.login,
      );

      expect(res['status'], equals('success'));
      expect(fakeApi.requestOtpCount, equals(1));
      expect(fakeApi.lastRequestedPhone, equals('081248002910'));
      expect(fakeApi.lastNiat, equals(NiatOtp.login));
    });

    test('verifyLoginOtpAndSave memvalidasi OTP dan menyimpan token JWT ke SecureStorage', () async {
      final fakeApi = FakeAuthApiService();
      final fakeStorage = FakeSecureStorageService();
      final repository = AuthRepository(apiService: fakeApi, secureStorage: fakeStorage);

      final user = await repository.verifyLoginOtpAndSave(
        phoneNumber: '081248002910',
        otp: '123456',
      );

      expect(user, isNotNull);
      expect(user!.id, equals('user-db-001'));
      expect(user.name, equals('Budi Santoso'));
      expect(user.isVerified, isTrue);

      expect(fakeApi.verifyOtpCount, equals(1));
      expect(fakeApi.lastVerifiedOtp, equals('123456'));

      // Verifikasi token JWT tersimpan di secure storage
      expect(await fakeStorage.hasValidToken(), isTrue);
      expect(await fakeStorage.getAccessToken(), equals('jwt_backend_token_sample_123'));
      expect(await fakeStorage.getUserId(), equals('user-db-001'));
    });

    test('logout menghapus token dan identitas dari SecureStorage', () async {
      final fakeApi = FakeAuthApiService();
      final fakeStorage = FakeSecureStorageService();
      final repository = AuthRepository(apiService: fakeApi, secureStorage: fakeStorage);

      await repository.verifyLoginOtpAndSave(
        phoneNumber: '081248002910',
        otp: '123456',
      );
      expect(await repository.hasActiveSession(), isTrue);

      await repository.logout();
      expect(await repository.hasActiveSession(), isFalse);
      expect(await fakeStorage.getAccessToken(), isNull);
    });

    test('logout mencabut token di server sebelum menghapus salinan lokal', () async {
      final fakeApi = FakeAuthApiService();
      final fakeStorage = FakeSecureStorageService();
      final repository = AuthRepository(apiService: fakeApi, secureStorage: fakeStorage);

      await repository.verifyLoginOtpAndSave(
        phoneNumber: '081248002910',
        otp: '123456',
      );

      final dicabut = await repository.cabutTokenDiServer();
      expect(dicabut, isTrue);
      expect(fakeApi.logoutSemuaPerangkatCount, equals(1));

      // Server sudah mencabut, sesi lokal baru dihapus setelahnya.
      expect(await repository.hasActiveSession(), isTrue);
      await repository.logout();
      expect(fakeApi.logoutSemuaPerangkatCount, equals(2));
      expect(await repository.hasActiveSession(), isFalse);
    });

    test('logout tetap berjalan ketika server tidak terjangkau', () async {
      final fakeApi = FakeAuthApiService()..gagalSaatLogout = true;
      final fakeStorage = FakeSecureStorageService();
      final repository = AuthRepository(apiService: fakeApi, secureStorage: fakeStorage);

      await repository.verifyLoginOtpAndSave(
        phoneNumber: '081248002910',
        otp: '123456',
      );

      await repository.logout();

      expect(fakeApi.logoutSemuaPerangkatCount, equals(1));
      expect(await repository.hasActiveSession(), isFalse);
      expect(await fakeStorage.getAccessToken(), isNull);
    });

    test('saveAuthTokens mencatat masa berlaku token dari klaim exp', () async {
      final kedaluwarsa = SecureStorageService.kedaluwarsaDariToken(
        _tokenDenganExp(DateTime.now().toUtc().add(const Duration(days: 7))),
      );

      expect(kedaluwarsa, isNotNull);
      expect(kedaluwarsa!.isAfter(DateTime.now().toUtc()), isTrue);
      expect(
        SecureStorageService.kedaluwarsaDariToken('token-tanpa-titik'),
        isNull,
      );
    });
  });
}

/// Menyusun token JWT tiruan yang hanya memuat klaim `exp`.
///
/// Tanda tangan tidak penting: perangkat hanya membaca `exp` untuk menolak token
/// yang jelas basi, sedangkan verifikasi sebenarnya tetap dilakukan server.
String _tokenDenganExp(DateTime kedaluwarsa) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode('{"exp":${kedaluwarsa.millisecondsSinceEpoch ~/ 1000}}'),
  );
  return '$header.$payload.tanda-tangan-palsu';
}
