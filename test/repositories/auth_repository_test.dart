import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<Map<String, dynamic>> requestOtp({
    required String phoneNumber,
    String? fullName,
  }) async {
    requestOtpCount++;
    lastRequestedPhone = AuthApiService.sanitizePhoneNumber(phoneNumber);
    return {'status': 'success', 'message': 'OTP sent'};
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
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
}

class FakeSecureStorageService extends SecureStorageService {
  String? _token;
  String? _userId;
  String? _nik;
  String? _phone;

  @override
  Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _token = accessToken;
  }

  @override
  Future<void> saveUserIdentity({
    required String userId,
    required String nik,
    required String phoneNumber,
  }) async {
    _userId = userId;
    _nik = nik;
    _phone = phoneNumber;
  }

  @override
  Future<bool> hasValidToken() async => _token != null && _token!.isNotEmpty;

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
    test('sanitizePhoneNumber membersihkan spasi dan tanda minus', () {
      expect(AuthApiService.sanitizePhoneNumber('+62 812-4800-2910'), equals('+6281248002910'));
      expect(AuthApiService.sanitizePhoneNumber('0812 4800 2910'), equals('081248002910'));
      expect(AuthApiService.sanitizePhoneNumber('0812-4800-2910'), equals('081248002910'));
    });

    test('requestOtp mengirim nomor telepon yang telah dibersihkan', () async {
      final fakeApi = FakeAuthApiService();
      final fakeStorage = FakeSecureStorageService();
      final repository = AuthRepository(apiService: fakeApi, secureStorage: fakeStorage);

      final res = await repository.requestOtp(phoneNumber: '+62 812-4800-2910');

      expect(res['status'], equals('success'));
      expect(fakeApi.requestOtpCount, equals(1));
      expect(fakeApi.lastRequestedPhone, equals('+6281248002910'));
    });

    test('verifyOtpAndSave memvalidasi OTP dan menyimpan token JWT ke SecureStorage', () async {
      final fakeApi = FakeAuthApiService();
      final fakeStorage = FakeSecureStorageService();
      final repository = AuthRepository(apiService: fakeApi, secureStorage: fakeStorage);

      final user = await repository.verifyOtpAndSave(
        phoneNumber: '081248002910',
        otp: '123456',
        fullName: 'Budi Santoso',
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

      await repository.verifyOtpAndSave(
        phoneNumber: '081248002910',
        otp: '123456',
      );
      expect(await repository.hasActiveSession(), isTrue);

      await repository.logout();
      expect(await repository.hasActiveSession(), isFalse);
      expect(await fakeStorage.getAccessToken(), isNull);
    });
  });
}
