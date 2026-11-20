import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/util/berkas_unduhan.dart';
import '../data/local/preferences/app_settings_service.dart';
import '../data/local/secure/secure_storage_service.dart';
import '../data/remote/auth_api_service.dart' show NiatOtp;
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../models/user_model.dart';
import '../services/merauke_geocoding_service.dart';
import '../services/notification_service.dart';

/// Status pemulihan sesi saat aplikasi dibuka.
///
/// Dipakai layar splash untuk memutuskan kapan boleh berpindah layar: menunggu
/// sampai statusnya bukan [memuat] lagi. Sebelumnya splash hanya menunggu
/// pengatur waktu tetap, sehingga aplikasi bisa terbuka dalam keadaan belum
/// diketahui — tamu yang sebenarnya sudah punya sesi, atau sebaliknya.
enum StatusBootSesi {
  /// Pemulihan sesi belum selesai.
  memuat,

  /// Sesi selesai dipulihkan (atau pengguna memang tamu).
  siap,

  /// Sesi terputus di tengah jalan dan sisa pembersihannya baru dituntaskan.
  dipulihkan,
}

/// Controller untuk mengelola autentikasi berbasis OTP WhatsApp dan sesi pengguna
/// dengan token aman di FlutterSecureStorage (Hardware Keystore).
class AuthController extends ChangeNotifier {
  final AuthRepository? repository;
  final SecureStorageService? secureStorage;

  /// Cache pesanan lokal. Dipakai untuk memastikan riwayat satu akun tidak
  /// terbawa ke akun lain: dibersihkan saat logout dan saat akun berganti.
  final BookingRepository? bookingRepository;

  /// Pengaturan ringan yang menyimpan jejak aktivitas pengguna.
  ///
  /// Opsional supaya pengujian bisa membuat controller tanpa SharedPreferences;
  /// bila tidak ada, langkah pembersihannya cukup dilewati.
  final AppSettingsService? settingsService;

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
  NiatOtp _activeOtpIntent = NiatOtp.login;

  /// Status pemulihan sesi saat aplikasi dibuka.
  StatusBootSesi _bootState = StatusBootSesi.memuat;

  /// Sedang menjalankan proses keluar akun.
  ///
  /// Menahan ketukan ganda pada tombol keluar. Sebelumnya dua ketukan beruntun
  /// menjalankan dua rangkaian pembersihan sekaligus, dan yang kedua bisa
  /// menghapus token milik sesi baru bila pengguna sempat masuk kembali.
  bool _isLoggingOut = false;

  AuthController({
    this.repository,
    this.secureStorage,
    this.bookingRepository,
    this.settingsService,
  });

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String get phoneNumber => _phoneNumber;
  String get inputOtp => _inputOtp;
  bool get hasLoginError => _hasLoginError;
  String? get errorMessage => _errorMessage;
  Map<String, String>? get pendingRegistration => _pendingRegistration;
  NiatOtp get activeOtpIntent => _activeOtpIntent;
  bool get hasSecureToken => _hasSecureToken;
  bool get isMenyimpanProfil => _isMenyimpanProfil;
  bool get isLoadingOtp => _isLoadingOtp;
  StatusBootSesi get bootState => _bootState;
  bool get isLoggingOut => _isLoggingOut;

  /// Memulihkan sesi pengguna dari Secure Storage saat aplikasi pertama kali dibuka (Guest Mode jika belum login)
  Future<void> initSession() async {
    final storage = secureStorage;
    final repo = repository;

    /* Jurnal pembersihan diperiksa paling awal. Bila penandanya masih ada,
       proses keluar akun sebelumnya terputus di tengah jalan — aplikasi ditutup
       paksa oleh penghemat daya, misalnya — sehingga sebagian lapisan lokal
       masih memuat data pemilik lama. Sisa pembersihan dituntaskan lebih dulu
       sebelum sesi apa pun dipulihkan, supaya akun berikutnya tidak mewarisi
       jejak akun sebelumnya. */
    if (storage != null) {
      try {
        if (await storage.isWipePending()) {
          await _pulihkanPembersihanTerputus();
          _bootState = StatusBootSesi.dipulihkan;
          notifyListeners();
          return;
        }
      } catch (_) {
        // Secure storage tidak terbaca. Pemulihan sesi tetap dilanjutkan; bila
        // token memang tidak terbaca, pengguna berakhir sebagai tamu.
      }
    }

    try {
      if (storage != null) {
        final hasToken = await storage.hasValidToken();
        _hasSecureToken = hasToken;

        if (hasToken && repo != null) {
          /* Saat perangkat sedang offline, sesi dipulihkan dari salinan
             identitas lokal. Dulu galat jaringan merambat keluar dari sini dan
             blok finally hanya menyelesaikan status boot, sehingga `_isLoggedIn`
             tetap false: pengguna dengan token sah terjebak sebagai tamu dan
             tidak bisa membaca riwayat pesanannya sendiri sampai jaringan
             kembali. Sesi tetap dibuang hanya ketika server benar-benar menolak
             tokennya (401/403), yang ditangani `restoreSession()` dengan
             mengembalikan null. */
          final restoredUser = await repo.restoreSession(izinkanModeOffline: true);
          if (restoredUser != null) {
            _currentUser = restoredUser;
            _profilUpdatedAt = restoredUser.updatedAt;
            _isLoggedIn = true;
            return;
          }
        }
      }

      // Default Guest Mode: pengguna belum login
      _currentUser = null;
      _isLoggedIn = false;
      _hasSecureToken = false;
    } finally {
      /* Status boot selalu diselesaikan, termasuk saat pemulihan gagal. Layar
         splash menunggu nilai ini; tanpa blok finally, satu kegagalan membuat
         aplikasi berhenti di layar pembuka selamanya. */
      _bootState = StatusBootSesi.siap;
      notifyListeners();
    }
  }

  /// Menandai sesi masuk tanpa memulihkan dari server.
  ///
  /// Dipakai pengujian widget yang perlu memeriksa perilaku layar saat pengguna
  /// benar-benar masuk, tanpa jaringan maupun secure storage sungguhan. Polanya
  /// sama dengan `setBookingsForTesting` pada `BookingController` dan
  /// `setActiveUserForTest` pada `BookingRepository`.
  @visibleForTesting
  void setSessionForTest({
    required UserModel? user,
    bool hasToken = true,
  }) {
    _currentUser = user;
    _isLoggedIn = user != null;
    _hasSecureToken = user != null && hasToken;
    _bootState = StatusBootSesi.siap;
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
    _activeOtpIntent = NiatOtp.register;
    _phoneNumber = phone;
    _hasLoginError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Membersihkan sisa state pendaftaran tertunda saat pengguna beralih ke alur login.
  void clearPendingRegistration() {
    _pendingRegistration = null;
    _activeOtpIntent = NiatOtp.login;
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

    if (niat == NiatOtp.login) {
      _pendingRegistration = null;
      _activeOtpIntent = NiatOtp.login;
    } else if (niat == NiatOtp.register) {
      _activeOtpIntent = NiatOtp.register;
    }
    notifyListeners();

    final niatEfektif = niat ?? _activeOtpIntent;

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
        _profilUpdatedAt = user.updatedAt;
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
    if (_activeOtpIntent == NiatOtp.register && _pendingRegistration != null) {
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
        _profilUpdatedAt = user.updatedAt;
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

  /// Keluar dari sesi akun dan membersihkan seluruh lapisan data lokal.
  ///
  /// Urutannya disengaja: token di secure storage dihapus **paling akhir**.
  /// Selama token masih ada, aplikasi belum dianggap keluar; bila proses
  /// terhenti di tengah jalan, jurnal [SecureStorageService.markWipePending]
  /// yang membuat pembersihan dilanjutkan saat aplikasi dibuka kembali.
  ///
  /// Setiap langkah dibungkus try/catch sendiri. Sebelumnya satu kegagalan
  /// menghentikan seluruh rangkaian: token sudah hilang tetapi cache pesanan
  /// dan berkas unduhan tetap tertinggal, dan pengguna tidak pernah menerima
  /// pemberitahuan karena `notifyListeners()` ada di baris terakhir.
  Future<void> logout() async {
    // Ketukan ganda tidak boleh menjalankan dua rangkaian pembersihan sekaligus.
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    /* Penanda ditulis sebelum langkah destruktif pertama. Bila aplikasi mati
       di antara baris ini dan penghapusan penanda, pembukaan berikutnya tahu
       bahwa pembersihan belum tuntas. */
    final storage = secureStorage;
    try {
      await storage?.markWipePending();
    } catch (_) {
      // Jurnal gagal ditulis (secure storage bermasalah). Pembersihan tetap
      // dijalankan; risikonya hanya hilangnya jaminan pemulihan otomatis.
    }

    try {
      /* Status sesi di memori dibuang lebih dulu supaya seluruh layar langsung
         berhenti menampilkan data pemilik lama, walau pembersihan cakram masih
         berjalan. */
      _isLoggedIn = false;
      _hasSecureToken = false;
      _currentUser = null;
      _phoneNumber = '';
      _inputOtp = '';
      _hasLoginError = false;
      _errorMessage = null;
      _profilUpdatedAt = null;
      _pendingRegistration = null;
      _activeOtpIntent = NiatOtp.login;
      _isMenyimpanProfil = false;
      _isLoadingOtp = false;

      // Setiap langkah berdiri sendiri: kegagalan satu lapisan tidak boleh
      // membatalkan lapisan lain.
      await _langkahPembersihanBersama();
      await _langkahPembersihanSesi();
    } finally {
      try {
        await storage?.clearWipePending();
      } catch (_) {
        // Bila penanda gagal dihapus, pembukaan berikutnya hanya menjalankan
        // pembersihan sekali lagi. Itu tidak berbahaya karena semua langkah
        // bersifat idempoten.
      }

      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Pembersihan yang tidak bergantung pada isi cache per akun.
  ///
  /// Dijalankan juga oleh [_pulihkanPembersihanTerputus], karena pembersihan
  /// yang terputus bisa terjadi sebelum maupun sesudah langkah-langkah ini.
  Future<void> _langkahPembersihanBersama() async {
    // Menghentikan notifikasi pesanan yang masih terpasang di baki notifikasi.
    try {
      await NotificationService().cancelAll();
    } catch (_) {
      // Plugin notifikasi tidak tersedia atau gagal: bukan alasan membatalkan
      // pembersihan data yang jauh lebih sensitif.
    }

    // Membuang cache nama lokasi dan permintaan geocoding yang tertunda.
    try {
      MeraukeGeocodingService.resetForLogout();
    } catch (_) {
      // Cache statis; kegagalan di sini tidak berdampak pada data pengguna.
    }

    // Menghapus berkas unduhan (tanda terima, surat pernyataan, salinan
    // dokumen identitas) beserta cache gambar yang sudah ter-decode.
    try {
      await BerkasUnduhan.wipeAll();
    } catch (_) {
      // Berkas sementara akan tertimpa pada unduhan berikutnya.
    }
  }

  /// Pembersihan data yang melekat pada akun yang sedang keluar.
  Future<void> _langkahPembersihanSesi() async {
    // Jejak aktivitas pengguna di SharedPreferences.
    try {
      await settingsService?.clearAllForLogout();
    } catch (_) {
      // Preferensi tidak terbaca: lanjut ke lapisan berikutnya.
    }

    /* Cache pesanan lokal. Server tetap sumber kebenaran; cache hanya salinan
       untuk pemakaian offline, jadi seluruh isinya dibuang saat keluar akun.
       Penghapusan dibatasi pada baris milik akun yang keluar: tabel yang sama
       dipakai bersama tamu dan akun lain di perangkat ini, dan dulu seluruh
       tabel dikosongkan sehingga riwayat akun lain ikut lenyap. */
    final bookingRepo = bookingRepository;
    if (bookingRepo != null) {
      try {
        await bookingRepo.wipeOwnedRows(await bookingRepo.refreshSession());
      } catch (_) {
        // Cache pesanan gagal dihapus. Token dihapus pada langkah terakhir,
        // sehingga jurnal pembersihan yang memastikan percobaan ulang.
      }
    }

    /* Token dihapus paling akhir. Sampai baris ini, aplikasi masih memegang
       bukti sesi; setelahnya tidak ada lagi data akun yang tersisa.

       Penghapusan dilakukan langsung lewat secure storage, bukan melalui
       `AuthRepository.logout()`. Keduanya menghapus kunci yang sama, sehingga
       memanggil keduanya berarti tujuh operasi platform dijalankan dua kali
       untuk hasil yang identik. */
    final storage = secureStorage;
    if (storage != null) {
      try {
        await storage.clearAuth();
      } catch (_) {
        // Secure storage menolak dihapus (jarang terjadi; biasanya platform
        // channel belum siap). Jurnal pembersihan masih terpasang sehingga
        // percobaan diulang saat aplikasi dibuka kembali.
      }
    } else {
      // Tanpa secure storage (mis. controller uji tanpa dependensi), repositori
      // tetap diminta membersihkan sesi bila tersedia.
      try {
        await repository?.logout();
      } catch (_) {
        // Tidak ada lagi jaring pengaman di bawah ini; kegagalan diabaikan
        // karena tidak ada token yang bisa dihapus.
      }
    }

    /* Pemilik cache di memori disegarkan setelah token hilang.
       Tanpa langkah ini, `BookingRepository._userId` tetap menyimpan id akun
       yang baru keluar sampai ada login berikutnya; nilai itu dipakai menyaring
       baris dan menjadi dasar pemeriksaan kepemilikan notifikasi. */
    if (bookingRepo != null) {
      try {
        await bookingRepo.refreshSession();
      } catch (_) {
        // Pemilik cache tidak terbaca: tidak ada yang bisa disaring lagi.
      }
    }
  }

  /// Menuntaskan pembersihan sesi yang terputus sebelum aplikasi ditutup.
  ///
  /// Dipanggil dari [initSession] ketika jurnal `sec_wipe_pending` masih ada.
  /// Seluruh langkah idempoten: menjalankannya pada sisa pembersihan yang
  /// sebagian sudah selesai tidak menimbulkan efek samping.
  Future<void> _pulihkanPembersihanTerputus() async {
    /* Status di memori disamakan lebih dulu: apa pun yang tersisa di cakram,
       pengguna saat ini belum tentu pemilik data itu. */
    _isLoggedIn = false;
    _hasSecureToken = false;
    _currentUser = null;
    _phoneNumber = '';
    _inputOtp = '';
    _hasLoginError = false;
    _errorMessage = null;
    _profilUpdatedAt = null;
    _pendingRegistration = null;
    _activeOtpIntent = NiatOtp.login;

    await _langkahPembersihanBersama();
    await _langkahPembersihanSesi();

    try {
      await secureStorage?.clearWipePending();
    } catch (_) {
      // Penanda tetap ada; pembersihan akan diulang pada pembukaan berikutnya.
    }
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
      _profilUpdatedAt = diperbarui.updatedAt;
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
        _profilUpdatedAt = user.updatedAt;
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
