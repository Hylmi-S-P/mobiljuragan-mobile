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

  /// Sedang menyimpan perubahan profil (nama/kata sandi) ke server.
  bool _isMenyimpanProfil = false;

  /// Sedang meminta kode verifikasi ke server.
  bool _isLoadingOtp = false;

  /// `updatedAt` profil terakhir yang dibaca dari server, untuk konkurensi
  /// optimistik saat `PATCH /me`.
  String? _profilUpdatedAt;

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
  bool get isMenyimpanProfil => _isMenyimpanProfil;
  bool get isLoadingOtp => _isLoadingOtp;

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

    _isLoadingOtp = true;
    notifyListeners();

    try {
      await repo.requestOtp(phoneNumber: phone, niat: niatEfektif);
      return true;
    } catch (e) {
      _hasLoginError = true;
      _errorMessage = _pesanGalat(e);
      return false;
    } finally {
      _isLoadingOtp = false;
      notifyListeners();
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

  /// Mengubah nama lewat server.
  ///
  /// Nama adalah data milik server. Versi sebelumnya menyimpannya di perangkat
  /// saja, sehingga server dan aplikasi menampilkan nama berbeda — dan itulah
  /// pintu masuk insiden "nama pelanggan tertimpa".
  ///
  /// Mengembalikan pesan galat yang bisa ditampilkan, atau null bila berhasil.
  Future<String?> ubahNama(String namaBaru) async {
    final current = _currentUser;
    if (current == null) {
      return 'Masuk akun terlebih dahulu untuk mengubah profil.';
    }

    final repo = repository;
    if (repo == null) {
      return 'Layanan autentikasi tidak tersedia di perangkat ini.';
    }

    final nama = namaBaru.trim();
    if (nama.length < 3) {
      return 'Nama lengkap minimal 3 karakter.';
    }
    if (nama == current.name) {
      return null;
    }

    _isMenyimpanProfil = true;
    notifyListeners();

    try {
      final diperbarui = await repo.ubahNama(
        pengguna: current,
        namaBaru: nama,
        expectedUpdatedAt: _profilUpdatedAt,
      );
      _currentUser = diperbarui;
      _hasLoginError = false;
      _errorMessage = null;
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 412) {
        /* Data di server sudah berubah sejak dibaca. Muat ulang profil supaya
           pengguna melihat nilai terbaru sebelum mencoba lagi. */
        await segarkanProfil();
        return 'Data profil sudah berubah di tempat lain. Nilai terbaru sudah dimuat, silakan periksa lalu simpan lagi.';
      }
      return _pesanGalat(e);
    } catch (e) {
      return _pesanGalat(e);
    } finally {
      _isMenyimpanProfil = false;
      notifyListeners();
    }
  }

  /// Membuat atau mengganti kata sandi.
  ///
  /// Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> ubahKataSandi({
    required String kataSandiBaru,
    String? kataSandiSaatIni,
  }) async {
    if (_currentUser == null) {
      return 'Masuk akun terlebih dahulu untuk mengubah kata sandi.';
    }

    final repo = repository;
    if (repo == null) {
      return 'Layanan autentikasi tidak tersedia di perangkat ini.';
    }

    _isMenyimpanProfil = true;
    notifyListeners();

    try {
      await repo.ubahKataSandi(
        kataSandiBaru: kataSandiBaru,
        kataSandiSaatIni: kataSandiSaatIni,
      );
      await segarkanProfil();
      _errorMessage = null;
      _hasLoginError = false;
      return null;
    } on ApiException catch (e) {
      return _pesanGalat(e);
    } catch (e) {
      return _pesanGalat(e);
    } finally {
      _isMenyimpanProfil = false;
      notifyListeners();
    }
  }

  /// Memuat ulang profil dari server (dipakai setelah perubahan data).
  Future<void> segarkanProfil() async {
    final repo = repository;
    if (repo == null) return;
    try {
      final user = await repo.restoreSession();
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        _hasSecureToken = true;
      } else {
        /* Token tidak lagi sah (mis. kata sandi diganti di perangkat lain).
           Kembali ke mode tamu tanpa mempertahankan identitas lama. */
        _currentUser = null;
        _isLoggedIn = false;
        _hasSecureToken = false;
      }
    } catch (_) {
      // Gagal jaringan: pertahankan data yang sudah tampil.
    }
    notifyListeners();
  }

  /// Masuk memakai kata sandi.
  Future<bool> masukDenganKataSandi({
    required String phone,
    required String password,
  }) async {
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();

    final repo = repository;
    if (repo == null) {
      _hasLoginError = true;
      _errorMessage = 'Layanan autentikasi tidak tersedia di perangkat ini.';
      notifyListeners();
      return false;
    }

    try {
      final user = await repo.loginKataSandi(phoneNumber: phone, password: password);
      if (user == null) {
        _hasLoginError = true;
        _errorMessage = 'Nomor atau kata sandi tidak sesuai.';
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoggedIn = true;
      _hasSecureToken = true;
      _hasLoginError = false;
      _errorMessage = null;
      await _onSessionStarted();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _hasLoginError = true;
      _errorMessage = _pesanGalat(e);
      notifyListeners();
      return false;
    } catch (e) {
      _hasLoginError = true;
      _errorMessage = _pesanGalat(e);
      notifyListeners();
      return false;
    }
  }

  /// Meminta kode pemulihan kata sandi.
  Future<void> mintaResetKataSandi(String phoneNumber) async {
    final repo = repository;
    if (repo == null) {
      throw ApiException('Layanan autentikasi tidak tersedia di perangkat ini.');
    }
    try {
      await repo.mintaResetKataSandi(phoneNumber);
    } on ApiException catch (e) {
      _errorMessage = _pesanGalat(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Menetapkan kata sandi baru lewat kode pemulihan.
  ///
  /// Mengembalikan pesan galat, atau null bila berhasil (dan sesi langsung aktif).
  Future<String?> resetKataSandi({
    required String phoneNumber,
    required String otp,
    required String kataSandiBaru,
  }) async {
    final repo = repository;
    if (repo == null) {
      return 'Layanan autentikasi tidak tersedia di perangkat ini.';
    }

    try {
      final user = await repo.resetKataSandi(
        phoneNumber: phoneNumber,
        otp: otp,
        password: kataSandiBaru,
      );
      if (user == null) {
        return 'Kata sandi belum dapat diperbarui. Coba lagi.';
      }

      _currentUser = user;
      _isLoggedIn = true;
      _hasSecureToken = true;
      _hasLoginError = false;
      _errorMessage = null;
      await _onSessionStarted();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return _pesanGalat(e);
    } catch (e) {
      return _pesanGalat(e);
    }
  }

  /// Mengeluarkan semua perangkat, termasuk perangkat ini.
  Future<void> keluarkanSemuaPerangkat() async {
    final repo = repository;
    try {
      await repo?.logoutSemuaPerangkat();
    } catch (_) {
      // Tetap bersihkan sesi lokal walaupun server tidak terjangkau.
    }
    await logout();
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
