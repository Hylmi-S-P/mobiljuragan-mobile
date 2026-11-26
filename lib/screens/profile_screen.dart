import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/legal_terms_sheet.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'help_center_screen.dart';
import 'order_status_screen.dart';
import '../theme/app_typography.dart';

/// Layar Profil Pengguna (Frame 13)
/// Menampilkan data akun pelanggan Merauke, statistik pesanan, pengaturan akun, dan alur login/logout
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final booking = context.watch<BookingController>();
    final user = auth.currentUser;
    final isLoggedIn = auth.isLoggedIn && user != null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Profil Pengguna',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoggedIn) ...[
              _buildUserIdentityCard(
                context,
                name: user.name,
                phone: _formatNomor(user.phone),
                city: user.city,
                initials: user.avatarInitials,
              ),
              const SizedBox(height: 16),
              _buildStatisticsRow(
                activeCount: booking.activeBookings.length,
                completedCount: booking.completedBookings.length,
                totalCount: booking.bookingHistory.length,
              ),
            ] else ...[
              _buildGuestIdentityCard(context),
            ],
            const SizedBox(height: 20),
            _buildMenuSection(context, isLoggedIn, auth, user),
            const SizedBox(height: 24),
            if (isLoggedIn) ...[
              _buildLogoutButton(context, auth),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestIdentityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.account_circle_outlined,
                size: 32,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Anda Belum Masuk Akun',
            style: TextStyle(
              fontSize: AppTypography.sizeHeading,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masuk atau daftar untuk melihat identitas sewa terverifikasi, memantau status mobil di Merauke, dan mengakses riwayat pemesanan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              height: 1.45,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryNavy),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Daftar Baru',
                      style: TextStyle(
                        fontSize: AppTypography.sizeBodyLarge,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                      'Masuk Akun',
                      style: AppTypography.cardTitle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserIdentityCard(
    BuildContext context, {
    required String name,
    required String phone,
    required String city,
    required String initials,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primaryNavy,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : 'MJ',
                style: const TextStyle(
                  fontSize: AppTypography.sizeDisplay,
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
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeHeading,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  city.isNotEmpty ? city : 'Merauke, Papua Selatan',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
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
          child: _buildStatItem(
            'Sewa Berjalan',
            '$activeCount',
            isHighlighted: activeCount > 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem('Riwayat Selesai', '$completedCount'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem('Total Transaksi', '$totalCount'),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.sizeMetric,
              fontWeight: FontWeight.w800,
              color: isHighlighted ? AppColors.primaryTeal : AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTypography.sizeCaption,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    bool isLoggedIn,
    AuthController auth,
    UserModel? user,
  ) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          children: [
            if (isLoggedIn && user != null) ...[
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
            ],
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: 'Syarat & Ketentuan Pengguna',
              onTap: () => LegalTermsSheet.showSyaratDanKetentuan(context),
            ),
            const Divider(height: 1, indent: 52, color: AppColors.borderSubtle),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan Privasi & Akun',
              onTap: () => LegalTermsSheet.showAkunDanPrivasi(context),
            ),
            const Divider(height: 1, indent: 52, color: AppColors.borderSubtle),
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Pusat Bantuan & Layanan CS',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HelpCenterScreen(showBackButton: true),
                  ),
                );
              },
            ),
          ],
        ),
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
          fontSize: AppTypography.sizeBodyLarge,
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
      height: (46 * MediaQuery.textScalerOf(context).scale(1)).clamp(46, 92),
      child: OutlinedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog(context, auth);
        },
        icon: const Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontSize: AppTypography.sizeBodyLarge,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Keluar',
          style: AppTypography.pageTitle,
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun MobilJuragan di perangkat ini?',
          style: TextStyle(
            fontSize: AppTypography.sizeBodyLarge,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              /* Proses keluar ditunggu sampai tuntas lebih dulu, baru dialog
                 ditutup dan SnackBar ditampilkan. Versi sebelumnya menutup
                 dialog lalu memanggil logout() tanpa menunggunya: SnackBar
                 "telah keluar" muncul sebelum token benar-benar terhapus, dan
                 kegagalan di tengah proses tidak pernah sampai ke pengguna. */
              await auth.logout();

              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anda telah keluar dari akun.')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              elevation: 0,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  /// Menampilkan nomor dalam bentuk `+62 812...` tanpa duplikasi awalan `62`.
  static String _formatNomor(String nomor) {
    var digit = nomor.replaceAll(RegExp(r'\D'), '');
    if (digit.startsWith('620')) {
      digit = digit.substring(3);
    } else if (digit.startsWith('62')) {
      digit = digit.substring(2);
    } else if (digit.startsWith('0')) {
      digit = digit.substring(1);
    }
    return '+62 $digit';
  }
}
