import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/user_model.dart';
import '../local/secure/secure_storage_service.dart';
import '../remote/auth_api_service.dart';

/// Repository autentikasi & sesi pengguna.
///
/// Satu aturan yang dijaga di seluruh berkas ini: **identitas hanya berasal dari
/// server**. Tidak ada id karangan, tidak ada token buatan sendiri, dan sesi yang
/// dipulihkan dari perangkat selalu diperiksa ulang ke backend.
class AuthRepository {
  final AuthApiService _apiService;
  final SecureStorageService _secureStorage;

  AuthRepository({
    AuthApiService? apiService,
    SecureStorageService? secureStorage,
  })  : _apiService = apiService ?? AuthApiService(),
        _secureStorage = secureStorage ?? SecureStorageService();

  /// Meminta kode verifikasi. Nama tidak ikut dikirim (lihat [AuthApiService]).
  Future<Map<String, dynamic>> requestOtp({
    required String phoneNumber,
    required NiatOtp niat,
  }) {
    return _apiService.requestOtp(phoneNumber: phoneNumber, niat: niat);
  }

  /// Masuk memakai kode verifikasi.
  Future<UserModel?> verifyLoginOtpAndSave({
    required String phoneNumber,
    required String otp,
    String? gender,
    String? idCardNumber,
  }) async {
    final res = await _apiService.verifyLoginOtp(phoneNumber: phoneNumber, otp: otp);
    return _simpanSesi(
      res,
      phoneNumber: phoneNumber,
      gender: gender,
      idCardNumber: idCardNumber,
    );
  }

  /// Menyelesaikan pendaftaran lalu menyimpan sesi.
  ///
  /// Server memverifikasi kode lebih dulu; akun baru lahir di permintaan ini.
  Future<UserModel?> daftarDanSimpan({
    required String phoneNumber,
    required String otp,
    required String fullName,
    required String password,
    String? gender,
    String? idCardNumber,
  }) async {
    final res = await _apiService.verifyRegisterOtp(
      phoneNumber: phoneNumber,
      otp: otp,
      fullName: fullName,
      password: password,
    );
    return _simpanSesi(
      res,
      phoneNumber: phoneNumber,
      gender: gender,
      idCardNumber: idCardNumber,
    );
  }

  /// Menyimpan token + identitas dari respons server yang sudah tervalidasi.
  Future<UserModel?> _simpanSesi(
    Map<String, dynamic> res, {
    required String phoneNumber,
    String? gender,
    String? idCardNumber,
  }) async {
    final token = res['token']?.toString();
    final userData = res['user'] as Map<String, dynamic>?;

    /* Tanpa token atau tanpa id, sesi tidak boleh dibentuk sama sekali.
     * Sebelumnya nilai karangan dipakai di sini, dan hasilnya adalah akun yang
     * tampil di aplikasi tetapi tidak ada di database. */
    final userId = userData?['id']?.toString();
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }

    await _secureStorage.saveAuthTokens(accessToken: token);

    final name = userData?['fullName']?.toString() ?? 'Pelanggan MobilJuragan';
    final serverPhone = userData?['phoneNumber']?.toString().trim();
    final canonicalPhone = AuthApiService.sanitizePhoneNumber(
      (serverPhone != null && serverPhone.isNotEmpty) ? serverPhone : phoneNumber,
    );
    final userGender = gender ?? 'Laki-laki';

    await _secureStorage.saveUserIdentity(
      userId: userId,
      nik: idCardNumber,
      phoneNumber: canonicalPhone,
      fullName: name,
      gender: userGender,
    );

    return UserModel(
      id: userId,
      name: name,
      phoneNumber: canonicalPhone,
      gender: userGender,
      idCardNumber: idCardNumber ?? '',
      city: 'Merauke, Papua Selatan',
      avatarInitials: UserModel.computeInitials(name),
      isVerified: true,
      phoneVerifiedAt: _tanggal(userData?['phoneVerifiedAt']),
      passwordUpdatedAt: _tanggal(userData?['passwordUpdatedAt']),
    );
  }

  /// Masuk memakai kata sandi lalu menyimpan sesi.
  Future<UserModel?> loginKataSandi({
    required String phoneNumber,
    required String password,
    String? gender,
    String? idCardNumber,
  }) async {
    final res = await _apiService.loginWithPassword(
      phoneNumber: phoneNumber,
      password: password,
    );
    return _simpanSesi(
      res,
      phoneNumber: phoneNumber,
      gender: gender,
      idCardNumber: idCardNumber,
    );
  }

  /// Meminta kode pemulihan kata sandi.
  Future<Map<String, dynamic>> mintaResetKataSandi(String phoneNumber) {
    return _apiService.requestPasswordReset(phoneNumber: phoneNumber);
  }

  /// Menetapkan kata sandi baru lewat kode pemulihan, lalu menyimpan sesi baru.
  Future<UserModel?> resetKataSandi({
    required String phoneNumber,
    required String otp,
    required String password,
  }) async {
    final res = await _apiService.verifyPasswordReset(
      phoneNumber: phoneNumber,
      otp: otp,
      password: password,
    );
    return _simpanSesi(res, phoneNumber: phoneNumber);
  }

  /// Mengubah nama lewat `PATCH /me`.
  ///
  /// Nama di perangkat **hanya** diperbarui setelah server menerima perubahan.
  /// Sebelumnya nama disimpan lokal saja, sehingga server dan aplikasi bisa
  /// menampilkan nama berbeda tanpa ada yang tahu mana yang benar.
  Future<UserModel> ubahNama({
    required UserModel pengguna,
    required String namaBaru,
    String? expectedUpdatedAt,
  }) async {
    final res = await _apiService.ubahNama(
      fullName: namaBaru,
      expectedUpdatedAt: expectedUpdatedAt,
    );

    final data = res['user'] as Map<String, dynamic>?;
    final namaServer = data?['fullName']?.toString() ?? namaBaru.trim();

    final diperbarui = UserModel(
      id: pengguna.id,
      name: namaServer,
      phoneNumber: pengguna.phoneNumber,
      gender: pengguna.gender,
      email: pengguna.email,
      idCardNumber: pengguna.idCardNumber,
      city: pengguna.city,
      avatarInitials: UserModel.computeInitials(namaServer),
      isVerified: pengguna.isVerified,
      phoneVerifiedAt: pengguna.phoneVerifiedAt,
      passwordUpdatedAt: pengguna.passwordUpdatedAt,
      updatedAt: data?['updatedAt']?.toString() ?? pengguna.updatedAt,
    );

    await _secureStorage.saveUserIdentity(
      userId: diperbarui.id,
      nik: diperbarui.idCardNumber,
      phoneNumber: diperbarui.phoneNumber,
      fullName: diperbarui.name,
      gender: diperbarui.gender,
    );

    return diperbarui;
  }

  /// Membuat atau mengganti kata sandi. Token baru dari server langsung disimpan,
  /// karena mengganti kata sandi mencabut semua token lama termasuk milik sesi ini.
  Future<void> ubahKataSandi({
    required String kataSandiBaru,
    String? kataSandiSaatIni,
  }) async {
    final res = await _apiService.ubahKataSandi(
      newPassword: kataSandiBaru,
      currentPassword: kataSandiSaatIni,
    );

    final token = res['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await _secureStorage.saveAuthTokens(accessToken: token);
    }
  }

  /// Mengeluarkan semua perangkat, lalu membersihkan sesi di perangkat ini.
  Future<void> logoutSemuaPerangkat() async {
    await _apiService.logoutSemuaPerangkat();
    await _secureStorage.clearAuth();
  }

  /// Jejak perubahan identitas milik sendiri.
  Future<List<dynamic>> riwayatIdentitas() => _apiService.riwayatIdentitas();

  /// Memeriksa apakah ada sesi aktif di SecureStorage.
  Future<bool> hasActiveSession() async {
    return _secureStorage.hasValidToken();
  }

  /// Mencabut token di server lebih dulu, lalu menghapus sesi lokal.
  ///
  /// Sebelum ini logout hanya menghapus tujuh key di perangkat tanpa memberi tahu
  /// server, sehingga token akses tetap sah sampai kedaluwarsa. Dampaknya paling
  /// berbahaya pada perangkat bekas: token yang tidak dicabut masih bisa dipakai
  /// memulihkan sesi. Endpoint yang tersedia di backend hanya
  /// `POST /me/logout-all`, jadi pencabutan ini memang mengeluarkan seluruh
  /// perangkat pengguna.
  ///
  /// Pencabutan dibatasi tiga detik dan kegagalannya diabaikan: logout lokal tidak
  /// boleh gagal hanya karena jaringan sedang putus. Sesudah itu `clearAuth()`
  /// tetap berjalan seperti biasa.
  Future<void> logout() async {
    await cabutTokenDiServer();
    await _secureStorage.clearAuth();
  }

  /// Meminta server mencabut token sesi ini.
  ///
  /// Mengembalikan `true` bila server menjawab, `false` bila permintaan gagal
  /// atau melewati batas waktu. Kegagalan sengaja tidak dilempar ke pemanggil.
  Future<bool> cabutTokenDiServer({
    Duration batasWaktu = const Duration(seconds: 3),
  }) async {
    try {
      await _apiService.logoutSemuaPerangkat().timeout(batasWaktu);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Memulihkan sesi pengguna saat aplikasi dibuka.
  ///
  /// Token yang tersimpan di perangkat **diperiksa ke server**. Kalau server
  /// menolaknya (kedaluwarsa, akun dihapus, atau token tidak pernah diterbitkan
  /// server), sesi dibuang dan pengguna kembali sebagai tamu. Nama diambil dari
  /// server, bukan dari salinan lokal, supaya perubahan di server ikut terlihat.
  ///
  /// [izinkanModeOffline] dipakai saat server tidak terjangkau: sesi **tidak** dibuang,
  /// melainkan dipulihkan dari identitas yang tersimpan di perangkat. Dulu
  /// kegagalan jaringan merambat keluar sebagai galat sehingga pengguna dengan
  /// token sah terjebak sebagai tamu hanya karena sedang offline; lebih buruk
  /// lagi, `clearAuth()` lama sempat menghapus sesi pada kegagalan apa pun.
  Future<UserModel?> restoreSession({bool izinkanModeOffline = false}) async {
    final hasToken = await _secureStorage.hasValidToken();
    if (!hasToken) return null;

    final Map<String, dynamic>? profil;
    try {
      profil = await _apiService.ambilProfilSaya();
    } on ApiException catch (galat) {
      /* 401/403/404 sudah ditangani `ambilProfilSaya()` dengan mengembalikan
         null; yang sampai ke sini adalah kegagalan jaringan. Untuk kasus itu
         sesi lokal dipertahankan, bukan dihapus. */
      if (galat.statusCode == null && izinkanModeOffline) {
        return _pulihkanIdentitasLokal();
      }
      rethrow;
    } on SocketException {
      if (izinkanModeOffline) return _pulihkanIdentitasLokal();
      rethrow;
    } on TimeoutException {
      if (izinkanModeOffline) return _pulihkanIdentitasLokal();
      rethrow;
    }

    if (profil == null) {
      await _secureStorage.clearAuth();
      return null;
    }

    final userId = profil['id']?.toString();
    final phone = profil['phoneNumber']?.toString();
    if (userId == null || userId.isEmpty || phone == null || phone.isEmpty) {
      await _secureStorage.clearAuth();
      return null;
    }

    final nama = profil['fullName']?.toString();
    final gender = await _secureStorage.getUserGender();
    final nik = await _secureStorage.getUserNik();

    final actualName = (nama != null && nama.isNotEmpty) ? nama : 'Pelanggan MobilJuragan';

    // Segarkan salinan lokal supaya layar yang belum sempat memuat profil tetap benar.
    await _secureStorage.saveUserIdentity(
      userId: userId,
      nik: nik,
      phoneNumber: phone,
      fullName: actualName,
      gender: gender,
    );

    return UserModel(
      id: userId,
      name: actualName,
      phoneNumber: phone,
      gender: gender ?? 'Laki-laki',
      idCardNumber: nik ?? '',
      city: 'Merauke, Papua Selatan',
      avatarInitials: UserModel.computeInitials(actualName),
      isVerified: true,
      phoneVerifiedAt: _tanggal(profil['phoneVerifiedAt']),
      passwordUpdatedAt: _tanggal(profil['passwordUpdatedAt']),
      updatedAt: profil['updatedAt']?.toString(),
    );
  }

  /// Membangun kembali pengguna dari salinan identitas di perangkat.
  ///
  /// Hanya dipakai saat server tidak terjangkau. Token tetap di tempatnya
  /// sehingga begitu jaringan pulih, pemanggilan berikutnya memverifikasi ulang
  /// ke server.
  Future<UserModel?> _pulihkanIdentitasLokal() async {
    final userId = await _secureStorage.getUserId();
    if (userId == null || userId.isEmpty) return null;

    final nama = await _secureStorage.getUserName();
    final phone = await _secureStorage.getUserPhone();
    final gender = await _secureStorage.getUserGender();
    final nik = await _secureStorage.getUserNik();

    final actualName = (nama != null && nama.isNotEmpty)
        ? nama
        : 'Pelanggan MobilJuragan';

    return UserModel(
      id: userId,
      name: actualName,
      phoneNumber: (phone != null && phone.isNotEmpty)
          ? phone
          : (nik ?? ''),
      gender: gender ?? 'Laki-laki',
      idCardNumber: nik ?? '',
      city: 'Merauke, Papua Selatan',
      avatarInitials: UserModel.computeInitials(actualName),
      isVerified: true,
    );
  }

  /// Membaca tanggal ISO dari respons server; null bila kosong/tidak valid.
  static DateTime? _tanggal(Object? nilai) {
    if (nilai == null) return null;
    return DateTime.tryParse(nilai.toString());
  }
}
