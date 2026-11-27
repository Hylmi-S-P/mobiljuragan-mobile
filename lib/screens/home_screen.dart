import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'order_status_screen.dart';
import 'profile_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_selection_screen.dart';
import '../theme/app_typography.dart';
import '../widgets/gambar_kendaraan.dart';

/// Halaman utama aplikasi pelanggan MobilJuragan
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPesan;
  final bool isActive;
  final Duration autoSlideInterval;

  const HomeScreen({
    super.key,
    this.onNavigateToPesan,
    this.isActive = true,
    this.autoSlideInterval = const Duration(seconds: 4),
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentSlideIndex = 0;
  int _totalSlides = 0;
  bool _isForeground = true;
  bool _isUserDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    _aturTimerAutoSlide();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.autoSlideInterval != widget.autoSlideInterval) {
      _aturTimerAutoSlide(
        forceRestart: oldWidget.autoSlideInterval != widget.autoSlideInterval,
      );
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void _aturTimerAutoSlide({bool forceRestart = false}) {
    if (!widget.isActive ||
        !_isForeground ||
        _isUserDragging ||
        _totalSlides <= 1) {
      _autoSlideTimer?.cancel();
      _autoSlideTimer = null;
      return;
    }

    if (_autoSlideTimer != null && _autoSlideTimer!.isActive && !forceRestart) {
      return;
    }

    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(widget.autoSlideInterval, (_) {
      if (!mounted || !_pageController.hasClients || _totalSlides <= 1) return;
      final nextPage = (_currentSlideIndex + 1) % _totalSlides;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  List<VehicleModel> _selectSlideshowVehicles(List<VehicleModel> vehicles) {
    final available = vehicles.where((v) => v.isAvailable).toList();
    final source = available.isNotEmpty
        ? available
        : List<VehicleModel>.from(vehicles);
    return [
      ...source.where((v) => v.isPopular),
      ...source.where((v) => !v.isPopular),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vehicleController = context.watch<VehicleController>();
    final slides = _selectSlideshowVehicles(vehicleController.vehicles);
    final int safeIndex;

    if (slides.isEmpty) {
      _totalSlides = 0;
      _aturTimerAutoSlide();
      safeIndex = 0;
    } else {
      _totalSlides = slides.length;
      safeIndex = _currentSlideIndex.clamp(0, slides.length - 1);
      if (_currentSlideIndex >= slides.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients &&
              (_pageController.page?.round() ?? 0) != safeIndex) {
            _pageController.jumpToPage(safeIndex);
          }
          if (_currentSlideIndex != safeIndex) {
            setState(() => _currentSlideIndex = safeIndex);
          }
        });
      }
      _aturTimerAutoSlide();
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 18),
              if (slides.isEmpty)
                _buildKartuKosong()
              else
                _buildVehicleSlideshow(slides, safeIndex),
              const SizedBox(height: 22),
              _buildReservationStatusSection(),
              const SizedBox(height: 16),
              _buildPrimaryCTA(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final auth = context.watch<AuthController>();
    final isLoggedIn = auth.isLoggedIn && auth.currentUser != null;
    final initials = isLoggedIn ? (auth.currentUser!.avatarInitials) : 'MJ';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Expanded: teks lokasi menyusut dengan ellipsis saat ukuran teks
        // sistem diperbesar, bukan mendorong avatar keluar layar.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MobilJuragan',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Merauke, Papua Selatan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.sizeHeading,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLoggedIn
                      ? AppColors.primaryNavy
                      : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: isLoggedIn
                      ? null
                      : Border.all(color: AppColors.borderSubtle, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isLoggedIn
                          ? AppColors.textWhite
                          : AppColors.textSecondary,
                      fontSize: AppTypography.sizeTitle,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /*
   * Ditampilkan saat katalog masih kosong.
   *
   * Sebelumnya bagian ini selalu terisi karena ada sembilan unit contoh di
   * dalam kode. Sekarang, kalau admin belum menambahkan armada, pelanggan
   * melihat keterangan yang jujur dan tombol muat ulang.
   */
  Widget _buildKartuKosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Armada belum tersedia',
            style: TextStyle(
              fontSize: AppTypography.sizeHeading,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Daftar kendaraan akan tampil di sini setelah admin menambahkan unit ke katalog.',
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.read<VehicleController>().refreshCatalog(force: true);
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Muat ulang katalog'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSlideshow(List<VehicleModel> slides, int safeIndex) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
    final cardHeight = 176.0 + (96.0 * textScale);

    if (slides.length == 1) {
      return SizedBox(
        height: cardHeight,
        child: _buildFeaturedCard(slides.first, index: 0, total: 1),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: cardHeight,
          child: Listener(
            onPointerDown: (_) {
              _isUserDragging = true;
              _aturTimerAutoSlide();
            },
            onPointerUp: (_) {
              _isUserDragging = false;
              _aturTimerAutoSlide();
            },
            onPointerCancel: (_) {
              _isUserDragging = false;
              _aturTimerAutoSlide();
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              onPageChanged: (idx) {
                setState(() => _currentSlideIndex = idx);
              },
              itemBuilder: (context, index) => _buildFeaturedCard(
                slides[index],
                index: index,
                total: slides.length,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (slides.length <= 12)
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: List.generate(slides.length, (i) {
                final isCurrent = i == safeIndex;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isCurrent ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primaryNavy
                          : AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          )
        else
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                '${safeIndex + 1} / ${slides.length}',
                style: const TextStyle(
                  fontSize: AppTypography.sizeTiny,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedCard(
    VehicleModel vehicle, {
    required int index,
    required int total,
  }) {
    final String badgeLabel;
    final Color badgeBg;
    final Color badgeTextColor;

    if (vehicle.isPopular) {
      badgeLabel = 'TERPOPULER DI MOBILJURAGAN';
      badgeBg = AppColors.accentSoft;
      badgeTextColor = AppColors.accent;
    } else if (vehicle.isAvailable) {
      badgeLabel = 'ARMADA TERSEDIA';
      badgeBg = AppColors.tealLight;
      badgeTextColor = AppColors.primaryTeal;
    } else {
      badgeLabel = 'KATALOG ARMADA';
      badgeBg = AppColors.surfaceLight;
      badgeTextColor = AppColors.textSecondary;
    }

    return InkWell(
      onTap: () {
        context.read<BookingController>().selectVehicle(vehicle);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VehicleDetailScreen(vehicle: vehicle),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                if (total > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${index + 1}/$total',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeHeading,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${vehicle.bodyType} \u2022 ${vehicle.seatCapacity} \u2022 ${vehicle.transmission}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  color: AppColors.surfaceLight,
                  child: GambarKendaraan(
                    sumber: vehicle.heroImageUrl ?? vehicle.imageUrl,
                    fit: BoxFit.contain,
                    lebarLogis: 320,
                    tinggiLogis: 130,
                    cadangan: const Center(
                      child: Icon(
                        Icons.directions_car,
                        color: AppColors.textSecondary,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationStatusSection() {
    final booking = context.watch<BookingController>();
    final activeOrder = booking.activeBooking;
    final hasActive = booking.hasActiveBooking && activeOrder != null;
    final vehicle = activeOrder?.vehicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Reservasi',
          style: TextStyle(
            fontSize: AppTypography.sizeTitle,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: hasActive
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderStatusScreen(booking: activeOrder),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasActive
                    ? (activeOrder.status == BookingStatus.mobilSiapDigunakan
                          ? const Color(0xFF16A34A)
                          : AppColors.primaryNavy)
                    : AppColors.borderSubtle,
                width: hasActive ? 1.5 : 1,
              ),
              boxShadow: hasActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasActive
                        ? (activeOrder.status ==
                                  BookingStatus.mobilSiapDigunakan
                              ? const Color(0xFFDCFCE7)
                              : AppColors.badgeNavyBg)
                        : AppColors.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      hasActive
                          ? (activeOrder.status ==
                                    BookingStatus.mobilSiapDigunakan
                                ? Icons.key
                                : Icons.directions_car)
                          : Icons.receipt_long,
                      color: hasActive
                          ? (activeOrder.status ==
                                    BookingStatus.mobilSiapDigunakan
                                ? const Color(0xFF15803D)
                                : AppColors.textWhite)
                          : AppColors.primaryTeal,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasActive
                            ? (vehicle?.name ?? 'Sewa Aktif Berjalan')
                            : 'Belum ada sewa aktif',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasActive
                            ? 'Kode: ${activeOrder.id} • ${activeOrder.durationDays} Hari (${activeOrder.modeLabel})'
                            : 'Pilih armada siap pakai di Merauke',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (hasActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getReservationSubtitleHint(activeOrder),
                          style: TextStyle(
                            fontSize: AppTypography.sizeTiny,
                            fontWeight: FontWeight.w500,
                            color:
                                activeOrder.status ==
                                    BookingStatus.mobilSiapDigunakan
                                ? const Color(0xFF15803D)
                                : AppColors.primaryNavy,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasActive) _buildReservationStatusBadge(activeOrder),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getReservationSubtitleHint(BookingModel order) {
    final payStatus = order.paymentStatus?.toUpperCase();
    switch (order.status) {
      case BookingStatus.permintaanDiterima:
        return 'Pengajuan sewa sedang ditinjau admin';
      case BookingStatus.pemeriksaanArmada:
        return 'Armada sedang diperiksa sebelum serah terima';
      case BookingStatus.menungguTarifFinal:
        return 'Admin sedang menghitung rincian tarif final';
      case BookingStatus.menungguPembayaran:
        if (payStatus == 'PENDING_VERIFICATION') {
          return 'Bukti pembayaran sedang diverifikasi admin';
        }
        if (payStatus == 'FAILED') {
          return 'Bukti pembayaran ditolak, silakan unggah ulang';
        }
        return 'Rincian tarif terbit, silakan selesaikan pembayaran di aplikasi';
      case BookingStatus.pembayaranSelesai:
      case BookingStatus.verifikasiKantor:
        return 'Pembayaran terkonfirmasi, armada disiapkan';
      case BookingStatus.mobilSiapDigunakan:
        /* Mode dengan sopir tidak menyerahkan kunci, jadi kalimatnya dibedakan:
           "kunci siap diserahterimakan" hanya benar untuk lepas kunci. */
        return order.withDriver
            ? 'Sopir siap menjemput Anda di ${order.pickupLocation}'
            : 'Kunci siap diserahterimakan di ${order.pickupLocation}';
      case BookingStatus.selesai:
        return 'Masa sewa telah selesai';
      case BookingStatus.dibatalkan:
        return 'Pengajuan sewa telah dibatalkan';
    }
  }

  Widget _buildReservationStatusBadge(BookingModel order) {
    final payStatus = order.paymentStatus?.toUpperCase();
    Color bg;
    Color text;
    String label;

    switch (order.status) {
      case BookingStatus.permintaanDiterima:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'MENUNGGU';
        break;
      case BookingStatus.pemeriksaanArmada:
        bg = AppColors.tealLight;
        text = AppColors.primaryTeal;
        label = 'DISIAPKAN';
        break;
      case BookingStatus.mobilSiapDigunakan:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'SIAP PAKAI';
        break;
      case BookingStatus.menungguPembayaran:
        if (payStatus == 'PENDING_VERIFICATION') {
          bg = AppColors.tealLight;
          text = AppColors.primaryTeal;
          label = 'VERIFIKASI BAYAR';
        } else if (payStatus == 'FAILED') {
          bg = const Color(0xFFFEF2F2);
          text = const Color(0xFFB91C1C);
          label = 'BUKTI DITOLAK';
        } else {
          bg = AppColors.badgeAmberBg;
          text = AppColors.badgeAmberText;
          label = 'MENUNGGU BAYAR';
        }
        break;
      case BookingStatus.menungguTarifFinal:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFB45309);
        label = 'HITUNG TARIF';
        break;
      case BookingStatus.pembayaranSelesai:
      case BookingStatus.verifikasiKantor:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF047857);
        label = 'LUNAS';
        break;
      case BookingStatus.selesai:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        label = 'SELESAI';
        break;
      case BookingStatus.dibatalkan:
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFB91C1C);
        label = 'BATAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeTiny,
          fontWeight: FontWeight.w700,
          color: text,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildPrimaryCTA() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
      child: ElevatedButton(
        onPressed: () {
          if (widget.onNavigateToPesan != null) {
            widget.onNavigateToPesan!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VehicleSelectionScreen(),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flexible: label menyusut dengan ellipsis agar tidak meluber
            // saat ukuran teks sistem diperbesar.
            Flexible(
              child: Text(
                'Pesan Mobil Sekarang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sectionTitle,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
