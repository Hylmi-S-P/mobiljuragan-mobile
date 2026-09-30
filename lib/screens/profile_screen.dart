import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'order_status_screen.dart';

/// Layar Profil Pengguna (Frame 13)
/// Menampilkan data akun pelanggan Merauke, statistik pesanan, dan menu pengaturan
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final booking = context.watch<BookingController>();
    final user = auth.currentUser ?? UserModel.defaultUser;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Profil Pengguna',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserIdentityCard(user.name, user.phone, user.email, user.nik, user.city),
            const SizedBox(height: 16),
            _buildStatisticsRow(
              activeCount: booking.activeBookings.length,
              completedCount: booking.completedBookings.length,
              totalCount: booking.bookingHistory.length,
            ),
            const SizedBox(height: 20),
            _buildMenuSection(context),
            const SizedBox(height: 24),
            _buildLogoutButton(context, auth),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'MobilJuragan Mobile • Versi 1.0.0 (Merauke Edition)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserIdentityCard(
    String name,
    String phone,
    String email,
    String nik,
    String city,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'HR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.badgeGreenBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TERVERIFIKASI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.badgeGreenText,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
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
          const Divider(height: 24, color: AppColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nomor Induk Kependudukan (NIK)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '${nik.substring(0, 6)}******${nik.substring(nik.length - 4)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow({
    required int activeCount,
    required int completedCount,
    required int totalCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Sewa Aktif', '$activeCount', const Color(0xFF1D4ED8), const Color(0xFFEFF6FF)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem('Selesai', '$completedCount', AppColors.badgeGreenText, AppColors.badgeGreenBg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem('Total Sewa', '$totalCount', AppColors.primaryNavy, AppColors.surfaceLight),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'Status Pesanan Terkini',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderStatusScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 52, color: AppColors.borderSubtle),
          _buildMenuItem(
            icon: Icons.shield_outlined,
            title: 'Syarat & Kebijakan Rental Kantor',
            onTap: () {
              _showTermsModal(context);
            },
          ),
          const Divider(height: 1, indent: 52, color: AppColors.borderSubtle),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Bantuan Layanan Pelanggan',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buka Tab Bantuan di bilah navigasi bawah untuk melihat FAQ & Chat CS.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryNavy),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthController auth) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog(context, auth);
        },
        icon: const Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
            fontFamily: 'Inter',
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun MobilJuragan di perangkat ini?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anda telah keluar dari akun.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (modalCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ketentuan Sewa Unit Merauke',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Pelanggan wajib menunjukkan dokumen fisik asli KTP dan SIM A saat serah terima armada di kantor MobilJuragan Merauke.\n\n'
                '2. Penggunaan kendaraan meliputi area Kota Merauke dan sekitarnya sesuai kesepakatan rute.\n\n'
                '3. Bahan bakar dikembalikan sesuai posisi awal serah terima armada.',
                style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(modalCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Saya Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
