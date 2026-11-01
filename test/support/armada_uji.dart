import 'package:mobiljuragan_mobile/models/vehicle_model.dart';

/*
 * Armada khusus pengujian.
 *
 * Dulu daftar seperti ini menempel di `lib/models/vehicle_model.dart` sebagai
 * `sampleVehicles`, sehingga ikut terpakai di aplikasi sungguhan: katalog
 * selalu berisi walaupun admin belum menambah unit. Sekarang daftar contoh
 * hanya hidup di folder `test/` dan tidak pernah ikut ke build aplikasi.
 *
 * Nilainya sengaja dibuat berbeda dari armada asli supaya tidak bisa tertukar.
 */
const List<VehicleModel> armadaUji = [
  VehicleModel(
    id: 'uji-avanza',
    name: 'AVANZA UJI',
    plateNumber: 'PS0001U',
    category: 'MPV',
    seatCapacity: '7 Penumpang',
    transmission: 'Manual',
    bodyType: 'MPV Keluarga',
    condition: 'Siap Pakai',
    availabilityTag: 'Tersedia',
    pricePerDay: 400000,
    imageUrl: '',
  ),
  VehicleModel(
    id: 'uji-hilux',
    name: 'HILUX UJI',
    plateNumber: 'PA0002U',
    category: 'PICKUP',
    seatCapacity: '5 Penumpang',
    transmission: 'Manual',
    bodyType: 'D-Cab',
    condition: 'Siap Pakai',
    availabilityTag: 'Tersedia',
    pricePerDay: 850000,
    imageUrl: '',
  ),
];
