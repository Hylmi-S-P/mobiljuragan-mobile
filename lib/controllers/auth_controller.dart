import 'package:flutter/foundation.dart';
import '../data/local/secure/secure_storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Controller untuk mengelola autentikasi berbasis OTP WhatsApp dan sesi pengguna
/// dengan token aman di FlutterSecureStorage (Hardware Keystore).
class AuthController extends ChangeNotifier {
  final AuthRepository? repository;
  final SecureStorageService? secureStorage;

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  String _phoneNumber = '';
  String _inputOtp = '';
  bool _hasLoginError = false;
  String? _errorMessage;
  bool _hasSecureToken = false;

  // Data sementara pendaftaran sebelum verifikasi OTP selesai
  Map<String, String>? _pendingRegistration;

  AuthController({
    this.repository,
    this.secureStorage,
  });

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String get phoneNumber => _phoneNumber;
  String get inputOtp => _inputOtp;
  bool get hasLoginError => _hasLoginError;
  String? get errorMessage => _errorMessage;
  Map<String, String>? get pendingRegistration => _pendingRegistration;
  bool get hasSecureToken => _hasSecureToken;

  /// Memulihkan sesi pengguna dari Secure Storage saat aplikasi pertama kali dibuka (Guest Mode jika belum login)
  Future<void> initSession() async {
    final storage = secureStorage;
    final repo = repository;

    if (storage != null) {
      final hasToken = await storage.hasValidToken();
      _hasSecureToken = hasToken;

      if (hasToken && repo != null) {
        final restoredUser = await repo.restoreSession();
        if (restoredUser != null) {
          _currentUser = restoredUser;
          _isLoggedIn = true;
          notifyListeners();
          return;
        }
      }
    }

    // Default Guest Mode: pengguna belum login
    _currentUser = null;
    _isLoggedIn = false;
    _hasSecureToken = false;
    notifyListeners();
  }

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  void setInputOtp(String otp) {
    _inputOtp = otp;
    if (_hasLoginError) {
      _hasLoginError = false;
      _errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> _saveSecureTokenAsync(UserModel user) async {
    final storage = secureStorage;
    if (storage != null) {
      await storage.saveAuthTokens(
        accessToken: 'secure_session_${DateTime.now().millisecondsSinceEpoch}',
      );
      await storage.saveUserIdentity(
        userId: user.id,
        phoneNumber: user.phoneNumber,
        fullName: user.name,
        gender: user.gender,
        nik: user.idCardNumber,
      );
      _hasSecureToken = true;
      notifyListeners();
    }
  }

  /// Menyimpan data pendaftaran sebelum verifikasi kode OTP
  void setPendingRegistration({
    required String name,
    required String phone,
    required String gender,
  }) {
    _pendingRegistration = {
      'name': name,
      'phone': phone,
      'gender': gender,
    };
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Mengirim permintaan kode OTP ke nomor WhatsApp via backend API
  Future<void> sendOtp(String phone) async {
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();

    final repo = repository;
    if (repo != null) {
      try {
        await repo.requestOtp(
          phoneNumber: phone,
          fullName: _pendingRegistration?['name'],
        );
      } catch (_) {
        // Fallback offline / demo mode
      }
    }
  }

  /// Verifikasi kode OTP pendaftaran pelanggan baru
  Future<bool> verifyRegisterOtp(String code) async {
    final repo = repository;
    final phone = _pendingRegistration?['phone'] ?? _phoneNumber;
    final fullName = _pendingRegistration?['name'] ?? 'Pelanggan MobilJuragan';
    final gender = _pendingRegistration?['gender'] ?? 'Laki-laki';

    if (repo != null) {
      try {
        final verifiedUser = await repo.verifyOtpAndSave(
          phoneNumber: phone,
          otp: code,
          fullName: fullName,
          gender: gender,
        );
        if (verifiedUser != null) {
          _currentUser = verifiedUser;
          _isLoggedIn = true;
          _hasLoginError = false;
          _errorMessage = null;
          _hasSecureToken = true;
          _pendingRegistration = null;
          notifyListeners();
          return true;
        }
      } catch (_) {
        // Fallback offline jika backend tidak dapat dihubungi
      }
    }

    // Fallback simulasi kode demo
    if (code == '123456' || code == '888888' || code == '1234') {
      final actualName = fullName.trim().isNotEmpty ? fullName.trim() : 'Pelanggan MobilJuragan';
      final newUser = UserModel(
        id: 'USR-MKQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        name: actualName,
        phoneNumber: phone,
        gender: gender ?? 'Laki-laki',
        city: 'Merauke, Papua Selatan',
        avatarInitials: UserModel.computeInitials(actualName),
        isVerified: true,
      );

      _currentUser = newUser;
      _isLoggedIn = true;
      _hasLoginError = false;
      _errorMessage = null;
      _pendingRegistration = null;
      await _saveSecureTokenAsync(newUser);
      notifyListeners();
      return true;
    } else {
      _hasLoginError = true;
      _errorMessage = 'Kode OTP tidak cocok. Masukkan 123456 untuk pengujian.';
      notifyListeners();
      return false;
    }
  }

  /// Verifikasi kode OTP untuk masuk akun (login)
  Future<bool> verifyOtp(String code) async {
    // Jika ada pending registration, teruskan ke verifyRegisterOtp
    if (_pendingRegistration != null) {
      return await verifyRegisterOtp(code);
    }

    final repo = repository;
    if (repo != null) {
      try {
        final verifiedUser = await repo.verifyOtpAndSave(
          phoneNumber: _phoneNumber,
          otp: code,
        );
        if (verifiedUser != null) {
          _currentUser = verifiedUser;
          _isLoggedIn = true;
          _hasLoginError = false;
          _errorMessage = null;
          _hasSecureToken = true;
          notifyListeners();
          return true;
        }
      } catch (_) {
        // Fallback offline
      }
    }

    // Fallback simulasi kode demo
    if (code == '123456' || code == '888888' || code == '1234') {
      _isLoggedIn = true;
      _hasLoginError = false;
      _errorMessage = null;
      final savedName = _pendingRegistration?['name']?.toString() ?? 'Pelanggan MobilJuragan';
      final savedGender = _pendingRegistration?['gender']?.toString() ?? 'Laki-laki';
      final phone = _phoneNumber.isNotEmpty ? _phoneNumber : '+62 812-4800-2910';
      _currentUser = UserModel(
        id: 'USR-MKQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        name: savedName,
        phoneNumber: phone,
        gender: savedGender,
        city: 'Merauke, Papua Selatan',
        avatarInitials: UserModel.computeInitials(savedName),
        isVerified: true,
      );
      await _saveSecureTokenAsync(_currentUser!);
      _pendingRegistration = null;
      notifyListeners();
      return true;
    } else {
      _hasLoginError = true;
      _errorMessage = 'Kode OTP tidak cocok. Masukkan 123456 untuk pengujian.';
      notifyListeners();
      return false;
    }
  }

  /// Keluar dari sesi akun (menghapus token di Hardware Keystore)
  Future<void> logout() async {
    _isLoggedIn = false;
    _hasSecureToken = false;
    _currentUser = null;
    final storage = secureStorage;
    if (storage != null) {
      await storage.clearAuth();
    }
    final repo = repository;
    if (repo != null) {
      await repo.logout();
    }
    notifyListeners();
  }

  /// Masuk dengan akun default untuk mode demo
  void loginAsDefault() {
    _currentUser = const UserModel(
      id: 'USR-MKQ-001',
      name: 'Pelanggan MobilJuragan',
      phoneNumber: '+62 812-4800-2910',
      gender: 'Laki-laki',
      city: 'Merauke, Papua Selatan',
      avatarInitials: 'MJ',
      isVerified: true,
    );
    _isLoggedIn = true;
    _hasLoginError = false;
    _saveSecureTokenAsync(_currentUser!);
    notifyListeners();
  }

  /// Memperbarui data profil pengguna
  void updateProfile({
    required String name,
    required String phone,
    String? gender,
    String? email,
    String? idCard,
  }) {
    final current = _currentUser;
    final cleanName = name.trim().isNotEmpty ? name.trim() : (current?.name ?? 'Pelanggan MobilJuragan');
    _currentUser = UserModel(
      id: current?.id ?? 'USR-MKQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      name: cleanName,
      phoneNumber: phone,
      gender: gender ?? current?.gender ?? 'Laki-laki',
      email: email ?? '',
      idCardNumber: idCard ?? current?.idCardNumber ?? '',
      city: current?.city ?? 'Merauke, Papua Selatan',
      avatarInitials: UserModel.computeInitials(cleanName),
      isVerified: true,
    );
    _saveSecureTokenAsync(_currentUser!);
    notifyListeners();
  }

  /// Kompatibilitas pendaftaran profil lokal
  void register({
    required String name,
    required String phone,
    String? gender,
    String? email,
    String? idCard,
  }) {
    updateProfile(
      name: name,
      phone: phone,
      gender: gender,
      email: email,
      idCard: idCard,
    );
  }

  void triggerErrorState([String? message]) {
    _hasLoginError = true;
    _errorMessage = message ?? 'Kode OTP tidak sesuai atau kedaluwarsa.';
    notifyListeners();
  }

  void clearErrorState() {
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }
}
