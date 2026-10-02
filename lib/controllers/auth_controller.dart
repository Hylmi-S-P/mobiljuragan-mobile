import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Controller untuk mengelola autentikasi, status login, dan profil pengguna
class AuthController extends ChangeNotifier {
  UserModel? _currentUser = UserModel.defaultUser;
  bool _isLoggedIn = true;
  String _phoneNumber = '+62 812-4800-2910';
  String _inputOtp = '';
  bool _hasLoginError = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String get phoneNumber => _phoneNumber;
  String get inputOtp => _inputOtp;
  bool get hasLoginError => _hasLoginError;
  String? get errorMessage => _errorMessage;

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

  /// Simulasi kirim OTP ke nomor WhatsApp / SMS
  void sendOtp(String phone) {
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Verifikasi kode OTP dengan dukungan simulasi error (Frame 12b)
  bool verifyOtp(String code) {
    // Kode valid default untuk demo pengujian: 123456 atau 1234
    if (code == '123456' || code == '888888' || code == '1234' || code == '8888') {
      _isLoggedIn = true;
      _hasLoginError = false;
      _errorMessage = null;
      _currentUser = UserModel.defaultUser;
      notifyListeners();
      return true;
    } else {
      _hasLoginError = true;
      _errorMessage = 'Kode OTP tidak cocok. Masukkan 123456 untuk simulasi.';
      notifyListeners();
      return false;
    }
  }

  /// Memicu tampilan State Error (Frame 12b) secara manual untuk demonstrasi
  void triggerErrorState([String? message]) {
    _hasLoginError = true;
    _errorMessage = message ?? 'Kode OTP tidak sesuai atau kedaluwarsa.';
    notifyListeners();
  }

  /// Membersihkan State Error kembali ke Frame 12 (Clean State)
  void clearErrorState() {
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Pendaftaran akun pengguna baru
  void register({
    required String name,
    required String phone,
    required String email,
    required String idCard,
  }) {
    _currentUser = UserModel(
      id: 'USR-MKQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      name: name,
      phoneNumber: phone,
      email: email,
      idCardNumber: idCard,
      city: 'Merauke, Papua Selatan',
      avatarInitials: name.isNotEmpty
          ? (name.trim().split(' ').length > 1
              ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'.toUpperCase()
              : name.substring(0, 2).toUpperCase())
          : 'MJ',
      isVerified: true,
    );
    _isLoggedIn = true;
    _hasLoginError = false;
    notifyListeners();
  }

  /// Keluar dari sesi login
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Masuk kembali dengan akun default
  void loginAsDefault() {
    _currentUser = UserModel.defaultUser;
    _isLoggedIn = true;
    _hasLoginError = false;
    notifyListeners();
  }
}
