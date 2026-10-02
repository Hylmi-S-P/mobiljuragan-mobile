import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Helper validator untuk aturan keamanan password
class PasswordRules {
  static bool hasMinLength(String p) => p.length >= 8;
  static bool hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool hasNumber(String p) => RegExp(r'[0-9]').hasMatch(p);
  static bool hasSymbol(String p) =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\\/~`\[\]]').hasMatch(p);

  static bool isValid(String p) {
    return hasMinLength(p) &&
        hasUppercase(p) &&
        hasNumber(p) &&
        hasSymbol(p);
  }
}

/// Controller untuk mengelola autentikasi, status login, dan profil pengguna
class AuthController extends ChangeNotifier {
  UserModel? _currentUser = UserModel.defaultUser;
  bool _isLoggedIn = true;
  String _phoneNumber = '+62 812-4800-2910';
  String _inputOtp = '';
  bool _hasLoginError = false;
  String? _errorMessage;

  // Kredensial default untuk demo aplikasi
  String _currentPassword = 'Merauke#2026';
  final Map<String, String> _userPasswords = {
    'harun.merauke@gmail.com': 'Merauke#2026',
    '812-4800-2910': 'Merauke#2026',
    '+62 812-4800-2910': 'Merauke#2026',
    '081248002910': 'Merauke#2026',
  };

  // Data sementara saat pendaftaran sebelum verifikasi OTP
  Map<String, String>? _pendingRegistration;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String get phoneNumber => _phoneNumber;
  String get inputOtp => _inputOtp;
  bool get hasLoginError => _hasLoginError;
  String? get errorMessage => _errorMessage;
  String get currentPassword => _currentPassword;
  Map<String, String>? get pendingRegistration => _pendingRegistration;

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

  /// Login menggunakan Email / Nomor HP dan Password (standar app pada umumnya)
  bool loginWithPassword({
    required String identifier,
    required String password,
  }) {
    final cleanId = identifier.trim().toLowerCase();
    final cleanPhone = cleanId.replaceAll(RegExp(r'[\s\-]'), '');

    // Cek kecocokan kredensial
    bool isMatch = false;

    if (_userPasswords.containsKey(cleanId) && _userPasswords[cleanId] == password) {
      isMatch = true;
    } else if (_userPasswords.containsKey(cleanPhone) && _userPasswords[cleanPhone] == password) {
      isMatch = true;
    } else if (cleanId == 'harun.merauke@gmail.com' && password == _currentPassword) {
      isMatch = true;
    } else if ((cleanPhone == '81248002910' || cleanPhone == '+6281248002910' || cleanPhone == '081248002910') &&
        password == _currentPassword) {
      isMatch = true;
    }

    if (isMatch) {
      _isLoggedIn = true;
      _hasLoginError = false;
      _errorMessage = null;
      _currentUser ??= UserModel.defaultUser;
      notifyListeners();
      return true;
    } else {
      _hasLoginError = true;
      _errorMessage = 'Email/No HP atau password salah. Silakan periksa kembali.';
      notifyListeners();
      return false;
    }
  }

  /// Menyimpan data pendaftaran sebelum lanjut ke tahap verifikasi OTP
  void setPendingRegistration({
    required String name,
    required String phone,
    required String email,
    required String idCard,
    required String city,
    required String password,
  }) {
    _pendingRegistration = {
      'name': name,
      'phone': phone,
      'email': email,
      'idCard': idCard,
      'city': city,
      'password': password,
    };
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Menyelesaikan pendaftaran setelah verifikasi kode OTP berhasil
  bool verifyRegisterOtp(String code) {
    if (code == '123456' || code == '888888' || code == '1234') {
      if (_pendingRegistration != null) {
        final name = _pendingRegistration!['name']!;
        final phone = _pendingRegistration!['phone']!;
        final email = _pendingRegistration!['email']!;
        final idCard = _pendingRegistration!['idCard']!;
        final city = _pendingRegistration!['city']!;
        final password = _pendingRegistration!['password']!;

        _currentUser = UserModel(
          id: 'USR-MKQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          name: name,
          phoneNumber: phone,
          email: email,
          idCardNumber: idCard,
          city: city.isNotEmpty ? city : 'Merauke, Papua Selatan',
          avatarInitials: name.isNotEmpty
              ? (name.trim().split(' ').length > 1
                  ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'.toUpperCase()
                  : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase())
              : 'MJ',
          isVerified: true,
        );

        // Daftarkan password baru ke kredensial
        _currentPassword = password;
        _userPasswords[email.toLowerCase()] = password;
        _userPasswords[phone.replaceAll(RegExp(r'[\s\-]'), '')] = password;
        _pendingRegistration = null;
      } else {
        _currentUser = UserModel.defaultUser;
      }

      _isLoggedIn = true;
      _hasLoginError = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _hasLoginError = true;
      _errorMessage = 'Kode OTP tidak cocok. Masukkan 123456 untuk simulasi demo.';
      notifyListeners();
      return false;
    }
  }

  /// Reset Password melalui verifikasi OTP
  bool resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) {
    if (otp != '123456' && otp != '888888' && otp != '1234') {
      _hasLoginError = true;
      _errorMessage = 'Kode OTP pemulihan tidak sesuai atau kedaluwarsa.';
      notifyListeners();
      return false;
    }

    if (!PasswordRules.isValid(newPassword)) {
      _hasLoginError = true;
      _errorMessage = 'Password baru belum memenuhi semua kriteria keamanan.';
      notifyListeners();
      return false;
    }

    final cleanId = identifier.trim().toLowerCase();
    final cleanPhone = cleanId.replaceAll(RegExp(r'[\s\-]'), '');

    _currentPassword = newPassword;
    _userPasswords[cleanId] = newPassword;
    _userPasswords[cleanPhone] = newPassword;

    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Simulasi kirim OTP ke nomor WhatsApp / SMS
  void sendOtp(String phone) {
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Verifikasi kode OTP umum
  bool verifyOtp(String code) {
    if (code == '123456' || code == '888888' || code == '1234' || code == '8888') {
      _isLoggedIn = true;
      _hasLoginError = false;
      _errorMessage = null;
      _currentUser ??= UserModel.defaultUser;
      notifyListeners();
      return true;
    } else {
      _hasLoginError = true;
      _errorMessage = 'Kode OTP tidak cocok. Masukkan 123456 untuk simulasi.';
      notifyListeners();
      return false;
    }
  }

  /// Memicu tampilan State Error secara manual untuk demonstrasi
  void triggerErrorState([String? message]) {
    _hasLoginError = true;
    _errorMessage = message ?? 'Kode OTP tidak sesuai atau kedaluwarsa.';
    notifyListeners();
  }

  /// Membersihkan State Error
  void clearErrorState() {
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Pendaftaran akun pengguna baru langsung
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
    _currentPassword = 'Merauke#2026';
    _isLoggedIn = true;
    _hasLoginError = false;
    notifyListeners();
  }
}
