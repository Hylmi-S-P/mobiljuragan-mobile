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
  });

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
