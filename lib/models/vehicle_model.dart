import 'package:drift/drift.dart';
import '../data/local/database/app_database.dart';

/// Model data kendaraan untuk katalog dan detail rental MobilJuragan
class VehicleModel {
  final String id;
  final String name;
  final String plateNumber;
  final String category; // MPV, SUV, Pickup
  final String seatCapacity;
  final String transmission;
  final String bodyType;
  final String condition;
  final String availabilityTag;
  final bool isPopular;
  final int pricePerDay;
  final String imageUrl;
  final String? heroImageUrl;
  final String? detailImageUrl;
  final bool isFavorite;
  final int? lastFetched;
  final int? updatedAt;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.category,
    required this.seatCapacity,
    required this.transmission,
    required this.bodyType,
    required this.condition,
    required this.availabilityTag,
    this.isPopular = false,
    required this.pricePerDay,
    required this.imageUrl,
    this.heroImageUrl,
    this.detailImageUrl,
    this.isFavorite = false,
    this.lastFetched,
    this.updatedAt,
  });

  /// Penanda ketersediaan unit untuk reservasi baru
  bool get isAvailable {
    final tag = availabilityTag.toLowerCase();
    if (tag.contains('sedang disewa') || tag.contains('perawatan') || tag.contains('tidak tersedia')) {
      return false;
    }
    return tag.contains('tersedia');
  }

  /// Penanda unit sedang terkunci karena telah dibayar atau digunakan penyewa lain
  bool get isBooked => availabilityTag.toLowerCase().contains('sedang disewa');

  /// Konversi dari entitas tabel Drift (Vehicle) ke domain model VehicleModel
  factory VehicleModel.fromDrift(Vehicle entry) {
    return VehicleModel(
      id: entry.id,
      name: entry.name,
      plateNumber: entry.plateNumber,
      category: entry.category,
      seatCapacity: entry.seatCapacity,
      transmission: entry.transmission,
      bodyType: entry.bodyType,
      condition: entry.condition,
      availabilityTag: entry.availabilityTag,
      isPopular: entry.isPopular,
      pricePerDay: entry.pricePerDay,
      imageUrl: entry.imageUrl,
      heroImageUrl: entry.heroImageUrl,
      detailImageUrl: entry.detailImageUrl,
      isFavorite: entry.isFavorite,
      lastFetched: entry.lastFetched,
      updatedAt: entry.updatedAt,
    );
  }

  /// Konversi ke Drift VehiclesCompanion untuk penulisan ke database SQLite lokal
  VehiclesCompanion toCompanion({int? lastFetchedMillis}) {
    final nowMillis = lastFetchedMillis ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    return VehiclesCompanion(
      id: Value(id),
      name: Value(name),
      plateNumber: Value(plateNumber),
      category: Value(category),
      seatCapacity: Value(seatCapacity),
      transmission: Value(transmission),
      bodyType: Value(bodyType),
      condition: Value(condition),
      availabilityTag: Value(availabilityTag),
      isPopular: Value(isPopular),
      pricePerDay: Value(pricePerDay),
      imageUrl: Value(imageUrl),
      heroImageUrl: Value(heroImageUrl),
      detailImageUrl: Value(detailImageUrl),
      isFavorite: Value(isFavorite),
      lastFetched: Value(nowMillis),
      updatedAt: Value(updatedAt ?? nowMillis),
    );
  }

  /// Konversi dari JSON backend API
  factory VehicleModel.fromJson(Map<String, dynamic> json, {bool isFavorite = false}) {
    final extId = json['externalId']?.toString() ?? json['id']?.toString() ?? '';
    final rawName = json['name']?.toString() ?? 'Armada MobilJuragan';
    final rawCategory = json['category']?.toString() ?? 'MPV';
    final seating = json['seatingCapacity'] != null ? '${json['seatingCapacity']} Penumpang' : '7 Penumpang';
    final trans = json['transmission']?.toString() ?? 'Manual';
    final rawPlate = json['licensePlate']?.toString() ?? 'PA-MKQ';

    // Harga sewa harian dinamis dari API backend, dengan fallback estimasi resmi Merauke
    final apiPrice = json['pricePerDay'] ?? json['dailyPrice'];
    int rate = 400000;
    if (apiPrice != null) {
      rate = (apiPrice is num) ? apiPrice.toInt() : (int.tryParse(apiPrice.toString()) ?? 400000);
    } else {
      final upName = rawName.toUpperCase();
      if (upName.contains('FORTUNER')) {
        rate = 900000;
      } else if (upName.contains('HILUX')) {
        rate = 850000;
      } else if (upName.contains('INNOVA')) {
        rate = 600000;
      } else if (upName.contains('XPANDER')) {
        rate = 550000;
      } else if (upName.contains('RUSH') || upName.contains('TERIOS')) {
        rate = 500000;
      } else if (upName.contains('VELOZ')) {
        rate = 450000;
      } else if (upName.contains('CARRY') || upName.contains('PICKUP') || rawCategory.toUpperCase() == 'COMMERCIAL') {
        rate = 350000;
      }
    }

    // Normalisasi kategori armada
    String normalizedCategory = 'MPV';
    final catUpper = rawCategory.toUpperCase();
    if (catUpper == 'COMMERCIAL') {
      normalizedCategory = 'Commercial';
    } else if (catUpper == 'SUV') {
      normalizedCategory = 'SUV';
    } else if (catUpper == 'PICKUP') {
      normalizedCategory = 'Pickup';
    }

    String bodyType = 'MPV Keluarga';
    if (normalizedCategory == 'SUV') {
      bodyType = 'SUV Tangguh';
    } else if (normalizedCategory == 'Pickup') {
      bodyType = 'D-Cab Ekspedisi';
    } else if (normalizedCategory == 'Commercial') {
      bodyType = 'Pick-up Niaga';
    }

    // Pemetaan gambar aset lokal fallback
    String cardImg = 'assets/images/avanza_card.png';
    String? heroImg = 'assets/images/avanza_hero.png';
    String? detailImg = 'assets/images/avanza_detail.png';

    if (extId.contains('fortuner') || rawName.toUpperCase().contains('FORTUNER')) {
      cardImg = 'assets/images/fortuner_card.png';
      heroImg = null;
      detailImg = 'assets/images/fortuner_card.png';
    } else if (extId.contains('hilux') || rawName.toUpperCase().contains('HILUX')) {
      cardImg = 'assets/images/hilux_card.png';
      heroImg = null;
      detailImg = 'assets/images/hilux_card.png';
    } else if (extId.contains('innova') || rawName.toUpperCase().contains('INNOVA')) {
      cardImg = 'assets/images/innova_card.png';
      heroImg = null;
      detailImg = 'assets/images/innova_card.png';
    } else if (extId.contains('carry') || rawName.toUpperCase().contains('CARRY')) {
      cardImg = 'assets/images/hilux_card.png';
      heroImg = null;
      detailImg = 'assets/images/hilux_card.png';
    }

    // Evaluasi status ketersediaan armada
    final opStatus = json['operationalStatus']?.toString().toUpperCase() ?? 'AVAILABLE';
    final bookingsList = json['bookings'] as List<dynamic>?;
    final bool hasActiveBooking = bookingsList != null && bookingsList.isNotEmpty;

    String calculatedAvailability = 'Tersedia • Lepas Kunci';
    if (opStatus == 'BOOKED' || hasActiveBooking) {
      calculatedAvailability = 'Sedang Disewa';
    } else if (opStatus == 'MAINTENANCE') {
      calculatedAvailability = 'Perawatan';
    } else if (opStatus == 'UNAVAILABLE') {
      calculatedAvailability = 'Tidak Tersedia';
    }

    return VehicleModel(
      id: extId,
      name: rawName,
      plateNumber: rawPlate,
      category: normalizedCategory,
      seatCapacity: seating,
      transmission: trans == 'AUTOMATIC' || trans == 'Matic' ? 'Matic' : 'Manual',
      bodyType: bodyType,
      condition: hasActiveBooking ? 'Sedang Digunakan' : 'Siap Pakai & Terawat',
      availabilityTag: calculatedAvailability,
      isPopular: rawName.toUpperCase().contains('AVANZA'),
      pricePerDay: rate,
      imageUrl: json['imageUrl']?.toString() ?? cardImg,
      heroImageUrl: heroImg,
      detailImageUrl: detailImg,
      isFavorite: isFavorite,
      lastFetched: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  VehicleModel copyWith({
    String? id,
    String? name,
    String? plateNumber,
    String? category,
    String? seatCapacity,
    String? transmission,
    String? bodyType,
    String? condition,
    String? availabilityTag,
    bool? isPopular,
    int? pricePerDay,
    String? imageUrl,
    String? heroImageUrl,
    String? detailImageUrl,
    bool? isFavorite,
    int? lastFetched,
    int? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      category: category ?? this.category,
      seatCapacity: seatCapacity ?? this.seatCapacity,
      transmission: transmission ?? this.transmission,
      bodyType: bodyType ?? this.bodyType,
      condition: condition ?? this.condition,
      availabilityTag: availabilityTag ?? this.availabilityTag,
      isPopular: isPopular ?? this.isPopular,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      imageUrl: imageUrl ?? this.imageUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      detailImageUrl: detailImageUrl ?? this.detailImageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      lastFetched: lastFetched ?? this.lastFetched,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Data 9 armada riil resmi MobilJuragan Merauke untuk seed awal offline
  static const List<VehicleModel> sampleVehicles = [
    VehicleModel(
      id: 'avanza-g-putih-ps1692b',
      name: 'AVANZA G PUTIH',
      plateNumber: 'PS1692B',
      category: 'MPV',
      seatCapacity: '7 Penumpang',
      transmission: 'Manual',
      bodyType: 'MPV Keluarga',
      condition: 'Siap Pakai',
      availabilityTag: 'Tersedia • Lepas Kunci',
      isPopular: true,
      pricePerDay: 400000,
      imageUrl: 'assets/images/avanza_card.png',
      heroImageUrl: 'assets/images/avanza_hero.png',
      detailImageUrl: 'assets/images/avanza_detail.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'veloz-merah-ps1693b',
      name: 'VELOZ MERAH',
      plateNumber: 'PS1693B',
      category: 'MPV',
      seatCapacity: '7 Penumpang',
      transmission: 'Matic',
      bodyType: 'MPV Keluarga',
      condition: 'Siap & Nyaman',
      availabilityTag: 'Tersedia • Lepas Kunci/Supir',
      isPopular: false,
      pricePerDay: 450000,
      imageUrl: 'assets/images/avanza_card.png',
      detailImageUrl: 'assets/images/avanza_detail.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'rush-g-all-new-coklat-pa1696gg',
      name: 'RUSH G ALL NEW COKLAT',
      plateNumber: 'PA1696GG',
      category: 'SUV',
      seatCapacity: '7 Penumpang',
      transmission: 'Manual',
      bodyType: 'SUV Tangguh',
      condition: 'Siap Pakai',
      availabilityTag: 'Tersedia • Lepas Kunci/Supir',
      isPopular: false,
      pricePerDay: 500000,
      imageUrl: 'assets/images/fortuner_card.png',
      detailImageUrl: 'assets/images/fortuner_card.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'terios-x-hijau-matic-b2534krb',
      name: 'TERIOS X HIJAU MATIC',
      plateNumber: 'B2534KRB',
      category: 'SUV',
      seatCapacity: '7 Penumpang',
      transmission: 'Matic',
      bodyType: 'SUV Tangguh',
      condition: 'Siap Pakai',
      availabilityTag: 'Tersedia • Lepas Kunci/Supir',
      isPopular: false,
      pricePerDay: 500000,
      imageUrl: 'assets/images/fortuner_card.png',
      detailImageUrl: 'assets/images/fortuner_card.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'xpander-exceed-hitam-ps1691b',
      name: 'XPANDER EXCEED HITAM',
      plateNumber: 'PS1691B',
      category: 'MPV',
      seatCapacity: '7 Penumpang',
      transmission: 'Manual',
      bodyType: 'MPV Keluarga',
      condition: 'Sedang Beroperasi',
      availabilityTag: 'Sedang Disewa',
      isPopular: false,
      pricePerDay: 550000,
      imageUrl: 'assets/images/innova_card.png',
      detailImageUrl: 'assets/images/innova_card.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'innova-reborn-g-hitam-pa1504g',
      name: 'INNOVA REBORN G HITAM',
      plateNumber: 'PA1504G',
      category: 'MPV',
      seatCapacity: '7 Penumpang',
      transmission: 'Matic',
      bodyType: 'Premium MPV',
      condition: 'Siap & Nyaman',
      availabilityTag: 'Tersedia • Premium MPV',
      isPopular: false,
      pricePerDay: 600000,
      imageUrl: 'assets/images/innova_card.png',
      detailImageUrl: 'assets/images/innova_card.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'hilux-g-hitam-pa8593gz',
      name: 'HILUX G HITAM',
      plateNumber: 'PA8593GZ',
      category: 'Pickup',
      seatCapacity: '5 Penumpang (Double Cabin)',
      transmission: 'Manual',
      bodyType: 'D-Cab Ekspedisi',
      condition: 'Siap & Tangguh Proyek',
      availabilityTag: 'Tersedia • Tangguh Proyek',
      isPopular: false,
      pricePerDay: 850000,
      imageUrl: 'assets/images/hilux_card.png',
      detailImageUrl: 'assets/images/hilux_card.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'fortuner-vrz-trd-hitam-b8833aku',
      name: 'FORTUNER VRZ TRD HITAM',
      plateNumber: 'B8833AKU',
      category: 'SUV',
      seatCapacity: '7 Penumpang',
      transmission: 'Matic',
      bodyType: 'SUV Tangguh',
      condition: 'Siap & AC Dingin',
      availabilityTag: 'Tersedia • Lepas Kunci/Supir',
      isPopular: false,
      pricePerDay: 900000,
      imageUrl: 'assets/images/fortuner_card.png',
      detailImageUrl: 'assets/images/fortuner_card.png',
      isFavorite: false,
    ),
    VehicleModel(
      id: 'pickup-suzuki-carry-hitam-b9762bay',
      name: 'PICKUP SUZUKI CARRY HITAM',
      plateNumber: 'B9762BAY',
      category: 'Commercial',
      seatCapacity: '3 Penumpang',
      transmission: 'Manual',
      bodyType: 'Pick-up Niaga',
      condition: 'Siap Angkut Barang',
      availabilityTag: 'Tersedia • Lepas Kunci',
      isPopular: false,
      pricePerDay: 350000,
      imageUrl: 'assets/images/hilux_card.png',
      detailImageUrl: 'assets/images/hilux_card.png',
      isFavorite: false,
    ),
  ];
}
