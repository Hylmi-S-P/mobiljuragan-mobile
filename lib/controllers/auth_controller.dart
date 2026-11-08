import 'package:flutter/foundation.dart';
import '../data/local/secure/secure_storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../models/user_model.dart';

/// Controller untuk mengelola autentikasi berbasis OTP WhatsApp dan sesi pengguna
/// dengan token aman di FlutterSecureStorage (Hardware Keystore).
class AuthController extends ChangeNotifier {
  final AuthRepository? repository;
  final SecureStorageService? secureStorage;

  /// Cache pesanan lokal. Dipakai untuk memastikan riwayat satu akun tidak
  /// terbawa ke akun lain: dibersihkan saat logout dan saat akun berganti.
  final BookingRepository? bookingRepository;

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
    this.bookingRepository,
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

  /// Menyimpan identitas sesi yang sudah diterbitkan server.
  ///
  /// Token TIDAK pernah dibuat di sini. Versi sebelumnya menulis
  /// `secure_session_<timestamp>` ketika alur demo/offline dipakai, sehingga
  /// aplikasi menganggap dirinya punya sesi sah padahal server tidak pernah
  /// menerbitkan apa pun. Sekarang: kalau server belum memberi token, sesi tetap
  /// tamu dan `hasValidToken()` akan bernilai false.
  Future<void> _saveSecureTokenAsync(UserModel user) async {
    final storage = secureStorage;
    if (storage != null) {
      await storage.saveUserIdentity(
        userId: user.id,
        phoneNumber: user.phoneNumber,
        fullName: user.name,
        gender: user.gender,
        nik: user.idCardNumber,
      );
      _hasSecureToken = await storage.hasValidToken();
      notifyListeners();
    }
  }

  /// Dipanggil setiap kali sesi baru dimulai.
  ///
  /// Membaca ulang pemilik cache dari secure storage lalu membuang cache akun
  /// lain, supaya halaman riwayat tidak menampilkan pesanan pemilik sebelumnya.
  Future<void> _onSessionStarted() async {
    final bookingRepo = bookingRepository;
    if (bookingRepo == null) return;
    await bookingRepo.refreshSession();
    await bookingRepo.purgeOtherAccounts();
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
          await _onSessionStarted();
          notifyListeners();
          return true;
        }
      } catch (_) {
        // Fallback offline jika backend tidak dapat dihubungi
      }
    }

    /* Verifikasi hanya boleh diputuskan server.
     *
     * Sebelumnya kode demo (123456 / 888888 / 1234) diterima di sisi klien, lalu
     * aplikasi membuat akun khayalan berid `USR-MKQ-<timestamp>` yang tidak pernah
     * ada di database. Akibatnya pengguna tampak sudah masuk, punya riwayat, tetapi
     * akun itu tidak dikenali backend maupun dashboard — dan nama yang diketik di
     * form bisa "menimpa" tampilan akun lain karena identitasnya dikarang sendiri.
     */
    _hasLoginError = true;
    _errorMessage =
        'Verifikasi tidak dapat diproses karena server tidak menjawab. Periksa koneksi lalu coba lagi.';
    notifyListeners();
    return false;
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
          await _onSessionStarted();
          notifyListeners();
          return true;
        }
      } catch (_) {
        // Fallback offline
      }
    }

    /* Login juga tidak boleh diputuskan klien.
     *
     * Dulu kode demo diterima tanpa server, lalu identitas dikarang di perangkat.
     * Itulah asal akun "hantu": aplikasi menampilkan nama dan inisial yang tidak
     * pernah ada di database, lengkap dengan riwayat yang tersimpan lokal saja.
     */
    _isLoggedIn = false;
    _hasLoginError = true;
    _errorMessage =
        'Kode verifikasi tidak dapat diperiksa karena server tidak menjawab. Periksa koneksi lalu coba lagi.';
    notifyListeners();
    return false;
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

    /* Cache pesanan bersifat sementara; server tetap sumber kebenaran. Menghapus
       seluruh cache saat logout adalah cara paling aman agar akun berikutnya
       tidak melihat riwayat pemilik sebelumnya. */
    final bookingRepo = bookingRepository;
    if (bookingRepo != null) {
      await bookingRepo.clearLocalBookings();
      await bookingRepo.refreshSession();
    }

    notifyListeners();
  }

  /// Memperbarui data profil pengguna
  ///
  /// Profil hanya bisa diubah kalau ada sesi sah. `id` tidak pernah dikarang:
  /// sebelumnya baris ini membuat `USR-MKQ-<timestamp>` ketika `currentUser`
  /// null, sehingga perubahan profil pada mode tamu melahirkan identitas palsu.
  void updateProfile({
    required String name,
    required String phone,
    String? gender,
    String? email,
    String? idCard,
  }) {
    final current = _currentUser;
    if (current == null) {
      /* Mode tamu: tidak ada akun untuk diperbarui. Profil hanya bermakna setelah
         server menerbitkan identitas (id + token). */
      _hasLoginError = true;
      _errorMessage = 'Masuk akun terlebih dahulu untuk mengubah profil.';
      notifyListeners();
      return;
    }
    final cleanName = name.trim().isNotEmpty ? name.trim() : current.name;
    _currentUser = UserModel(
      id: current.id,
      name: cleanName,
      phoneNumber: phone,
      gender: gender ?? current.gender,
      email: email ?? '',
      idCardNumber: idCard ?? current.idCardNumber,
      city: current.city,
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
