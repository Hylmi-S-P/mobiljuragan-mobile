import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import 'main_navigation_screen.dart';
import '../theme/app_typography.dart';

/// Halaman SplashScreen modern peningkatan dari Frame Loading (1346:167)
/// Menampilkan emblem branding MobilJuragan dengan animasi halus
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  /* Dua syarat berpindah layar: waktu tampil minimum sudah lewat, dan status
     boot sesi sudah selesai. Dulu hanya syarat pertama yang ada, sehingga
     aplikasi bisa masuk ke layar utama sebelum pemulihan sesi selesai —
     pengguna yang sebenarnya sudah punya sesi sempat terlihat sebagai tamu,
     dan sebaliknya. Waktu minimum tetap dipertahankan supaya animasi merek
     punya kesempatan tampil utuh. */
  Timer? _minimumTimer;
  bool _waktuMinimumSelesai = false;

  /// Sesi yang ditunggu status bootnya; null bila tidak ada penyedia.
  AuthController? _auth;

  /// Menahan perpindahan agar tidak terjadi dua kali.
  bool _sudahBerpindah = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeIn,
      ),
    );

    _animController.forward();

    _minimumTimer = Timer(const Duration(milliseconds: 2100), () {
      _waktuMinimumSelesai = true;
      _cobaPindah();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /* Penyedia dibaca dengan aman: pengujian widget memasang SplashScreen
       tanpa MultiProvider, dan aplikasi tidak boleh gagal hanya karena itu.
       Bila penyedia ada, status boot-nya ikut ditunggu; bila tidak ada,
       splash tetap berpindah setelah waktu minimum. */
    AuthController? auth;
    try {
      auth = Provider.of<AuthController>(context, listen: false);
    } catch (_) {
      auth = null;
    }

    if (auth != _auth) {
      _auth?.removeListener(_padaPerubahanSesi);
      _auth = auth;
      _auth?.addListener(_padaPerubahanSesi);
    }
    // Status boot bisa saja sudah selesai sebelum listener terpasang.
    _cobaPindah();
  }

  /// Dipanggil setiap kali status boot sesi berubah.
  void _padaPerubahanSesi() {
    _cobaPindah();
  }

  /// Berpindah ke layar utama begitu kedua syarat terpenuhi.
  void _cobaPindah() {
    if (_sudahBerpindah || !mounted) return;
    if (!_waktuMinimumSelesai) return;

    final auth = _auth;
    if (auth != null && auth.bootState == StatusBootSesi.memuat) return;

    _sudahBerpindah = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    _auth?.removeListener(_padaPerubahanSesi);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emblem Icon MobilJuragan
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withValues(alpha: 0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 20,
                          child: Icon(
                            Icons.directions_car_rounded,
                            size: 34,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        const Text(
                          'MJ',
                          style: TextStyle(
                            fontSize: AppTypography.sizeBrand,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Nama Brand
                const Text(
                  'MobilJuragan',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBrandName,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Subteks Wilayah Operasional Merauke
                Text(
                  'Rental Mobil Terpercaya Merauke, Papua Selatan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 48),

                // Progress Indicator Ringan
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryTeal.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
