import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/vehicle_card_item.dart';
import 'vehicle_detail_screen.dart';

/// Layar pemilihan armada kendaraan
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
        stepSubtitle: 'Langkah 1 dari 5',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Katalog Armada Tersedia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bandingkan tipe, kapasitas, dan plat nomor kendaraan.',
                    style: TextStyle(
                      fontSize: 12,
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
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  _buildNoticeCard(filteredVehicles.length),
                  const SizedBox(height: 24),
                ],
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
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = controller.selectedCategory == category;

          return InkWell(
            onTap: () {
              controller.setCategory(category);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryTeal : AppColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(VehicleController controller) {
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
          const Icon(Icons.car_rental, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Tidak ada armada kategori "${controller.selectedCategory}"',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => controller.setCategory('Semua'),
            child: const Text('Tampilkan Semua Armada'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(int count) {
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
            '$count kendaraan ditampilkan dalam kategori ini',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Gunakan filter di atas untuk melihat pilihan kategori lainnya',
            style: TextStyle(
              fontSize: 11,
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
              context.read<BookingController>().selectVehicle(selectedVehicle);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VehicleDetailScreen(vehicle: selectedVehicle),
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
            child: Text(
              'Pilih ${selectedVehicle.name}',
              style: const TextStyle(
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
