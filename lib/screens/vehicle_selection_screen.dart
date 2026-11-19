import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/daftar_geser_horizontal.dart';
import '../widgets/vehicle_card_item.dart';
import 'vehicle_detail_screen.dart';
import '../theme/app_typography.dart';

/// Layar pemilihan armada kendaraan dengan filter kategori persisten & fitur favorit reaktif
class VehicleSelectionScreen extends StatefulWidget {
  final bool showBottomNav;

  const VehicleSelectionScreen({super.key, this.showBottomNav = false});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  // Kosong sampai pelanggan memilih unit atau keranjang sudah berisi pilihan.
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VehicleController>().refreshCatalog(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleController = context.watch<VehicleController>();
    final filteredVehicles = vehicleController.filteredVehicles;
    final availableVehicles = filteredVehicles.where((v) => v.isAvailable).toList();
    final rentedVehicles = filteredVehicles.where((v) => !v.isAvailable).toList();

    final VehicleModel? selectedVehicle = _pilihKendaraan(
      filteredVehicles,
      vehicleController.vehicles,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(title: 'Pilih Kendaraan'),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryTeal,
              onRefresh: () => vehicleController.refreshCatalog(force: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.screenV),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Katalog Armada Tersedia',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeHeading,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              if (vehicleController.isSyncing)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Bandingkan tipe, kapasitas, dan transmisi armada untuk kenyamanan perjalanan Anda.',
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
                    const SizedBox(height: 16),
                    _buildCategoryFilterBar(vehicleController),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (filteredVehicles.isEmpty)
                            _buildEmptyState(vehicleController)
                          else ...[
                            /* Unit yang sedang disewa dipisah dari yang bisa dipesan.
                               Sebelumnya keduanya bercampur, sehingga pelanggan harus
                               membuka satu per satu untuk tahu mana yang tersedia. */
                            if (availableVehicles.isNotEmpty) ...[
                              _buildSectionLabel('Tersedia (${availableVehicles.length})'),
                              ...availableVehicles.map(
                                (vehicle) => VehicleCardItem(
                                  vehicle: vehicle,
                                  isSelected: vehicle.id == _selectedVehicleId,
                                  onTap: () {
                                    setState(() {
                                      _selectedVehicleId = vehicle.id;
                                    });
                                    context.read<BookingController>().selectVehicle(
                                      vehicle,
                                    );
                                  },
                                  onToggleFavorite: () {
                                    vehicleController.toggleFavorite(vehicle.id);
                                  },
                                ),
                              ),
                            ],
                            if (rentedVehicles.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildSectionLabel('Sedang disewa (${rentedVehicles.length})'),
                              ...rentedVehicles.map(
                                (vehicle) => VehicleCardItem(
                                  vehicle: vehicle,
                                  isSelected: vehicle.id == _selectedVehicleId,
                                  onTap: () {
                                    setState(() {
                                      _selectedVehicleId = vehicle.id;
                                    });
                                    context.read<BookingController>().selectVehicle(vehicle);
                                  },
                                  onToggleFavorite: () {
                                    vehicleController.toggleFavorite(vehicle.id);
                                  },
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildStickyCTA(selectedVehicle),
        ],
      ),
    );
  }

  /*
   * Menentukan unit yang sedang dipilih.
   *
   * Mengembalikan null kalau katalog benar-benar kosong. Dulu ada unit cadangan
   * dari daftar contoh, sehingga tombol "Lanjutkan" bisa menunjuk mobil yang
   * tidak ada di katalog.
   */
  VehicleModel? _pilihKendaraan(
    List<VehicleModel> tersaring,
    List<VehicleModel> semua,
  ) {
    final id = _selectedVehicleId;
    if (id == null) return null;
    for (final kendaraan in tersaring) {
      if (kendaraan.id == id) return kendaraan;
    }
    for (final kendaraan in semua) {
      if (kendaraan.id == id) return kendaraan;
    }
    return null;
  }

  Widget _buildCategoryFilterBar(VehicleController controller) {
    const categories = VehicleController.availableCategories;

    return DaftarGeserHorizontal(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < categories.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _buildFilterChip(controller, categories[index]),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(VehicleController controller, String category) {
    final bool isSelected = controller.selectedCategory == category;
    final bool isFav = category == 'Favorit';

    return InkWell(
      onTap: () => controller.setCategory(category),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFav) ...[
              Icon(
                isSelected ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                size: 16,
                color: isSelected ? AppColors.textWhite : AppColors.primaryNavy,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              category,
              style: TextStyle(
                fontSize: AppTypography.sizeBody,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            if (isFav && controller.favoriteCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${controller.favoriteCount}',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.primaryNavy,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(VehicleController controller) {
    final isFavoriteFilter = controller.selectedCategory == 'Favorit';
    final katalogKosong = controller.vehicles.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            isFavoriteFilter ? Icons.bookmark_border_rounded : Icons.car_rental,
            size: 48,
            color: isFavoriteFilter
                ? AppColors.primaryNavy
                : AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            katalogKosong
                ? 'Belum Ada Armada'
                : (isFavoriteFilter
                      ? 'Belum Ada Armada Favorit'
                      : 'Tidak ada armada kategori "${controller.selectedCategory}"'),
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            katalogKosong
                ? 'Admin belum menambahkan unit ke katalog. Coba muat ulang beberapa saat lagi.'
                : (isFavoriteFilter
                      ? 'Ketuk ikon bookmark pada armada di katalog untuk menyimpannya sebagai kendaraan favorit Anda.'
                      : 'Silakan pilih kategori lain atau periksa kata kunci pencarian Anda.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppTypography.sizeCaption,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => controller.setCategory('Semua'),
            child: const Text('Tampilkan Semua Armada'),
          ),
        ],
      ),
    );
  }

  /// Judul pemisah antar kelompok unit pada daftar.
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTypography.sizeBody,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildStickyCTA(VehicleModel? selectedVehicle) {
    if (selectedVehicle == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
          child: ElevatedButton(
            onPressed: () {
              context.read<BookingController>().selectVehicle(selectedVehicle);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VehicleDetailScreen(vehicle: selectedVehicle),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              elevation: 0,
            ),
            child: Text(
              'Lanjutkan: ${selectedVehicle.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
