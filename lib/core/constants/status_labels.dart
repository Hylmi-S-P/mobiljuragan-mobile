/// Label status armada — satu sumber untuk seluruh layar.
///
/// Sebelumnya status armada ditentukan dengan membandingkan potongan string
/// ("Sedang Disewa"/"Tersedia …") langsung di masing-masing layar.
/// Akibatnya satu unit bisa tampil berbeda antar halaman, dan penambahan status
/// baru (mis. masa pemeriksaan setelah sewa) menuntut perubahan di banyak file.
///
/// Semua pemetaan status -> label sekarang lewat file ini.
enum VehicleAvailability {
  /// Bisa dipesan sekarang.
  tersedia,

  /// Sedang dipakai pesanan aktif.
  disewa,

  /// Masa pemeriksaan/pembersihan setelah sewa selesai (backend: IN_SERVICE).
  pemeriksaan,

  /// Servis berkala atau perbaikan.
  perawatan,

  /// Dinonaktifkan dari pemesanan.
  tidakTersedia,
}

/// Menentukan status dari tag yang tersimpan (termasuk data lama).
///
/// Label lama (ejaan sebelum revisi) tetap dikenali supaya cache lokal dari
/// versi sebelumnya tidak tiba-tiba tampil sebagai "Tersedia".
VehicleAvailability classifyVehicleAvailability(String tag) {
  final value = tag.toLowerCase();

  if (value.contains('pemeriksaan') ||
      value.contains('in service') ||
      value.contains('in-service')) {
    return VehicleAvailability.pemeriksaan;
  }
  if (value.contains('disewa') || value.contains('tersewa')) {
    return VehicleAvailability.disewa;
  }
  if (value.contains('perawatan')) {
    return VehicleAvailability.perawatan;
  }
  if (value.contains('tidak tersedia')) {
    return VehicleAvailability.tidakTersedia;
  }
  return VehicleAvailability.tersedia;
}

/// Label pendek untuk badge/kartu.
///
/// Istilah resmi yang dipakai adalah "Disewa".
String vehicleAvailabilityLabel(VehicleAvailability availability) {
  switch (availability) {
    case VehicleAvailability.tersedia:
      return 'Tersedia';
    case VehicleAvailability.disewa:
      return 'Disewa';
    case VehicleAvailability.pemeriksaan:
      return 'Dalam Pemeriksaan';
    case VehicleAvailability.perawatan:
      return 'Perawatan';
    case VehicleAvailability.tidakTersedia:
      return 'Tidak Tersedia';
  }
}

/// Keterangan kondisi unit untuk kartu detail.
String vehicleConditionLabel(VehicleAvailability availability) {
  switch (availability) {
    case VehicleAvailability.tersedia:
      return 'Siap Pakai & Terawat';
    case VehicleAvailability.disewa:
      return 'Sedang Digunakan';
    case VehicleAvailability.pemeriksaan:
      return 'Dalam Pemeriksaan';
    case VehicleAvailability.perawatan:
      return 'Servis Berkala';
    case VehicleAvailability.tidakTersedia:
      return 'Tidak Tersedia';
  }
}

/// Unit bisa dipesan hanya saat benar-benar tersedia.
bool isVehicleRentable(VehicleAvailability availability) {
  return availability == VehicleAvailability.tersedia;
}