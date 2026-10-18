import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/data/local/secure/secure_storage_service.dart';

void main() {
  late SecureStorageService secureStorageService;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorageService = SecureStorageService();
  });

  group('SecureStorageService (FlutterSecureStorage) Tests', () {
    test('Token autentikasi JWT disimpan dan dibaca secara aman', () async {
      expect(await secureStorageService.hasValidToken(), isFalse);

      await secureStorageService.saveAuthTokens(
        accessToken: 'mock_jwt_access_token_merauke',
        refreshToken: 'mock_jwt_refresh_token',
      );

      expect(await secureStorageService.hasValidToken(), isTrue);
      expect(await secureStorageService.getAccessToken(), equals('mock_jwt_access_token_merauke'));
      expect(await secureStorageService.getRefreshToken(), equals('mock_jwt_refresh_token'));
    });

    test('Data identitas sensitif (NIK & User ID) tersimpan dan terhapus saat clearAuth', () async {
      await secureStorageService.saveUserIdentity(
        userId: 'USR-MKQ-001',
        nik: '9101012304980002',
        phoneNumber: '+6281248002910',
      );

      expect(await secureStorageService.getUserId(), equals('USR-MKQ-001'));
      expect(await secureStorageService.getUserNik(), equals('9101012304980002'));
      expect(await secureStorageService.getUserPhone(), equals('+6281248002910'));

      // Logout / bersihkan seluruh secrets
      await secureStorageService.clearAuth();
      expect(await secureStorageService.hasValidToken(), isFalse);
      expect(await secureStorageService.getAccessToken(), isNull);
      expect(await secureStorageService.getUserId(), isNull);
      expect(await secureStorageService.getUserNik(), isNull);
    });
  });
}
