import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/support_controller.dart';
import 'controllers/vehicle_controller.dart';
import 'core/config/app_config_store.dart';
import 'core/network/api_client.dart';
import 'core/network/app_config_api_service.dart';
import 'data/local/database/app_database.dart';
import 'data/local/preferences/app_settings_service.dart';
import 'data/local/secure/secure_storage_service.dart';
import 'data/remote/ai_api_service.dart';
import 'data/remote/auth_api_service.dart';
import 'data/remote/booking_api_service.dart';
import 'data/remote/faq_api_service.dart';
import 'data/remote/ticket_api_service.dart';
import 'data/remote/vehicle_api_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/vehicle_repository.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Penangkap galat global agar kegagalan UI maupun asinkron tertangani aman
  // tanpa mencetak detail sensitif di build rilis.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Galat asinkron aplikasi: ${error.runtimeType}');
    }
    return true;
  };

  /* 1. Inisialisasi layanan notifikasi sistem perangkat di latar belakang.
     Meminta izin notifikasi Android 13+ sebelum runApp() bisa menahan frame
     pertama di logo splash bawaan; kegagalannya juga tidak boleh menghalangi
     aplikasi dibuka. */
  unawaited(
    NotificationService().init().catchError((Object galat) {
      if (kDebugMode) {
        debugPrint('Notifikasi perangkat tidak aktif: ${galat.runtimeType}');
      }
    }),
  );

  // 2. Inisialisasi tier penyimpanan pengaturan (SharedPreferences)
  final settingsService = await AppSettingsService.create();

  // 3. Inisialisasi tier penyimpanan rahasia & klien HTTP terpusat
  final secureStorage = SecureStorageService();
  final apiClient = ApiClient(secureStorage: secureStorage);

  // 4. Inisialisasi tier penyimpanan terstruktur lokal (Drift SQLite)
  final appDatabase = AppDatabase();

  /* Pengaturan publik (tarif jasa supir, jam operasional) dibaca di latar
     belakang agar startup tidak tertahan di logo splash Flutter saat DNS/sinyal
     lambat. Selama belum diterima, AppConfigStore memakai nilai cadangan dan
     tagihan tetap dihitung server. */
  unawaited(
    AppConfigApiService(apiClient)
        .fetchConfig()
        .then(AppConfigStore.terapkan)
        .catchError((Object _) {
          AppConfigStore.reset();
        }),
  );

  // 5. Inisialisasi layanan API dan lapisan Repository Offline-First
  final vehicleApiService = VehicleApiService(apiClient);
  final authApiService = AuthApiService(apiClient);
  final bookingApiService = BookingApiService(apiClient);
  final faqApiService = FaqApiService(apiClient);
  final ticketApiService = TicketApiService(apiClient);
  final aiApiService = AiApiService(apiClient);

  final vehicleRepo = VehicleRepository(
    vehicleDao: appDatabase.vehicleDao,
    apiService: vehicleApiService,
    settingsService: settingsService,
    secureStorage: secureStorage,
  );
  final authRepo = AuthRepository(
    apiService: authApiService,
    secureStorage: secureStorage,
  );
  final bookingRepo = BookingRepository(
    appDatabase.bookingDao,
    bookingApiService,
    secureStorage,
    appDatabase.vehicleDao,
  );

  /* Server yang menolak token (401/403) harus berujung pada satu jalur keluar
     akun, bukan pada setiap layar yang gagal sendiri-sendiri. Penangan ini
     dipasang ke controller sesungguhnya, sehingga yang dijalankan adalah
     pembersihan sesi yang utuh, bukan sekadar penghapusan token. */
  final authController = AuthController(
    repository: authRepo,
    secureStorage: secureStorage,
    bookingRepository: bookingRepo,
    // Jejak aktivitas pengguna (kategori terakhir, riwayat pencarian) ikut
    // dibersihkan saat keluar akun.
    settingsService: settingsService,
  );
  ApiClient.onUnauthorized = authController.logout;
  ApiClient.onSessionRejected = authController.tanganiSesiDitolak;
  unawaited(authController.initSession());

  // Set system overlay style untuk status bar yang bersih dan transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.cardWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Layanan & Database
        Provider<AppDatabase>.value(value: appDatabase),
        Provider<AppSettingsService>.value(value: settingsService),
        Provider<SecureStorageService>.value(value: secureStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<VehicleRepository>.value(value: vehicleRepo),
        Provider<AuthRepository>.value(value: authRepo),
        Provider<BookingRepository>.value(value: bookingRepo),

        // State Management Controllers
        // AuthController wajib berada di atas seluruh ProxyProvider yang bergantung padanya.
        ChangeNotifierProvider.value(value: authController),
        /* Armada juga mengikuti sesi, karena penanda favorit sekarang menempel
           pada akun (tabel favorites), bukan pada baris kendaraan. */
        ChangeNotifierProxyProvider<AuthController, VehicleController>(
          create: (_) => VehicleController(
            repository: vehicleRepo,
            settingsService: settingsService,
            idPemilik: authController.currentUser?.id,
          ),
          update: (_, auth, vehicle) {
            final controller =
                vehicle ??
                VehicleController(
                  repository: vehicleRepo,
                  settingsService: settingsService,
                  idPemilik: auth.currentUser?.id,
                );
            controller.syncIfSessionChanged(auth.currentUser?.id);
            return controller;
          },
        ),
        /* BookingController mengikuti sesi: saat akun berganti, riwayat akun
           sebelumnya dibuang dan riwayat akun baru diambil dari server. */
        ChangeNotifierProxyProvider<AuthController, BookingController>(
          create: (_) => BookingController(
            repository: bookingRepo,
            apiService: bookingApiService,
            idPemilik: authController.currentUser?.id,
          ),
          update: (_, auth, booking) {
            if (booking != null) {
              booking.syncIfSessionChanged(auth.currentUser?.id);
              return booking;
            }
            return BookingController(
              repository: bookingRepo,
              apiService: bookingApiService,
              idPemilik: auth.currentUser?.id,
            );
          },
        ),
        ChangeNotifierProxyProvider<AuthController, SupportController>(
          create: (_) => SupportController(
            faqApiService: faqApiService,
            ticketApiService: ticketApiService,
            aiApiService: aiApiService,
            secureStorage: secureStorage,
          )..fetchFaqs(),
          update: (_, auth, support) {
            if (support != null) {
              support.syncIfSessionChanged(auth.currentUser?.id);
              return support;
            }
            return SupportController(
              faqApiService: faqApiService,
              ticketApiService: ticketApiService,
              aiApiService: aiApiService,
              secureStorage: secureStorage,
            )..fetchFaqs();
          },
        ),
      ],
      child: const MobilJuraganApp(),
    ),
  );
}

/// Root Widget MobilJuragan Mobile App
class MobilJuraganApp extends StatefulWidget {
  const MobilJuraganApp({super.key});

  @override
  State<MobilJuraganApp> createState() => _MobilJuraganAppState();
}

class _MobilJuraganAppState extends State<MobilJuraganApp>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  AuthController? _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AuthController? berikutnya;
    try {
      berikutnya = Provider.of<AuthController>(context, listen: false);
    } on ProviderNotFoundException {
      berikutnya = null;
    }

    if (!identical(_auth, berikutnya)) {
      _auth?.removeListener(_cekPesanSesiBerakhir);
      _auth = berikutnya;
      _auth?.addListener(_cekPesanSesiBerakhir);
      _cekPesanSesiBerakhir();
    }
  }

  void _cekPesanSesiBerakhir() {
    final auth = _auth;
    if (auth == null || !auth.adaPesanSesiBerakhir) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = _scaffoldMessengerKey.currentState;
      if (messenger == null) return;
      final pesan = _auth?.konsumsiPesanSesiBerakhir();
      if (pesan == null || pesan.isEmpty) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(pesan),
            backgroundColor: AppColors.statusCancelled,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = _auth;
      if (auth != null) {
        unawaited(auth.periksaSesiJikaAktif());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth?.removeListener(_cekPesanSesiBerakhir);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobilJuragan',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
