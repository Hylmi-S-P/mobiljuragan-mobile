import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/merauke_geocoding_service.dart';
import '../theme/app_colors.dart';

/// Data preset landmark dan titik lokasi populer di Merauke
class MeraukeLocationPreset {
  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final bool isPool;
  final bool isAirport;
  final bool isHotel;

  const MeraukeLocationPreset({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    this.isPool = false,
    this.isAirport = false,
    this.isHotel = false,
  });

  static const List<MeraukeLocationPreset> standardPresets = [
    MeraukeLocationPreset(
      id: 'pool',
      name: 'Pool Kantor MobilJuragan (Gratis)',
      address: 'Jl. Brawijaya No. 88, Merauke Kota',
      coordinates: LatLng(-8.4905, 140.3995),
      isPool: true,
    ),
    MeraukeLocationPreset(
      id: 'airport',
      name: 'Bandara Mopah Merauke',
      address: 'Lobi Kedatangan & Parkir VIP Bandara Mopah',
      coordinates: LatLng(-8.5202, 140.4180),
      isAirport: true,
    ),
    MeraukeLocationPreset(
      id: 'swissbel',
      name: 'Swiss-Belhotel Merauke',
      address: 'Jl. Raya Mandala No. 53, Merauke',
      coordinates: LatLng(-8.4845, 140.3878),
      isHotel: true,
    ),
    MeraukeLocationPreset(
      id: 'grand',
      name: 'Hotel Grand Merauke',
      address: 'Jl. Raya Mandala No. 12, Merauke',
      coordinates: LatLng(-8.4950, 140.4020),
      isHotel: true,
    ),
  ];
}

/// Widget Peta Interaktif Merauke menggunakan OpenStreetMap & flutter_map
/// Mendukung pemilihan lokasi penjemputan (Dengan Sopir) maupun serah terima unit (Lepas Kunci)
class MeraukeLocationMapPicker extends StatefulWidget {
  final String selectedLocationName;
  final LatLng? selectedCoordinates;
  final ValueChanged<MeraukeLocationPreset>? onPresetSelected;
  final void Function(String locationName, LatLng coordinates)? onCustomCoordinateSelected;
  final bool isWithDriver;
  final bool isMiniPreview;
  final double mapHeight;
  final bool showCardContainer;
  final bool showFullscreenButton;

  const MeraukeLocationMapPicker({
    super.key,
    required this.selectedLocationName,
    this.selectedCoordinates,
    this.onPresetSelected,
    this.onCustomCoordinateSelected,
    this.isWithDriver = false,
    this.isMiniPreview = false,
    this.mapHeight = 155,
    this.showCardContainer = true,
    this.showFullscreenButton = true,
  });

  @override
  State<MeraukeLocationMapPicker> createState() => _MeraukeLocationMapPickerState();
}

class _MeraukeLocationMapPickerState extends State<MeraukeLocationMapPicker> {
  late final MapController _mapController;
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.selectedCoordinates ?? _findMatchingCoordinates(widget.selectedLocationName);
  }

  @override
  void didUpdateWidget(covariant MeraukeLocationMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLocationName != oldWidget.selectedLocationName ||
        widget.selectedCoordinates != oldWidget.selectedCoordinates) {
      final newCoord = widget.selectedCoordinates ?? _findMatchingCoordinates(widget.selectedLocationName);
      setState(() {
        _currentCenter = newCoord;
      });
      _flyTo(newCoord);
    }
  }

  LatLng _findMatchingCoordinates(String name) {
    for (final preset in MeraukeLocationPreset.standardPresets) {
      if (preset.name.toLowerCase().contains(name.toLowerCase()) ||
          name.toLowerCase().contains(preset.name.toLowerCase()) ||
          name.toLowerCase().contains(preset.id)) {
        return preset.coordinates;
      }
    }
    // Default pusat kota Merauke (Tugu Lingkaran Brawijaya)
    return const LatLng(-8.4991, 140.4011);
  }

  void _flyTo(LatLng target) {
    if (widget.isMiniPreview) return;
    try {
      _mapController.move(target, 14.5);
    } catch (_) {
      // Abaikan jika map controller belum siap
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMiniPreview) {
      return _buildMiniPreview();
    }

    return _buildInteractiveMap();
  }

  Widget _buildMiniPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 13.8,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mobiljuragan.mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentCenter,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryTeal,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pin_drop, size: 12, color: AppColors.primaryTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.selectedLocationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMap() {
    if (!widget.showCardContainer) {
      return _buildMapCanvas(
        height: widget.mapHeight,
        borderRadius: BorderRadius.circular(10),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.primaryTeal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isWithDriver
                            ? 'Peta Titik Penjemputan Sopir'
                            : 'Peta Titik Serah Terima Unit',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isWithDriver
                            ? 'Sopir akan menjemput tepat di titik pin lokasi terpilih.'
                            : 'Kunci dan armada diserahterimakan di titik lokasi ini.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildMapCanvas(
            height: widget.mapHeight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCanvas({
    required double height,
    required BorderRadius borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
                onTap: (tapPosition, point) async {
                  if (widget.isWithDriver && widget.onCustomCoordinateSelected != null) {
                    setState(() {
                      _currentCenter = point;
                    });
                    widget.onCustomCoordinateSelected!(
                      'Memuat nama lokasi...',
                      point,
                    );
                    final resolvedLocation = await MeraukeGeocodingService.resolveLocationNameDebounced(point);
                    if (mounted && resolvedLocation != null) {
                      widget.onCustomCoordinateSelected!(
                        resolvedLocation,
                        point,
                      );
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mobiljuragan.mobile',
                ),
                MarkerLayer(
                  markers: [
                    // Marker Titik Terpilih
                    Marker(
                      point: _currentCenter,
                      width: 140,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.selectedLocationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primaryTeal,
                            size: 34,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Kontrol Zoom & Pusatkan di pojok kanan bawah
            Positioned(
              right: 10,
              bottom: 10,
              child: Column(
                children: [
                  _buildMapActionButton(
                    icon: Icons.add,
                    onPressed: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, zoom + 1);
                    },
                  ),
                  const SizedBox(height: 5),
                  _buildMapActionButton(
                    icon: Icons.remove,
                    onPressed: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, zoom - 1);
                    },
                  ),
                  const SizedBox(height: 5),
                  _buildMapActionButton(
                    icon: Icons.my_location,
                    onPressed: () {
                      _flyTo(_currentCenter);
                    },
                  ),
                ],
              ),
            ),

            // Tombol Perbesar Peta di pojok kanan atas
            if (widget.showFullscreenButton)
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openFullScreenMap(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full, size: 12, color: AppColors.primaryNavy),
                          SizedBox(width: 4),
                          Text(
                            'Perbesar',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Indikator ketuk peta jika dengan sopir
            if (widget.isWithDriver)
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 11, color: AppColors.primaryTeal),
                      SizedBox(width: 4),
                      Text(
                        'Ketuk peta untuk ubah pin',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenMap(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryNavy,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, size: 20, color: AppColors.primaryTeal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isWithDriver
                                      ? 'Peta Titik Penjemputan Sopir'
                                      : 'Peta Titik Serah Terima Unit',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const Text(
                                  'Geser atau ketuk peta Merauke dengan leluasa',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 380,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _currentCenter,
                              initialZoom: 14.5,
                              onTap: (tapPosition, point) async {
                                if (widget.isWithDriver && widget.onCustomCoordinateSelected != null) {
                                  setState(() {
                                    _currentCenter = point;
                                  });
                                  setDialogState(() {});
                                  widget.onCustomCoordinateSelected!(
                                    'Memuat nama lokasi...',
                                    point,
                                  );
                                  final resolvedLocation = await MeraukeGeocodingService.resolveLocationNameDebounced(point);
                                  if (mounted && resolvedLocation != null) {
                                    setDialogState(() {});
                                    widget.onCustomCoordinateSelected!(
                                      resolvedLocation,
                                      point,
                                    );
                                  }
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.mobiljuragan.mobile',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentCenter,
                                    width: 140,
                                    height: 70,
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryNavy,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.18),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            widget.selectedLocationName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Icon(
                                          Icons.location_on,
                                          color: AppColors.primaryTeal,
                                          size: 34,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (widget.isWithDriver)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app, size: 14, color: AppColors.primaryTeal),
                                    SizedBox(width: 6),
                                    Text(
                                      'Ketuk lokasi mana saja untuk geser pin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pin_drop, size: 16, color: AppColors.primaryTeal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.selectedLocationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Gunakan Titik Ini',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 15, color: AppColors.primaryNavy),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
