/// Model data profil pengguna MobilJuragan
class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String idCardNumber; // NIK KTP
  final String city;
  final String avatarInitials;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.idCardNumber,
    required this.city,
    required this.avatarInitials,
    this.isVerified = true,
  });

  /// Alias getter untuk kemudahan akses
  String get phone => phoneNumber;
  String get nik => idCardNumber;

  /// Data profil default pelanggan (Harun, Merauke)
  static const UserModel defaultUser = UserModel(
    id: 'USR-MKQ-001',
    name: 'Harun',
    phoneNumber: '+62 812-4800-2910',
    email: 'harun.merauke@gmail.com',
    idCardNumber: '9101012304980002',
    city: 'Merauke, Papua Selatan',
    avatarInitials: 'HR',
    isVerified: true,
  );
}
