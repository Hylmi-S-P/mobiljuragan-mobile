import 'vehicle_model.dart';

/// Status siklus tahapan pesanan rental (Sesuai alur Figma Frame 07 + Tahap Menunggu Pembayaran)
enum BookingStatus {
  permintaanDiterima, // Tahap 1 Figma: Permintaan diterima
  pemeriksaanArmada, // Tahap 2 Figma: Pemeriksaan armada (jadwal & unit terkonfirmasi)
  menungguTarifFinal, // Tahap 3 Figma: Konfirmasi tarif final (sedang dihitung admin)
  menungguPembayaran, // Tahap Tambahan: Menunggu Pembayaran (tarif final terbit + no rekening BRI)
  pembayaranSelesai, // Pembayaran sewa tervalidasi
  verifikasiKantor, // Verifikasi dokumen fisik KTP & SIM A di kantor saat serah terima
  mobilSiapDigunakan, // Tahap 4 Figma: Mobil siap digunakan (kunci diserahkan di lokasi)
  selesai, // Riwayat sewa selesai & unit kembali
  dibatalkan, // Dibatalkan oleh pelanggan atau sistem
}

/// Model item penyesuaian biaya / surcharge / deposit / diskon yang diinput dinamis oleh admin dari dashboard website
class BookingFeeAdjustment {
  final String title;
  final int amount; // Nilai rupiah (+ untuk surcharge/deposit, - untuk potongan)
  final String? note; // Keterangan opsional misal "Refundable", "Promo perdana"

  const BookingFeeAdjustment({
    required this.title,
    required this.amount,
    this.note,
  });

  bool get isDeduction => amount < 0;
}

/// Entitas data pemesanan rental mobil pelanggan
class BookingModel {
  final String id;
  final VehicleModel vehicle;
  final DateTime startDate;
  final String startTime;
  final int durationDays;
  final bool withDriver;
  final String pickupLocation;
  final String? note;
  final BookingStatus status;
  final DateTime createdAt;
  final int dailyRate;
  final int serviceFee;
  final String paymentBank;
  final String paymentAccountNumber;
  final List<BookingFeeAdjustment> adminAdjustments;
  final bool isFinalTariffConfirmed;

  const BookingModel({
    required this.id,
    required this.vehicle,
    required this.startDate,
    required this.startTime,
    required this.durationDays,
    required this.withDriver,
    required this.pickupLocation,
    this.note,
    required this.status,
    required this.createdAt,
    required this.dailyRate,
    this.serviceFee = 25000,
    this.paymentBank = 'Bank BRI Merauke',
    this.paymentAccountNumber = '0087-01-002345-53-1',
    this.adminAdjustments = const [],
    this.isFinalTariffConfirmed = false,
  });

  /// Tanggal selesai masa sewa
  DateTime get endDate => startDate.add(Duration(days: durationDays));

  /// Subtotal sewa unit mobil
  int get vehicleSubtotal => dailyRate * durationDays;

  /// Subtotal biaya jasa pengemudi di Merauke
  int get driverSubtotal => withDriver ? (150000 * durationDays) : 0;

  /// Label moda sewa
  String get modeLabel => withDriver ? 'Dengan Sopir' : 'Lepas Kunci';

  /// Estimasi biaya dasar sebelum penyesuaian/surcharge admin
  int get baseEstimatedCost => vehicleSubtotal + driverSubtotal + serviceFee;

  /// Total akumulasi penyesuaian biaya dari admin dashboard
  int get adjustmentsTotal =>
      adminAdjustments.fold(0, (sum, item) => sum + item.amount);

  /// Total tarif resmi: jika tarif final sudah dikonfirmasi admin, menggunakan total + penyesuaian; jika belum, menggunakan estimasi dasar
  int get totalCost =>
      isFinalTariffConfirmed ? (baseEstimatedCost + adjustmentsTotal) : baseEstimatedCost;

  /// Label tampilan status pesanan
  String get statusLabel {
    switch (status) {
      case BookingStatus.permintaanDiterima:
        return 'Permintaan Diterima';
      case BookingStatus.pemeriksaanArmada:
        return 'Pemeriksaan Armada';
      case BookingStatus.menungguTarifFinal:
        return 'Hitung Tarif Final';
      case BookingStatus.menungguPembayaran:
        return 'Menunggu Pembayaran';
      case BookingStatus.pembayaranSelesai:
        return 'Pembayaran Selesai';
      case BookingStatus.verifikasiKantor:
        return 'Verifikasi Fisik Kantor';
      case BookingStatus.mobilSiapDigunakan:
        return 'Mobil Siap Digunakan';
      case BookingStatus.selesai:
        return 'Selesai';
      case BookingStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  /// Keterangan ringkas posisi pesanan saat ini
  String get statusDescription {
    switch (status) {
      case BookingStatus.permintaanDiterima:
        return 'Pengajuan Anda telah masuk ke sistem operasional MobilJuragan Merauke.';
      case BookingStatus.pemeriksaanArmada:
        return 'Armada unit mobil siap dan jadwal penggunaan telah terkonfirmasi.';
      case BookingStatus.menungguTarifFinal:
        return 'Admin operasional sedang meninjau rute dan menghitung rincian tarif resmi (surcharge/diskon).';
      case BookingStatus.menungguPembayaran:
        return 'Rincian tarif resmi final telah diterbitkan. Silakan lakukan pembayaran ke Bank BRI Merauke.';
      case BookingStatus.pembayaranSelesai:
        return 'Pembayaran sewa telah tervalidasi. Jadwal dan unit telah dikunci sistem.';
      case BookingStatus.verifikasiKantor:
        return 'Verifikasi fisik KTP asli dan SIM A dilakukan langsung oleh staf kantor saat serah terima unit.';
      case BookingStatus.mobilSiapDigunakan:
        return 'Armada telah diserahterimakan dan kunci diserahkan di lokasi penjemputan.';
      case BookingStatus.selesai:
        return 'Masa sewa telah selesai dan unit telah dikembalikan ke garasi dengan baik.';
      case BookingStatus.dibatalkan:
        return 'Pengajuan sewa ini telah dibatalkan.';
    }
  }

  BookingModel copyWith({
    String? id,
    VehicleModel? vehicle,
    DateTime? startDate,
    String? startTime,
    int? durationDays,
    bool? withDriver,
    String? pickupLocation,
    String? note,
    BookingStatus? status,
    DateTime? createdAt,
    int? dailyRate,
    int? serviceFee,
    String? paymentBank,
    String? paymentAccountNumber,
    List<BookingFeeAdjustment>? adminAdjustments,
    bool? isFinalTariffConfirmed,
  }) {
    return BookingModel(
      id: id ?? this.id,
      vehicle: vehicle ?? this.vehicle,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      durationDays: durationDays ?? this.durationDays,
      withDriver: withDriver ?? this.withDriver,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dailyRate: dailyRate ?? this.dailyRate,
      serviceFee: serviceFee ?? this.serviceFee,
      paymentBank: paymentBank ?? this.paymentBank,
      paymentAccountNumber: paymentAccountNumber ?? this.paymentAccountNumber,
      adminAdjustments: adminAdjustments ?? this.adminAdjustments,
      isFinalTariffConfirmed:
          isFinalTariffConfirmed ?? this.isFinalTariffConfirmed,
    );
  }

  /// Contoh rincian penyesuaian biaya standar dari dashboard admin website
  static const List<BookingFeeAdjustment> standardAdminAdjustments = [
    BookingFeeAdjustment(
      title: 'Layanan Luar Jam Operasional',
      amount: 50000,
      note: 'Penjemputan di luar jadwal operasional kantor',
    ),
    BookingFeeAdjustment(
      title: 'Deposit Jaminan (Refundable)',
      amount: 500000,
      note: 'Akan dikembalikan utuh setelah unit selesai sewa',
    ),
    BookingFeeAdjustment(
      title: 'Diskon Promo Pengguna Baru',
      amount: -50000,
      note: 'Potongan sewa perdana pelanggan Merauke',
    ),
  ];

  /// Data dummy riwayat pesanan awal untuk keperluan pengujian dan demonstrasi
  static List<BookingModel> get initialSampleBookings {
    final sampleVehicle = VehicleModel.sampleVehicles.first;
    final secondVehicle = VehicleModel.sampleVehicles.length > 1
        ? VehicleModel.sampleVehicles[1]
        : sampleVehicle;

    return [
      BookingModel(
        id: 'MBJ-2026-0042',
        vehicle: sampleVehicle,
        startDate: DateTime.now().add(const Duration(days: 1)),
        startTime: '09.00 WIT',
        durationDays: 2,
        withDriver: false,
        pickupLocation: 'Bandara Mopah Merauke',
        note: 'Antar langsung ke lobi kedatangan Bandara Mopah Merauke',
        status: BookingStatus.menungguTarifFinal,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        dailyRate: sampleVehicle.pricePerDay,
        adminAdjustments: const [],
        isFinalTariffConfirmed: false,
      ),
      BookingModel(
        id: 'MBJ-2026-0038',
        vehicle: secondVehicle,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        startTime: '10.00 WIT',
        durationDays: 3,
        withDriver: true,
        pickupLocation: 'Hotel Swiss-Belhotel Merauke',
        status: BookingStatus.selesai,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        dailyRate: secondVehicle.pricePerDay,
        adminAdjustments: standardAdminAdjustments,
        isFinalTariffConfirmed: true,
      ),
    ];
  }
}
