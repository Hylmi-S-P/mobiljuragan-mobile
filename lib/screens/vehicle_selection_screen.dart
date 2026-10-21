import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
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
  String _selectedVehicleId = 'avanza-g-putih';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentVehicle = context.read<BookingController>().selectedVehicle;
      if (currentVehicle != null && mounted) {
        setState(() {
          _selectedVehicleId = currentVehicle.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleController = context.watch<VehicleController>();
    final filteredVehicles = vehicleController.filteredVehicles;

    final selectedVehicle = filteredVehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => filteredVehicles.isNotEmpty
          ? filteredVehicles.first
          : (vehicleController.vehicles.isNotEmpty
              ? vehicleController.vehicles.first
              : VehicleModel.sampleVehicles.first),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Pilih Kendaraan',
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryTeal,
              onRefresh: () => vehicleController.refreshCatalog(force: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Katalog Armada Tersedia',
                          style: TextStyle(
                            fontSize: AppTypography.sizeHeading,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (vehicleController.isSyncing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bandingkan tipe, kapasitas, dan plat nomor kendaraan.',
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryFilterBar(vehicleController),
                    const SizedBox(height: 16),
                    if (filteredVehicles.isEmpty)
                      _buildEmptyState(vehicleController)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = filteredVehicles[index];
                          return VehicleCardItem(
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
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    _buildNoticeCard(vehicleController, filteredVehicles.length),
                    const SizedBox(height: 24),
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

  Widget _buildCategoryFilterBar(VehicleController controller) {
    const categories = VehicleController.availableCategories;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = controller.selectedCategory == category;
          final bool isFav = category == 'Favorit';

          return InkWell(
            onTap: () {
              controller.setCategory(category);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryTeal : AppColors.borderSubtle,
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
                      color: isSelected ? AppColors.textWhite : const Color(0xFFD97706),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${controller.favoriteCount}',
                        style: TextStyle(
                          fontSize: AppTypography.sizeMicro,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFFB45309),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(VehicleController controller) {
    final isFavoriteFilter = controller.selectedCategory == 'Favorit';

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
            color: isFavoriteFilter ? const Color(0xFFD97706) : AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            isFavoriteFilter
                ? 'Belum Ada Armada Favorit'
                : 'Tidak ada armada kategori "${controller.selectedCategory}"',
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFavoriteFilter
                ? 'Ketuk ikon bookmark pada armada di katalog untuk menyimpannya sebagai kendaraan favorit Anda.'
                : 'Silakan pilih kategori lain atau periksa kata kunci pencarian Anda.',
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

  Widget _buildNoticeCard(VehicleController controller, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count armada siap jalan (${controller.totalFleetCount} unit terdaftar di Merauke)',
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Gunakan filter di atas untuk melihat pilihan kategori armada lainnya',
            style: TextStyle(
              fontSize: AppTypography.sizeCaption,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryTeal,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCTA(VehicleModel selectedVehicle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
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
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Pilih Armada',
              style: TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
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
