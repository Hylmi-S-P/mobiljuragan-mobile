import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
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
  // Preset lokasi khusus Lepas Kunci (fokus titik serah terima resmi)
  final List<Map<String, dynamic>> _selfDriveLocations = [
    {
      'name': 'Pool Kantor MobilJuragan (Gratis)',
      'shortName': 'Pool Kantor',
      'desc': 'Jl. Brawijaya No. 88, Merauke Kota',
      'coords': const LatLng(-8.4905, 140.3995),
      'isFree': true,
    },
    {
      'name': 'Diantar ke Bandara Mopah Merauke',
      'shortName': 'Bandara Mopah',
      'desc': 'Lobi Kedatangan & Parkir VIP Bandara',
      'coords': const LatLng(-8.5202, 140.4180),
      'isFree': false,
    },
    {
      'name': 'Diantar ke Swiss-Belhotel Merauke',
      'shortName': 'Swiss-Belhotel',
      'desc': 'Jl. Raya Mandala No. 53, Merauke',
      'coords': const LatLng(-8.4845, 140.3878),
      'isFree': false,
    },
    {
      'name': 'Diantar ke Hotel Grand Merauke',
      'shortName': 'Hotel Grand',
      'desc': 'Jl. Raya Mandala No. 12, Merauke',
      'coords': const LatLng(-8.4950, 140.4020),
      'isFree': false,
    },
  ];

  // Preset lokasi khusus Dengan Sopir (fleksibel di mana saja di Merauke)
  final List<Map<String, dynamic>> _withDriverLocations = [
    {
      'name': 'Bandara Mopah Merauke',
      'shortName': 'Bandara Mopah',
      'desc': 'Lobi Kedatangan & Parkir VIP Bandara Mopah',
      'coords': const LatLng(-8.5202, 140.4180),
    },
    {
      'name': 'Swiss-Belhotel Merauke',
      'shortName': 'Swiss-Belhotel',
      'desc': 'Jl. Raya Mandala No. 53, Merauke',
      'coords': const LatLng(-8.4845, 140.3878),
    },
    {
      'name': 'Hotel Grand Merauke',
      'shortName': 'Hotel Grand',
      'desc': 'Jl. Raya Mandala No. 12, Merauke',
      'coords': const LatLng(-8.4950, 140.4020),
    },
    {
      'name': 'Pool Kantor MobilJuragan',
      'shortName': 'Pool Kantor',
      'desc': 'Jl. Brawijaya No. 88, Merauke Kota',
      'coords': const LatLng(-8.4905, 140.3995),
    },
    {
      'name': 'Alamat / Titik Lain di Merauke',
      'shortName': 'Titik Lain',
      'desc': 'Tentukan titik jemput bebas pada peta di bawah',
      'coords': const LatLng(-8.4991, 140.4011),
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
          'Tentukan moda sewa dan titik lokasi penjemputan atau serah terima unit di Merauke.',
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
            booking.toggleDriver(false);
            // Default titik serah terima lepas kunci: Pool Kantor (gratis)
            booking.setPickupLocation('Pool Kantor MobilJuragan (Gratis)', -8.4905, 140.3995);
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
                            'Lepas Kunci (Self-Drive)',
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
            booking.toggleDriver(true);
            // Default titik penjemputan dengan sopir: Bandara Mopah Merauke
            booking.setPickupLocation('Bandara Mopah Merauke', -8.5202, 140.4180);
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
        'coords': LatLng(booking.pickupLatitude ?? -8.4991, booking.pickupLongitude ?? 140.4011),
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
                      : 'Pilih ambil di garasi pool MobilJuragan (gratis) atau diantar ke bandara/hotel.',
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
                final coords = (loc['coords'] as LatLng?) ?? const LatLng(-8.4991, 140.4011);
                final isFree = loc['isFree'] == true;
                final isCustom = loc['isCustom'] == true;
                final pickup = booking.pickupLocation.toLowerCase();
                final isSelected = pickup.contains(shortName.toLowerCase()) ||
                    pickup.contains(name.toLowerCase()) ||
                    name.toLowerCase().contains(pickup);

                // Ikon sesuai kategori
                IconData iconData = Icons.place_outlined;
                if (isFree || name.toLowerCase().contains('pool')) {
                  iconData = Icons.storefront_outlined;
                } else if (name.toLowerCase().contains('bandara')) {
                  iconData = Icons.flight_land;
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
            _buildPolicyRow('1. Wajib menunjukkan fisik e-KTP dan SIM A asli saat serah terima unit.'),
            _buildPolicyRow('2. Serah terima unit dilakukan di pool kantor atau diantar ke bandara/hotel.'),
            _buildPolicyRow('3. Deposit jaminan sewa (refundable) dikonfirmasi admin pada tarif final.'),
            _buildPolicyRow('4. Bahan bakar dikembalikan sesuai posisi indikator awal serah terima.'),
          ] else ...[
            _buildPolicyRow('1. Pengemudi adalah staf tetap MobilJuragan yang terikat SOP perusahaan.'),
            _buildPolicyRow('2. Jam kerja operasional harian sopir adalah 12 jam per hari.'),
            _buildPolicyRow('3. Bebas uang deposit jaminan armada dan tanpa syarat SIM A penyewa.'),
            _buildPolicyRow('4. Koordinasi nomor WhatsApp sopir dilakukan langsung melalui Chat CS.'),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        // Wrap: saat ukuran teks sangat besar, tombol turun ke barisnya sendiri
        // dan label kiri tetap punya lebar layar penuh untuk membungkus wajar.
        // Sebelumnya Row menahan keduanya sebaris sehingga label terhimpit
        // sampai terpecah satu huruf per baris.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 10,
          children: [
            ConstrainedBox(
              // Sisakan ruang untuk tombol bila masih muat sebaris.
              constraints: BoxConstraints(
                minWidth: 120,
                maxWidth: MediaQuery.sizeOf(context).width - 200,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.withDriver ? 'Dengan Sopir Lokal' : 'Lepas Kunci (Self-Drive)',
                    maxLines: 2,
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
            SizedBox(
              // Tinggi ikut skala teks sistem agar label tombol tidak terpotong.
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
                  padding: const EdgeInsets.symmetric(horizontal: 18),
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
