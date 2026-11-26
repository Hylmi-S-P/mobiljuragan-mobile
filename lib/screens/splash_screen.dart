import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'main_navigation_screen.dart';

/// Halaman SplashScreen dengan latar navy dan logo MobilJuragan.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _splashBackground = Color(0xFF142B4F);

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

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
  bool _preloadDimulai = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _minimumTimer = Timer(const Duration(milliseconds: 650), () {
      _waktuMinimumSelesai = true;
      _cobaPindah();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preloadDimulai) {
      _preloadDimulai = true;
      precacheImage(
        const AssetImage('assets/images/logo-mj-splash.webp'),
        context,
      ).catchError((Object _) {}).whenComplete(() {
        if (mounted) _animController.forward();
      });
    }

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
        transitionDuration: const Duration(milliseconds: 300),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _splashBackground,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            alwaysIncludeSemantics: true,
            child: Image.asset(
              'assets/images/logo-mj-splash.webp',
              width: 184,
              height: 184,
              fit: BoxFit.contain,
              semanticLabel: 'MobilJuragan',
            ),
          ),
        ),
      ),
    );
  }
}
