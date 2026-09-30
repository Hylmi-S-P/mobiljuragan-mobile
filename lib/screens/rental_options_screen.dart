import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'order_review_screen.dart';

/// Layar pemilihan opsi rental (Frame 05)
/// Memungkinkan pemilihan moda Lepas Kunci vs Dengan Sopir dan titik jemput di Merauke
/// Catatan: Form informasi kedatangan/penerbangan dihilangkan sesuai arahan
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
  final List<String> _locationOptions = [
    'Bandara Mopah Merauke',
    'Swiss-Belhotel Merauke',
    'Hotel Grand Merauke',
    'Kantor / Pool MobilJuragan Merauke',
  ];

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Opsi Rental',
        stepSubtitle: 'Langkah 4 dari 5',
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
                  _buildPickupLocationSection(booking),
                  const SizedBox(height: 20),
                  _buildRentalPoliciesCard(),
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tentukan preferensi berkendara dan lokasi serah terima unit di Merauke.',
          style: TextStyle(
            fontSize: 12,
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
          onTap: () => booking.toggleDriver(false),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lepas Kunci (Self-Drive)',
                            style: TextStyle(
                              fontSize: 14,
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
                              'Rekomendasi Hemat',
                              style: TextStyle(
                                fontSize: 10,
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
                        'Kemudi mandiri, fleksibilitas penuh untuk aktivitas keluarga atau pekerjaan di Merauke.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tarif: Termasuk dalam harga harian unit (Rp 0)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
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

        // Opsi 2: Dengan Sopir
        InkWell(
          onTap: () => booking.toggleDriver(true),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dengan Sopir Lokal',
                            style: TextStyle(
                              fontSize: 14,
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
                            child: const Text(
                              '+Rp 150.000 / hari',
                              style: TextStyle(
                                fontSize: 10,
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
                        'Didampingi pengemudi lokal profesional dan ramah yang hafal kondisi rute Merauke.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tarif: +Rp 150.000 per hari (akomodasi sopir ditanggung)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
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

  Widget _buildPickupLocationSection(BookingController booking) {
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
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryTeal),
              SizedBox(width: 8),
              Text(
                'Titik Lokasi Serah Terima',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _locationOptions.contains(booking.pickupLocation)
                    ? booking.pickupLocation
                    : _locationOptions.first,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
                items: _locationOptions.map((String location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (String? newLocation) {
                  if (newLocation != null) {
                    booking.setPickupLocation(newLocation);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unit akan diantarkan tepat waktu ke lokasi yang Anda tentukan di wilayah Merauke.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalPoliciesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryTeal),
              SizedBox(width: 8),
              Text(
                'Ketentuan Sewa Unit Merauke',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPolicyRow('1. Serah terima unit dilakukan sesuai jadwal dan lokasi pilihan.'),
          _buildPolicyRow('2. Area operasional mencakup wilayah Kota Merauke dan sekitarnya.'),
          _buildPolicyRow('3. Bahan bakar dikembalikan sesuai posisi indikator awal serah terima.'),
        ],
      ),
    );
  }

  Widget _buildPolicyRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
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
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderReviewScreen(
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
            ),
            child: const Text(
              'Lanjutkan ke Tinjau Pesanan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
