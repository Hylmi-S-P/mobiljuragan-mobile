import 'package:drift/drift.dart';

/// Skema tabel SQLite lokal Drift untuk entitas pemesanan sewa mobil pelanggan
class Bookings extends Table {
  /// Kode pemesanan unik (contoh: 'MKQ-2026-001' atau UUID/bookingCode dari backend)
  TextColumn get id => text()();

  /// ID referensi armada kendaraan
  TextColumn get vehicleId => text()();

  /// Tanggal mulai sewa (UTC epoch milliseconds)
  IntColumn get startDate => integer()();

  /// Waktu jam penjemputan (contoh: '09.00 WIT')
  TextColumn get startTime => text()();

  /// Durasi penyewaan dalam satuan hari
  IntColumn get durationDays => integer()();

  /// Menggunakan supir (true) atau lepas kunci (false)
  BoolColumn get withDriver => boolean().withDefault(const Constant(false))();

  /// Titik lokasi penjemputan di wilayah Merauke
  TextColumn get pickupLocation => text()();

  /// Koordinat lintang penjemputan
  RealColumn get pickupLatitude => real().nullable()();

  /// Koordinat bujur penjemputan
  RealColumn get pickupLongitude => real().nullable()();

  /// Catatan khusus dari pelanggan
  TextColumn get customerNote => text().nullable()();

  /// Status pemesanan (nama enum: permintaanDiterima, pemeriksaanArmada, selesai, dll.)
  TextColumn get status => text()();

  /// Tarif harian unit mobil saat dipesan
  IntColumn get dailyRate => integer()();

  /// Biaya layanan pemesanan
  IntColumn get serviceFee => integer()();

  /// Nama bank tujuan pembayaran
  TextColumn get paymentBank => text()();

  /// Nomor rekening tujuan pembayaran
  TextColumn get paymentAccountNumber => text()();

  /// Apakah tarif final sudah dikonfirmasi admin
  BoolColumn get isFinalTariffConfirmed => boolean().withDefault(const Constant(false))();

  /// Rincian penyesuaian biaya / surcharge dari admin (format JSON array)
  TextColumn get adminAdjustmentsJson => text().nullable()();

  /// Waktu pembuatan pesanan (UTC epoch milliseconds)
  IntColumn get createdAt => integer()();

  /// Atribut penanda cache wajib: Waktu terakhir data di-fetch/di-cache (UTC Milliseconds)
  IntColumn get lastFetched => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
