import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../data/local/secure/secure_storage_service.dart';
import '../data/remote/auth_api_service.dart' show NiatOtp;
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

  /* Data sementara pendaftaran sebelum kode verifikasi selesai.
   *
   * Kata sandi ikut di sini hanya selama layar daftar -> OTP terbuka, di memori
   * proses, dan dibuang begitu pendaftaran selesai atau dibatalkan. Tidak pernah
   * ditulis ke secure storage maupun SharedPreferences.
   */
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
    required String password,
  }) {
    _pendingRegistration = {
      'name': name,
      'phone': phone,
      'gender': gender,
      'password': password,
    };
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Meminta kode verifikasi ke nomor WhatsApp.
  ///
  /// Niat (`login`/`register`) menentukan apakah server boleh membuat kode untuk
  /// nomor yang belum terdaftar. Kegagalan **tidak** disembunyikan: pengguna harus
  /// tahu kalau permintaan belum terkirim. Dulu kegagalan ditelan diam-diam lalu
  /// diganti akun karangan di perangkat.
  Future<bool> sendOtp(String phone, {NiatOtp? niat}) async {
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();

    final niatEfektif = niat ?? (_pendingRegistration != null ? NiatOtp.register : NiatOtp.login);

    final repo = repository;
    if (repo == null) {
      _hasLoginError = true;
      _errorMessage = 'Layanan autentikasi tidak tersedia di perangkat ini.';
      notifyListeners();
      return false;
    }

    try {
      await repo.requestOtp(phoneNumber: phone, niat: niatEfektif);
      return true;
    } catch (e) {
      _hasLoginError = true;
      _errorMessage = _pesanGalat(e);
      notifyListeners();
      return false;
    }
  }

  /// Menerjemahkan galat API menjadi kalimat yang bisa dibaca pengguna.
  String _pesanGalat(Object error) {
    final pesan = error is ApiException ? error.message : error.toString();
    return pesan.replaceFirst('ApiException: ', '').trim();
  }

  /// Menyelesaikan pendaftaran: verifikasi kode, lalu akun dibuat server.
  ///
  /// Nama dan kata sandi dikirim di langkah ini — setelah kode diverifikasi —
  /// sehingga tidak ada identitas yang tersimpan sebelum nomor terbukti.
  Future<bool> verifyRegisterOtp(String code) async {
    final repo = repository;
    final pending = _pendingRegistration;
    final phone = pending?['phone'] ?? _phoneNumber;
    final fullName = pending?['name'] ?? '';
    final gender = pending?['gender'] ?? 'Laki-laki';
    final password = pending?['password'] ?? '';

    if (repo == null) {
      _hasLoginError = true;
      _errorMessage = 'Layanan autentikasi tidak tersedia di perangkat ini.';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _hasLoginError = true;
      _errorMessage = 'Kata sandi belum diisi. Ulangi pendaftaran dari awal.';
      notifyListeners();
      return false;
    }

    try {
      final user = await repo.daftarDanSimpan(
        phoneNumber: phone,
        otp: code,
        fullName: fullName,
        password: password,
        gender: gender,
      );

      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        _hasLoginError = false;
        _errorMessage = null;
        _hasSecureToken = true;
        _pendingRegistration = null;
        await _onSessionStarted();
        notifyListeners();
        return true;
      }

      _hasLoginError = true;
      _errorMessage = 'Pendaftaran tidak dapat diselesaikan. Silakan coba lagi.';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _hasLoginError = true;
      _errorMessage = _pesanGalat(e);
      notifyListeners();
      return false;
    } catch (_) {
      _hasLoginError = true;
      _errorMessage = 'Tidak dapat menghubungi server. Periksa koneksi lalu coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Masuk memakai kode verifikasi.
  ///
  /// Keputusan sepenuhnya milik server. Tidak ada kode ajaib yang diterima di
  /// perangkat: dulu jalur itu melahirkan akun yang tidak ada di database.
  Future<bool> verifyOtp(String code) async {
    if (_pendingRegistration != null) {
      return verifyRegisterOtp(code);
    }

    final repo = repository;
    if (repo == null) {
      _hasLoginError = true;
      _errorMessage = 'Layanan autentikasi tidak tersedia di perangkat ini.';
      notifyListeners();
      return false;
    }

    try {
      final user = await repo.verifyLoginOtpAndSave(
        phoneNumber: _phoneNumber,
        otp: code,
      );

      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        _hasLoginError = false;
        _errorMessage = null;
        _hasSecureToken = true;
        await _onSessionStarted();
        notifyListeners();
        return true;
      }

      _hasLoginError = true;
      _errorMessage = 'Kode verifikasi tidak sesuai. Periksa kembali kode terbaru.';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _hasLoginError = true;
      _errorMessage = _pesanGalat(e);
      notifyListeners();
      return false;
    } catch (_) {
      _hasLoginError = true;
      _errorMessage = 'Tidak dapat menghubungi server. Periksa koneksi lalu coba lagi.';
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
