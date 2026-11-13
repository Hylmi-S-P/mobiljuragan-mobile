import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../core/network/pickup_point_api_service.dart';
import '../data/remote/document_api_service.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/merauke_location_map_picker.dart';
import 'date_time_screen.dart';
import '../theme/app_typography.dart';

/// Layar pemilihan opsi rental (Langkah 2 dari 5)
/// Memungkinkan pemilihan moda Lepas Kunci vs Dengan Sopir dan titik penjemputan/serah terima dengan peta interaktif
class RentalOptionsScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const RentalOptionsScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<RentalOptionsScreen> createState() => _RentalOptionsScreenState();
}

class _RentalOptionsScreenState extends State<RentalOptionsScreen> {
  final DocumentApiService _documentApiService = DocumentApiService();

  /* Titik serah terima sepenuhnya berasal dari backend (GET /pickup-points).
     Tidak ada daftar cadangan berisi koordinat karangan: kalau server belum
     menjawab, layar menampilkan keadaan memuat atau gagal, bukan titik palsu
     yang bisa dipilih pelanggan lalu ditolak kantor. */
  final PickupPointApiService _pickupPointApiService = PickupPointApiService();
  List<PickupPoint> _pickupPoints = const <PickupPoint>[];
  bool _memuatTitik = true;
  String? _galatTitik;

  @override
  void initState() {
    super.initState();
    _loadPickupPoints();
  }

  /// Titik bawaan saat mode sewa berubah.
  ///
  /// Lepas kunci diambil di kantor; dengan sopir dijemput di bandara. Titik
  /// yang dipilih sendiri oleh pelanggan (hotel, alamat bebas, atau hasil
  /// ketukan peta) TIDAK ditimpa — titik jemput adalah keputusan pelanggan,
  /// bukan efek samping pergantian mode. Yang diganti hanya titik bawaan mode
  /// sebelumnya.
  void _pilihTitikBawaan(BookingController booking, {required bool denganSopir}) {
    const bawaanLepasKunci = 'Kantor MobilJuragan';
    const bawaanDenganSopir = 'Bandara Mopah Merauke';
    final sekarang = booking.pickupLocation.trim();
    final masihBawaan =
        sekarang == bawaanLepasKunci || sekarang == bawaanDenganSopir;
    if (!masihBawaan) return;

    final idBawaan = denganSopir ? 'bandara-mopah' : 'kantor-mobiljuragan';
    final cocok = _pickupPoints.where((p) => p.id == idBawaan).toList();
    if (cocok.isEmpty) {
      /* Titik bawaan belum termuat. Titik jemput dibiarkan apa adanya supaya
         pelanggan tidak terkirim ke koordinat yang tidak pernah dipilihnya. */
      return;
    }
    final titik = cocok.first;
    booking.setPickupLocation(titik.label, titik.latitude, titik.longitude);
  }

  /// Membuka peta penuh supaya pelanggan mengetuk sendiri titik jemputnya.
  ///
  /// Dipakai chip "Titik Lain": sebelumnya chip itu menyetel koordinat tetap di
  /// pusat kota dengan nama generik, sehingga titik yang terlihat di peta bukan
  /// titik yang dipilih pelanggan.
  Future<void> _bukaPetaTitikBebas(BookingController booking) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.primaryNavy,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_location_alt_outlined,
                          size: 20, color: AppColors.primaryTeal),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pilih Titik di Peta',
                          style: TextStyle(
                            fontSize: AppTypography.sizeBodyLarge,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, size: 20, color: Colors.white),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: MeraukeLocationMapPicker(
                    selectedLocationName: booking.pickupLocation,
                    selectedCoordinates: (booking.pickupLatitude != null &&
                            booking.pickupLongitude != null)
                        ? LatLng(booking.pickupLatitude!, booking.pickupLongitude!)
                        : null,
                    isWithDriver: true,
                    mapHeight: 320,
                    showCardContainer: false,
                    showFullscreenButton: false,
                    showOverlayBanner: false,
                    onCustomCoordinateSelected: (customName, coords) {
                      booking.setPickupLocation(
                        customName,
                        coords.latitude,
                        coords.longitude,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Pakai Titik Ini',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadPickupPoints() async {
    setState(() {
      _memuatTitik = true;
      _galatTitik = null;
    });
    try {
      final points = await _pickupPointApiService.fetchPickupPoints();
      if (!mounted) return;
      setState(() {
        _pickupPoints = points;
        _memuatTitik = false;
        _galatTitik = points.isEmpty
            ? 'Kantor belum mendaftarkan titik serah terima.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuatTitik = false;
        _galatTitik = 'Titik serah terima gagal dimuat. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  /// Titik serah terima untuk lepas kunci.
  List<Map<String, dynamic>> get _selfDriveLocations => _pickupPoints
      .map((point) => {
            'name': point.label,
            'shortName': point.label,
            'desc': point.address,
            'coords': LatLng(point.latitude, point.longitude),
            'isFree': point.isFree,
          })
      .toList();

  /// Titik serah terima untuk layanan dengan sopir, ditambah opsi titik bebas.
  List<Map<String, dynamic>> get _withDriverLocations => [
        ..._selfDriveLocations,
        {
          'name': 'Alamat / Titik Lain di Merauke',
          'shortName': 'Titik Lain',
          'desc': 'Tentukan titik jemput bebas pada peta di bawah',
          'isCustom': true,
        },
      ];

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Opsi Rental',
        stepSubtitle: 'Langkah 2 dari 4',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 16),
                  _buildModeSelectionCards(booking),
                  const SizedBox(height: 20),
                  _buildUnifiedLocationCard(booking),
                  const SizedBox(height: 20),
                  _buildRentalPoliciesCard(booking),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildStickyCTA(context, booking),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Layanan Pengemudi & Lokasi',
          style: TextStyle(
            fontSize: AppTypography.sizeHeading,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tentukan model sewa dan titik lokasi penjemputan atau serah terima unit di Merauke.',
          style: TextStyle(
            fontSize: AppTypography.sizeBody,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelectionCards(BookingController booking) {
    final isDriver = booking.withDriver;

    return Column(
      children: [
        // Opsi 1: Lepas Kunci
        InkWell(
          onTap: () {
            final berubah = booking.withDriver;
            booking.toggleDriver(false);
            /* Titik hanya diganti ketika modenya benar-benar berubah. Sebelumnya
               setiap ketukan menyetel ulang ke kantor, sehingga titik yang sudah
               dipilih pelanggan di peta terhapus tanpa peringatan. */
            if (berubah) _pilihTitikBawaan(booking, denganSopir: false);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: !isDriver ? AppColors.cardWhite : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: !isDriver ? AppColors.primaryTeal : AppColors.borderSubtle,
                width: !isDriver ? 2 : 1,
              ),
              boxShadow: !isDriver
                  ? [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: !isDriver ? AppColors.primaryTeal : AppColors.textSecondary,
                      width: 2,
                    ),
                    color: !isDriver ? AppColors.primaryTeal : Colors.transparent,
                  ),
                  child: !isDriver
                      ? const Center(
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap: badge "Bebas Biaya Sopir" turun ke baris berikutnya
                      // saat ukuran teks sistem diperbesar, bukan menimpa judul.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Lepas Kunci',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTitle,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Bebas Biaya Sopir',
                              style: TextStyle(
                                fontSize: AppTypography.sizeTiny,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kemudi mandiri 24 jam penuh per hari. Fleksibilitas tinggi untuk mobilitas pribadi, pekerjaan, atau keluarga.',
                        style: TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Opsi 2: Dengan Sopir Lokal
        InkWell(
          onTap: () {
            final berubah = !booking.withDriver;
            booking.toggleDriver(true);
            if (berubah) _pilihTitikBawaan(booking, denganSopir: true);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDriver ? AppColors.cardWhite : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDriver ? AppColors.primaryTeal : AppColors.borderSubtle,
                width: isDriver ? 2 : 1,
              ),
              boxShadow: isDriver
                  ? [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDriver ? AppColors.primaryTeal : AppColors.textSecondary,
                      width: 2,
                    ),
                    color: isDriver ? AppColors.primaryTeal : Colors.transparent,
                  ),
                  child: isDriver
                      ? const Center(
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap: badge biaya sopir turun ke baris berikutnya saat
                      // ukuran teks sistem diperbesar, bukan meluber ke kanan.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Dengan Sopir Lokal',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTitle,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+Rp ${_formatRupiah(BookingController.driverCostPerDay)} / hari',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeTiny,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D4ED8),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Didampingi staf pengemudi tetap MobilJuragan yang ramah dan hafal seluruh kondisi rute Merauke. Durasi layanan 12 jam/hari.',
                        style: TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedLocationCard(BookingController booking) {
    final isDriver = booking.withDriver;
    final locations = isDriver ? _withDriverLocations : _selfDriveLocations;

    // Cari deskripsi preset aktif secara aman tanpa resiko type cast error
    Map<String, dynamic> matchingLoc;
    final foundIndex = locations.indexWhere(
      (loc) {
        final name = (loc['name'] as String?) ?? '';
        final shortName = (loc['shortName'] as String?) ?? name;
        final pickup = booking.pickupLocation.toLowerCase();
        return pickup.contains(shortName.toLowerCase()) ||
            pickup.contains(name.toLowerCase()) ||
            name.toLowerCase().contains(pickup);
      },
    );
    if (foundIndex != -1) {
      matchingLoc = locations[foundIndex];
    } else {
      matchingLoc = <String, dynamic>{
        'name': booking.pickupLocation,
        'shortName': 'Titik Peta',
        'desc': 'Koordinat titik penjemputan terpilih di peta Merauke',
      };
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isDriver
                            ? 'Titik Penjemputan Sopir'
                            : 'Titik Serah Terima Unit Kendaraan',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    if (isDriver)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Fleksibel',
                          style: TextStyle(
                            fontSize: AppTypography.sizeTiny,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isDriver
                      ? 'Pilih lokasi populer atau ketuk titik bebas di peta untuk penjemputan.'
                      : 'Pilih titik serah terima resmi MobilJuragan di Merauke.',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_memuatTitik)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Memuat titik serah terima...',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            )
          else if (_galatTitik != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _galatTitik!,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: Color(0xFFB45309),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadPickupPoints,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),

          // Horizontal Chips Selector (terisolasi dan terpotong rapi dengan padding insets)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: locations.map((loc) {
                final name = (loc['name'] as String?) ?? 'Lokasi';
                final shortName = (loc['shortName'] as String?) ??
                    (name.startsWith('Diantar ke ') ? name.replaceFirst('Diantar ke ', '') : name);
                final coords = loc['coords'] as LatLng?;
                final isFree = loc['isFree'] == true;
                final isCustom = loc['isCustom'] == true;
                final pickup = booking.pickupLocation.toLowerCase();
                final isSelected = pickup.contains(shortName.toLowerCase()) ||
                    pickup.contains(name.toLowerCase()) ||
                    name.toLowerCase().contains(pickup);

                // Ikon sesuai kategori
                IconData iconData = Icons.place_outlined;
                if (isFree || name.toLowerCase().contains('kantor')) {
                  iconData = Icons.storefront_outlined;
                } else if (name.toLowerCase().contains('bandara')) {
                  iconData = Icons.flight_land;
                } else if (name.toLowerCase().contains('pelabuhan')) {
                  iconData = Icons.directions_boat_outlined;
                } else if (name.toLowerCase().contains('hotel')) {
                  iconData = Icons.hotel_outlined;
                } else if (isCustom) {
                  iconData = Icons.edit_location_alt_outlined;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (isCustom) {
                          /* "Titik Lain" bukan tempat, jadi tidak boleh
                             menyetel koordinat tetap: pelanggan harus memilih
                             sendiri di peta. */
                          _bukaPetaTitikBebas(booking);
                          return;
                        }
                        if (coords == null) {
                          /* Titik tanpa koordinat tidak boleh dipilih: lebih baik
                             tidak terjadi apa-apa daripada menyimpan titik palsu. */
                          return;
                        }
                        booking.setPickupLocation(name, coords.latitude, coords.longitude);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryTeal.withValues(alpha: 0.12)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryTeal : AppColors.borderSubtle,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData,
                              size: 14,
                              color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              shortName,
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primaryNavy : AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (isFree) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeGreenBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'GRATIS',
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeMicro,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.badgeGreenText,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Baris Detail Lokasi Terpilih
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop, size: 16, color: AppColors.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.pickupLocation,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          matchingLoc['desc'] as String? ?? 'Merauke, Papua Selatan',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeTiny,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Peta Terintegrasi Kompak (150px)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: MeraukeLocationMapPicker(
              selectedLocationName: booking.pickupLocation,
              selectedCoordinates: (booking.pickupLatitude != null && booking.pickupLongitude != null)
                  ? LatLng(booking.pickupLatitude!, booking.pickupLongitude!)
                  : null,
              isWithDriver: booking.withDriver,
              mapHeight: 150,
              showCardContainer: false,
              onCustomCoordinateSelected: (customName, coords) {
                booking.setPickupLocation(customName, coords.latitude, coords.longitude);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalPoliciesCard(BookingController booking) {
    final isDriver = booking.withDriver;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isDriver ? Icons.airline_seat_recline_normal : Icons.verified_user_outlined,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(width: 8),
              // Expanded: judul ketentuan membungkus ke baris berikutnya saat
              // ukuran teks sistem diperbesar, bukan meluber ke kanan.
              Expanded(
                child: Text(
                  isDriver ? 'Ketentuan Layanan Sopir Tetap' : 'Ketentuan Sewa Lepas Kunci',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!isDriver) ...[
            _buildPolicyRow('Wajib mengunggah foto asli e-KTP dan SIM A aktif pada halaman status pesanan setelah pengajuan dikirim.'),
            _buildPolicyRow('Wajib mengunduh, menandatangani, dan mengunggah Surat Pernyataan Penyewa (bebas alkohol/narkoba & tanggung jawab unit) sebelum pengambilan kunci.'),
            _buildPolicyRow('Penyewa wajib menunjukkan fisik e-KTP dan SIM A asli saat serah terima unit.'),
            _buildPolicyRow('Bahan bakar dikembalikan sesuai posisi indikator awal serah terima.'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showStatementPreviewModal(context),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 15, color: AppColors.primaryTeal),
                    SizedBox(width: 6),
                    Text(
                      'Lihat Pratinjau Surat Pernyataan',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                        fontFamily: 'Inter',
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildPolicyRow('Pengemudi adalah staf tetap MobilJuragan yang terikat SOP perusahaan.'),
            _buildPolicyRow('Jam kerja operasional harian sopir adalah 12 jam per hari.'),
            _buildPolicyRow('Tanpa kewajiban menyetir sendiri dan tanpa syarat SIM A penyewa.'),
            _buildPolicyRow('Koordinasi nomor WhatsApp sopir dilakukan langsung melalui Chat CS.'),
          ],
        ],
      ),
    );
  }

  void _showStatementPreviewModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined, size: 20, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pratinjau Surat Pernyataan',
                          style: TextStyle(
                            fontSize: AppTypography.sizeBodyLarge,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          'Klausul Hukum Sewa Lepas Kunci',
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  /*
                   * Yang ditampilkan adalah keterangan dokumen resmi yang sedang
                   * aktif di server: nama berkas, jenis, ukuran, dan versinya.
                   *
                   * Sebelumnya layar ini menampilkan empat klausul ringkas yang
                   * ditulis ulang di aplikasi, berbeda dari surat resmi sepuluh
                   * butir. Sekarang dokumennya berupa berkas unggahan admin yang
                   * bisa PDF atau Word, jadi isinya tidak mungkin dibaca sebagai
                   * teks. Pelanggan membaca berkas hasil unduhan.
                   */
                  future: _documentApiService.fetchStatementTemplateText(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data;

                    if (snapshot.hasError || data == null || data.isEmpty) {
                      return Text(
                        'Keterangan dokumen tidak dapat dimuat saat ini. Dokumen lengkap tetap bisa Anda unduh dan tandatangani lewat tombol di bawah.',
                        style: TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          height: 1.4,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      );
                    }

                    final namaBerkas = data['namaBerkas']?.toString();
                    final versi = data['versi']?.toString();
                    final byte = data['byte'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['judul']?.toString() ?? 'Form Kesanggupan',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (namaBerkas != null && namaBerkas.isNotEmpty) namaBerkas,
                            if (byte is int)
                              '${(byte / 1024).toStringAsFixed(0)} KB',
                            if (versi != null) 'versi $versi',
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            height: 1.4,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dokumen ini yang akan Anda cetak, isi, dan tandatangani. Bacalah dengan saksama sebelum menyetujui.',
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            height: 1.4,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Saya Mengerti',
                    style: TextStyle(fontSize: AppTypography.sizeBody, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPolicyRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCTA(BuildContext context, BookingController booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.withDriver ? 'Dengan Sopir Lokal' : 'Lepas Kunci',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.pickupLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DateTimeScreen(
                        vehicle: widget.vehicle,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Lanjut ke Jadwal Sewa',
                  style: AppTypography.cardTitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int amount) {
    final chars = amount.toString().split('').reversed.toList();
    final out = <String>[];
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) out.add('.');
      out.add(chars[i]);
    }
    return out.reversed.join('');
  }
}
