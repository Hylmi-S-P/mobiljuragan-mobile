/// Model data profil pengguna MobilJuragan
class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? gender; // 'Laki-laki' | 'Perempuan'
  final String email;
  final String idCardNumber; // NIK KTP (opsional saat lepas kunci)
  final String city;
  final String avatarInitials;
  final bool isVerified;

  /// Kapan nomor telepon terbukti lewat kode verifikasi.
  ///
  /// Null berarti akun lama yang belum pernah masuk ulang setelah verifikasi
  /// nomor diwajibkan.
  final DateTime? phoneVerifiedAt;

  /// Kapan kata sandi terakhir dibuat atau diganti.
  ///
  /// Null berarti akun ini belum punya kata sandi dan hanya bisa masuk lewat
  /// kode OTP.
  final DateTime? passwordUpdatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.gender,
    this.email = '',
    this.idCardNumber = '',
    this.city = 'Merauke, Papua Selatan',
    required this.avatarInitials,
    this.isVerified = true,
    this.phoneVerifiedAt,
    this.passwordUpdatedAt,
  });

  /// Apakah akun ini sudah punya kata sandi.
  bool get punyaKataSandi => passwordUpdatedAt != null;

  /// Alias getter untuk kemudahan akses
  String get phone => phoneNumber;
  String get nik => idCardNumber;

  /// Helper menghitung 1-2 inisial huruf dari nama pengguna asli
  static String computeInitials(String fullName) {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'MJ';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }
}
