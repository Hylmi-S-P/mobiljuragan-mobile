import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../core/config/app_config_store.dart';
import '../core/network/pickup_point_api_service.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/daftar_geser_horizontal.dart';
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
    booking.setPickupLocation(
      titik.label,
      titik.latitude,
      titik.longitude,
      titik.address,
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

  /// Titik serah terima yang ditawarkan sebagai chip.
  ///
  /// Isinya sama untuk kedua mode: daftar titik resmi dari backend. Titik bebas
  /// tidak dibuatkan chip karena pelanggan memilihnya langsung dengan mengetuk
  /// peta di dalam kartu — kalau dijadikan chip, pilihan itu bersembunyi di luar
  /// tepi kanan dan tidak pernah terlihat tanpa menggeser baris chip.
  List<Map<String, dynamic>> get _pickupLocations => _pickupPoints
      .map((point) => {
            'name': point.label,
            'shortName': point.label,
            'desc': point.address,
            'coords': LatLng(point.latitude, point.longitude),
            'isFree': point.isFree,
          })
      .toList();

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
              padding: AppSpacing.screenPadding,
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
                              '+Rp ${_formatRupiah(AppConfigStore.driverDailyRate)} / hari',
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
    final locations = _pickupLocations;

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
                  Expanded(
                    child: Text(
                      'Memuat titik serah terima...',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
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

          // Horizontal Chips Selector (satu baris geser, dengan gradasi tepi
          // supaya terlihat masih ada pilihan di luar layar)
          DaftarGeserHorizontal(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: locations.map((loc) {
                final name = (loc['name'] as String?) ?? 'Lokasi';
                final shortName = (loc['shortName'] as String?) ??
                    (name.startsWith('Diantar ke ') ? name.replaceFirst('Diantar ke ', '') : name);
                final coords = loc['coords'] as LatLng?;
                final isFree = loc['isFree'] == true;
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
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (coords == null) {
                          /* Titik tanpa koordinat tidak boleh dipilih: lebih baik
                             tidak terjadi apa-apa daripada menyimpan titik palsu. */
                          return;
                        }
                        booking.setPickupLocation(
                          name,
                          coords.latitude,
                          coords.longitude,
                          loc['desc'] as String?,
                        );
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
            _buildPolicyRow('Unggah foto e-KTP dan SIM A aktif di halaman status pesanan, lalu tunjukkan berkas fisiknya saat serah terima unit.'),
            _buildPolicyRow('Wajib mengunduh, menandatangani, dan mengunggah Surat Pernyataan Penyewa (bebas alkohol/narkoba & tanggung jawab unit) sebelum pengambilan kunci.'),
            _buildPolicyRow('Bahan bakar dikembalikan sesuai posisi indikator awal serah terima.'),
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
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 46),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Lanjut ke Jadwal Sewa',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle,
                  ),
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
