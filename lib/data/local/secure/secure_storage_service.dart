import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Layanan penyimpanan kredensial rahasia & token autentikasi (Hardware Keystore / iOS Keychain)
///
/// PERINGATAN KEAMANAN:
/// Kelas ini khusus mengelola data rahasia (secrets).
/// Dilarang keras memindahkan penyimpanan token atau kredensial ini ke SharedPreferences!
class SecureStorageService {
  final FlutterSecureStorage _storage;

  /* Cache memori berlingkup instance: mengurangi pembacaan Keystore/Keychain
     berulang saat header Authorization dibuat berdekatan, namun tetap
     terisolasi per instance sehingga antar-pengujian tidak saling membocorkan
     token. Seluruh cache dikosongkan seketika di [clearAuth]. */
  String? _cachedAccessToken;
  bool _accessTokenLoaded = false;
  String? _cachedUserId;
  bool _userIdLoaded = false;
  String? _cachedTokenExpiry;
  bool _tokenExpiryLoaded = false;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _keyAccessToken = 'sec_access_token';
  static const String _keyRefreshToken = 'sec_refresh_token';
  static const String _keyUserId = 'sec_user_id';
  static const String _keyUserNik = 'sec_user_nik';
  static const String _keyUserPhone = 'sec_user_phone';
  static const String _keyUserName = 'sec_user_name';
  static const String _keyUserGender = 'sec_user_gender';

  /// Waktu kedaluwarsa token dalam milidetik sejak epoch.
  ///
  /// Diisi saat token disimpan dan dibaca lagi oleh [hasValidToken]. Tanpa
  /// catatan ini, token yang sudah kedaluwarsa tetap dianggap sah sehingga
  /// aplikasi membuka sesi lalu gagal di setiap permintaan.
  static const String _keyTokenExpiry = 'sec_token_expiry';

  /// Sisa waktu minimal agar token masih dianggap layak dipakai.
  ///
  /// Token yang kedaluwarsa kurang dari 30 detik lagi akan ditolak lebih awal
  /// supaya permintaan yang sedang berjalan tidak gagal di tengah jalan.
  static const Duration _marginKedaluwarsa = Duration(seconds: 30);

  /// Jurnal keluar akun yang belum tuntas.
  ///
  /// Ditulis sebelum langkah pembersihan pertama dan baru dihapus setelah
  /// seluruh langkah selesai. Kalau aplikasi ditutup paksa di tengah proses,
  /// penanda ini masih ada saat aplikasi dibuka lagi sehingga sisa pembersihan
  /// bisa dituntaskan sebelum sesi apa pun dipulihkan. Tanpa jurnal ini, token
  /// yang sudah terlanjur dihapus bisa berpasangan dengan cache pesanan yang
  /// masih utuh — persis kondisi yang membuat riwayat pemilik lama muncul lagi.
  static const String _keyWipePending = 'sec_wipe_pending';

  /// Nilai penanda jurnal. Versi disertakan supaya bentuk jurnal bisa berubah
  /// tanpa salah membaca penanda dari versi aplikasi yang lebih lama.
  static const String _wipePendingValue = 'v1';

  /// Menyimpan token autentikasi JWT
  ///
  /// [kedaluwarsa] diisi bila server mengirimkan waktu berakhir token. Nilainya
  /// disimpan terpisah karena tidak semua token memuat klaim `exp` yang bisa
  /// dibaca, dan [hasValidToken] butuh jawaban pasti sebelum membuka sesi.
  ///
  /// Bila pemanggil tidak mengirim [kedaluwarsa], klaim `exp` di dalam token
  /// dicoba dibaca lebih dulu (lihat [kedaluwarsaDariToken]). Backend menerbitkan
  /// token berumur tujuh hari, jadi tanpa langkah ini aplikasi tidak punya
  /// catatan waktu sama sekali dan token basi tetap dianggap sah.
  Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? kedaluwarsa,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    _cachedAccessToken = accessToken;
    _accessTokenLoaded = true;
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    final batas = kedaluwarsa ?? kedaluwarsaDariToken(accessToken);
    if (batas != null) {
      final batasStr = batas.toUtc().millisecondsSinceEpoch.toString();
      await _storage.write(
        key: _keyTokenExpiry,
        value: batasStr,
      );
      _cachedTokenExpiry = batasStr;
      _tokenExpiryLoaded = true;
    } else {
      _cachedTokenExpiry = null;
      _tokenExpiryLoaded = false;
    }
  }

  /// Membaca klaim `exp` dari token JWT tanpa memverifikasi tanda tangannya.
  ///
  /// Verifikasi tetap dilakukan server; di perangkat nilai ini hanya dipakai
  /// untuk menolak token yang jelas sudah lewat masa berlaku, sehingga aplikasi
  /// tidak membuka sesi yang pasti ditolak. Nilai yang tidak bisa dibaca
  /// menghasilkan `null`, dan [hasValidToken] memperlakukannya sebagai token
  /// lama yang masih boleh dicoba ke server.
  static DateTime? kedaluwarsaDariToken(String token) {
    final bagian = token.split('.');
    if (bagian.length < 2) return null;

    try {
      final muatan = utf8.decode(base64Url.decode(base64Url.normalize(bagian[1])));
      final data = jsonDecode(muatan);
      if (data is! Map) return null;

      final nilai = data['exp'];
      if (nilai is int) {
        return DateTime.fromMillisecondsSinceEpoch(nilai * 1000, isUtc: true);
      }
      if (nilai is String) {
        final angka = int.tryParse(nilai);
        if (angka != null) {
          return DateTime.fromMillisecondsSinceEpoch(angka * 1000, isUtc: true);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil access token aktif
  Future<String?> getAccessToken() async {
    if (_accessTokenLoaded) return _cachedAccessToken;
    final value = await _storage.read(key: _keyAccessToken);
    _cachedAccessToken = value;
    _accessTokenLoaded = true;
    return value;
  }

  /// Mengambil refresh token aktif
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Menyimpan data identitas pengguna asli (User ID, No HP, Nama Lengkap, Gender, NIK)
  Future<void> saveUserIdentity({
    required String userId,
    String? nik,
    required String phoneNumber,
    String? fullName,
    String? gender,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    _cachedUserId = userId;
    _userIdLoaded = true;
    if (nik != null && nik.isNotEmpty) {
      await _storage.write(key: _keyUserNik, value: nik);
    }
    await _storage.write(key: _keyUserPhone, value: phoneNumber);
    if (fullName != null && fullName.isNotEmpty) {
      await _storage.write(key: _keyUserName, value: fullName);
    }
    if (gender != null && gender.isNotEmpty) {
      await _storage.write(key: _keyUserGender, value: gender);
    }
  }

  Future<String?> getUserId() async {
    if (_userIdLoaded) return _cachedUserId;
    final value = await _storage.read(key: _keyUserId);
    _cachedUserId = value;
    _userIdLoaded = true;
    return value;
  }
  Future<String?> getUserNik() async => await _storage.read(key: _keyUserNik);
  Future<String?> getUserPhone() async => await _storage.read(key: _keyUserPhone);
  Future<String?> getUserName() async => await _storage.read(key: _keyUserName);
  Future<String?> getUserGender() async => await _storage.read(key: _keyUserGender);

  /// Mengecek apakah terdapat sesi token aktif
  ///
  /// Selain memastikan token tidak kosong, waktu kedaluwarsa yang tercatat ikut
  /// diperiksa. Token yang tersisa kurang dari 30 detik dianggap sudah tidak
  /// layak, sehingga aplikasi tidak membuka sesi yang pasti gagal di server.
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;

    final String? batas;
    if (_tokenExpiryLoaded) {
      batas = _cachedTokenExpiry;
    } else {
      batas = await _storage.read(key: _keyTokenExpiry);
      _cachedTokenExpiry = batas;
      _tokenExpiryLoaded = true;
    }
    if (batas == null || batas.isEmpty) {
      /* Token lama yang disimpan sebelum versi ini tidak punya catatan waktu.
         Server tetap memverifikasinya pada permintaan pertama, jadi token itu
         masih dipakai alih-alih memaksa pengguna masuk ulang. */
      return true;
    }

    final milidetik = int.tryParse(batas);
    if (milidetik == null) return true;

    final kedaluwarsa = DateTime.fromMillisecondsSinceEpoch(milidetik, isUtc: true);
    return DateTime.now().toUtc().add(_marginKedaluwarsa).isBefore(kedaluwarsa);
  }

  /// Menandai bahwa pembersihan sesi sedang berjalan.
  ///
  /// Dipanggil sebelum langkah destruktif pertama. Penanda ini sengaja tidak
  /// ikut dihapus oleh [clearAuth] supaya tetap terbaca saat aplikasi dibuka
  /// kembali setelah ditutup paksa di tengah proses keluar akun.
  Future<void> markWipePending() async {
    await _storage.write(key: _keyWipePending, value: _wipePendingValue);
  }

  /// Membaca apakah ada pembersihan sesi yang belum tuntas.
  Future<bool> isWipePending() async {
    final nilai = await _storage.read(key: _keyWipePending);
    return nilai != null && nilai.isNotEmpty;
  }

  /// Menghapus penanda jurnal setelah seluruh pembersihan selesai.
  Future<void> clearWipePending() async {
    await _storage.delete(key: _keyWipePending);
  }

  /// Menghapus seluruh kredensial rahasia saat keluar (Logout)
  Future<void> clearAuth() async {
    _cachedAccessToken = null;
    _accessTokenLoaded = false;
    _cachedUserId = null;
    _userIdLoaded = false;
    _cachedTokenExpiry = null;
    _tokenExpiryLoaded = false;
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserNik);
    await _storage.delete(key: _keyUserPhone);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserGender);
    await _storage.delete(key: _keyTokenExpiry);
  }
}
