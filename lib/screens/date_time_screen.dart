import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTextThemeData,
        CupertinoTheme,
        CupertinoThemeData;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../core/util/format_tanggal.dart';
import '../core/util/rental_duration.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/standard_bottom_sheet.dart';
import 'order_review_screen.dart';
import '../theme/app_typography.dart';

/// Layar pemilihan jadwal tanggal dan durasi sewa
class DateTimeScreen extends StatefulWidget {
  final VehicleModel vehicle;
  final DateTime Function()? nowProvider;

  const DateTimeScreen({
    super.key,
    required this.vehicle,
    this.nowProvider,
  });

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  
  String _selectedTime = '09.00 WIT';
  String _timeDescription = 'Pagi';
  int _durationDays = 2;
  bool _isSelectingEndDate = false; // Siklus 2 ketukan: false = pilih mulai, true = pilih selesai

  final List<String> _monthNames = namaBulan;

  final List<String> _dayNames = namaHariSingkat;

  DateTime _sekarang() => widget.nowProvider?.call() ?? DateTime.now();

  DateTime _minStartMonth(DateTime now) {
    final earliest = tanggalMulaiPalingAwal(now);
    return DateTime(earliest.year, earliest.month, 1);
  }

  DateTime _maxNavMonth(DateTime now) {
    final maxStart = batasTanggalMulaiMaksimal(now);
    return DateTime(maxStart.year, maxStart.month, 1);
  }

  @override
  void initState() {
    super.initState();
    final now = _sekarang();
    final minDate = tanggalMulaiPalingAwal(now);
    final maxDate = batasTanggalMulaiMaksimal(now);
    final booking = context.read<BookingController>();

    final kandidatTanggal = tanggalSaja(booking.selectedDate);
    if (kandidatTanggal.isBefore(minDate)) {
      _selectedDate = minDate;
    } else if (kandidatTanggal.isAfter(maxDate)) {
      _selectedDate = maxDate;
    } else {
      _selectedDate = kandidatTanggal;
    }

    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _selectedTime = jamValidUntukTanggal(
      tanggal: _selectedDate,
      labelSekarang: booking.selectedTime,
      now: now,
    );
    final parsed = _parseTimeOfDay(_selectedTime);
    _timeDescription = _getTimeDescription(parsed?.hour ?? 9);
    _durationDays = booking.durationDays.clamp(1, maxBookingAdvanceDays);
  }

  void _previousMonth() {
    final minMonth = _minStartMonth(_sekarang());
    if (!_displayedMonth.isAfter(minMonth)) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    final maxMonth = _maxNavMonth(_sekarang());
    if (!_displayedMonth.isBefore(maxMonth)) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Tanggal & Waktu',
        stepSubtitle: 'Langkah 3 dari 4',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 14),
                  _buildInteractiveCalendarCard(),
                  const SizedBox(height: 14),
                  _buildScheduleConfigCard(),
                  const SizedBox(height: 14),
                  _buildRentalPolicyNotice(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildStickyCTA(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tentukan Jadwal Rental',
          style: TextStyle(
            fontSize: AppTypography.sizeHeading,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Pilih tanggal mulai sewa dan durasi pemakaian.',
          style: TextStyle(
            fontSize: AppTypography.sizeBody,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveCalendarCard() {
    final int daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );

    final DateTime firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final int startingWeekday = firstDayOfMonth.weekday;

    final String monthName = _monthNames[_displayedMonth.month - 1];
    final String formattedYear = _displayedMonth.year.toString();
    final DateTime returnDate = _selectedDate.add(Duration(days: _durationDays));

    final now = _sekarang();
    final canGoPrev = _displayedMonth.isAfter(_minStartMonth(now));
    final canGoNext = _displayedMonth.isBefore(_maxNavMonth(now));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bulan & Navigasi Kalender: tombol kiri/kanan menempel di tepi
          // kartu supaya posisinya tetap konsisten dan tidak bergeser mengikuti
          // panjang nama bulan.
          Row(
            children: [
              _buildMonthNavButton(
                icon: Icons.chevron_left,
                enabled: canGoPrev,
                onTap: _previousMonth,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$monthName $formattedYear',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeTitle,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildMonthNavButton(
                icon: Icons.chevron_right,
                enabled: canGoNext,
                onTap: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: _dayNames.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildDatesGrid(daysInMonth, startingWeekday, returnDate),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _isSelectingEndDate ? AppColors.tealLight : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSelectingEndDate
                    ? AppColors.primaryTeal.withValues(alpha: 0.25)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSelectingEndDate
                      ? Icons.date_range_rounded
                      : Icons.touch_app_outlined,
                  size: 15,
                  color: _isSelectingEndDate
                      ? AppColors.primaryTeal
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSelectingEndDate
                        ? 'Pilih tanggal selesai'
                        : 'Ketuk tanggal mulai, lalu pilih tanggal selesai',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight:
                          _isSelectingEndDate ? FontWeight.w600 : FontWeight.w500,
                      color: _isSelectingEndDate
                          ? AppColors.primaryTeal
                          : AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.surfaceLight
                  : AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled ? AppColors.borderMedium : AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? AppColors.primaryNavy
                  : AppColors.textSecondary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatesGrid(int totalDays, int startingWeekday, DateTime returnDate) {
    final int emptyLeadingDays = startingWeekday - 1;
    final int totalGridItems = emptyLeadingDays + totalDays;
    final int trailingDays = (7 - (totalGridItems % 7)) % 7;
    final int totalSlots = totalGridItems + trailingDays;

    final DateTime startDayOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final DateTime endDayOnly = DateTime(
      returnDate.year,
      returnDate.month,
      returnDate.day,
    );

    final now = _sekarang();
    final DateTime minStartDate = tanggalMulaiPalingAwal(now);
    final DateTime maxStartDate = batasTanggalMulaiMaksimal(now);

    final DateTime prevMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    final int daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    final DateTime nextMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final int day;
        final DateTime currentDayOnly;
        final bool isOtherMonth;

        if (index < emptyLeadingDays) {
          day = daysInPrevMonth - emptyLeadingDays + 1 + index;
          currentDayOnly = DateTime(prevMonth.year, prevMonth.month, day);
          isOtherMonth = true;
        } else if (index < totalGridItems) {
          day = index - emptyLeadingDays + 1;
          currentDayOnly = DateTime(_displayedMonth.year, _displayedMonth.month, day);
          isOtherMonth = false;
        } else {
          day = index - totalGridItems + 1;
          currentDayOnly = DateTime(nextMonth.year, nextMonth.month, day);
          isOtherMonth = true;
        }

        final bool isDisabled =
            currentDayOnly.isBefore(minStartDate) || currentDayOnly.isAfter(maxStartDate);

        final bool isStartDate = currentDayOnly.isAtSameMomentAs(startDayOnly);
        final bool isEndDate = currentDayOnly.isAtSameMomentAs(endDayOnly);
        final bool isInRange = currentDayOnly.isAfter(startDayOnly) &&
            currentDayOnly.isBefore(endDayOnly);

        return InkWell(
          onTap: isDisabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isOtherMonth) {
                      _displayedMonth = DateTime(currentDayOnly.year, currentDayOnly.month, 1);
                    }
                    if (!_isSelectingEndDate) {
                      // Ketukan 1: Memilih tanggal mulai sewa
                      _selectedDate = currentDayOnly;
                      _durationDays = 1;
                      _isSelectingEndDate = true;
                    } else {
                      // Ketukan 2: Memilih tanggal selesai sewa
                      if (currentDayOnly.isAfter(_selectedDate)) {
                        _durationDays = currentDayOnly.difference(_selectedDate).inDays;
                        _isSelectingEndDate = false;
                      } else if (currentDayOnly.isBefore(_selectedDate)) {
                        // Jika memilih tanggal sebelum tanggal mulai, jadikan tanggal mulai baru
                        _selectedDate = currentDayOnly;
                        _durationDays = 1;
                        _isSelectingEndDate = true;
                      } else {
                        // Mengetuk tanggal yang sama persis: durasi 1 hari
                        _durationDays = 1;
                        _isSelectingEndDate = false;
                      }
                    }

                    final jamBaru = jamValidUntukTanggal(
                      tanggal: _selectedDate,
                      labelSekarang: _selectedTime,
                      now: _sekarang(),
                    );
                    if (jamBaru != _selectedTime) {
                      _selectedTime = jamBaru;
                      final parsedBaru = _parseTimeOfDay(jamBaru);
                      if (parsedBaru != null) {
                        _timeDescription = _getTimeDescription(parsedBaru.hour);
                      }
                    }
                  });
                },
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pita penghubung tanggal sewa
              if (isInRange)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.primaryNavy.withValues(alpha: 0.10),
                  ),
                )
              else if (isStartDate && _durationDays > 0)
                Positioned(
                  right: 0,
                  top: 3,
                  bottom: 3,
                  left: 17,
                  child: Container(
                    color: AppColors.primaryNavy.withValues(alpha: 0.10),
                  ),
                )
              else if (isEndDate && _durationDays > 0)
                Positioned(
                  left: 0,
                  top: 3,
                  bottom: 3,
                  right: 17,
                  child: Container(
                    color: AppColors.primaryNavy.withValues(alpha: 0.10),
                  ),
                ),

              // Lingkaran penanda tanggal
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isStartDate || isEndDate)
                      ? AppColors.primaryNavy
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: (isStartDate || isEndDate)
                          ? FontWeight.w700
                          : isInRange
                              ? FontWeight.w600
                              : FontWeight.w500,
                      color: (isStartDate || isEndDate)
                          ? AppColors.textWhite
                          : isInRange
                              ? AppColors.primaryNavy
                              : isDisabled
                                  ? AppColors.textSecondary.withValues(alpha: 0.22)
                                  : isOtherMonth
                                      ? AppColors.textSecondary.withValues(alpha: 0.78)
                                      : AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.replaceAll(' WIT', '').trim();
      final parts = clean.contains(':') ? clean.split(':') : clean.split('.');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String _getTimeDescription(int hour) {
    if (hour >= 6 && hour < 11) {
      return 'Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Sore';
    } else {
      return 'Malam';
    }
  }

  void _applyTime(String timeStr, {String? desc}) {
    final now = _sekarang();
    final parsed = _parseTimeOfDay(timeStr);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Format jam tidak valid. Silakan pilih waktu yang tersedia.',
          ),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (!adalahJamOperasional(parsed.hour, parsed.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jam sewa di luar jam operasional (06.00 s.d. 22.00 WIT). Untuk penjemputan subuh/malam hari, silakan konfirmasi khusus via Chat CS Merauke.',
          ),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    if (!jadwalMulaiMemenuhiLeadTime(_selectedDate, parsed.hour, parsed.minute, now)) {
      final minPickup = waktuJemputPalingAwal(now);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Untuk sewa hari ini, jam jemput minimal 2 jam dari sekarang (paling cepat pukul ${formatJamWit(minPickup.hour, minPickup.minute)}).',
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    final description = desc ?? _getTimeDescription(parsed.hour);
    setState(() {
      _selectedTime = timeStr;
      _timeDescription = description;
    });
  }

  Future<void> _pickTimeManually() async {
    final now = _sekarang();
    final jamAwal = jamValidUntukTanggal(
      tanggal: _selectedDate,
      labelSekarang: _selectedTime,
      now: now,
    );
    final parsed = _parseTimeOfDay(jamAwal) ?? const TimeOfDay(hour: 9, minute: 0);
    DateTime tempTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      parsed.hour,
      parsed.minute,
    );

    final selected = await StandardBottomSheet.show<DateTime>(
      context: context,
      title: 'Pilih Jam Penjemputan',
      subtitle: 'Format digital 24 jam (WIT)',
      icon: Icons.schedule_rounded,
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final sheetNow = _sekarang();
          final isOperational = adalahJamOperasional(tempTime.hour, tempTime.minute);
          final meetsLeadTime = jadwalMulaiMemenuhiLeadTime(
            _selectedDate,
            tempTime.hour,
            tempTime.minute,
            sheetNow,
          );
          final isValid = isOperational && meetsLeadTime;
          final minPickup = waktuJemputPalingAwal(sheetNow);

          final String statusText;
          final String buttonText;
          if (!isOperational) {
            statusText =
                'Di luar jam operasional (06.00 - 22.00 WIT). Butuh konfirmasi khusus CS.';
            buttonText = 'Pilih jam 06.00 - 22.00 WIT';
          } else if (!meetsLeadTime) {
            final jamMinimal = formatJamWit(minPickup.hour, minPickup.minute);
            statusText = 'Minimal 2 jam dari sekarang (paling cepat $jamMinimal).';
            buttonText = 'Pilih jam mulai $jamMinimal';
          } else {
            statusText = 'Jam operasional normal Merauke (06.00 - 22.00 WIT)';
            buttonText = 'Terapkan Jam Sewa';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Digital Wheel Picker
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: tempTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      setSheetState(() {
                        tempTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          newDateTime.hour,
                          newDateTime.minute,
                        );
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status Jam Operasional Info
              Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16,
                    color: isValid ? AppColors.statusSuccessFg : AppColors.statusDangerFg,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: FontWeight.w500,
                        color: isValid ? AppColors.statusSuccessFg : AppColors.statusDangerFg,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol Konfirmasi
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
                child: ElevatedButton(
                  onPressed: isValid
                      ? () => Navigator.of(sheetContext).pop(tempTime)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: AppColors.textWhite,
                    disabledBackgroundColor: AppColors.borderSubtle,
                    disabledForegroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (selected != null) {
      final formattedTime =
          '${selected.hour.toString().padLeft(2, '0')}.${selected.minute.toString().padLeft(2, '0')} WIT';
      _applyTime(formattedTime);
    }
  }

  Widget _buildScheduleConfigCard() {
    final returnDate = _selectedDate.add(Duration(days: _durationDays));
    final returnDayName = _dayNames[returnDate.weekday - 1];
    final formattedReturnDate =
        '$returnDayName, ${returnDate.day.toString().padLeft(2, '0')} ${_monthNames[returnDate.month - 1]} ${returnDate.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Jam Mulai Sewa Header
          const Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Jam Mulai Sewa',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pilihan Jam Mandiri
          InkWell(
            onTap: _pickTimeManually,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTime,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeTitle,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sesi $_timeDescription',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: AppColors.borderMedium),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'Ubah',
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
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
            ),
          ),
          const SizedBox(height: 10),

          // Keterangan Jam Operasional (Tanpa Box Berlapis)
          Builder(
            builder: (context) {
              final now = _sekarang();
              final isHariIni =
                  tanggalSaja(_selectedDate).isAtSameMomentAs(tanggalSaja(now));
              final minPickup = waktuJemputPalingAwal(now);
              final teks = isHariIni
                  ? 'Penjemputan dilayani pukul 06.00 - 22.00 WIT. Pemesanan hari ini minimal 2 jam dari sekarang (mulai pukul ${formatJamWit(minPickup.hour, minPickup.minute)}).'
                  : 'Penjemputan dilayani pukul 06.00 - 22.00 WIT. Jadwal sewa tersedia hingga 60 hari ke depan.';
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.primaryTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      teks,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 14),

          // 2. Ringkasan Durasi & Pengembalian Armada (Netral)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 20,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kembali: $formattedReturnDate pukul $_selectedTime',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total durasi sewa $_durationDays Hari (${_durationDays * 24} jam penuh)',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
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
        ],
      ),
    );
  }

  Widget _buildRentalPolicyNotice() {
    final booking = context.watch<BookingController>();
    final isDriver = booking.withDriver;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDriver
                  ? 'Sopir menjemput di lokasi pilihan Anda sesuai jadwal mulai pukul $_selectedTime.'
                  : 'Hitungan sewa berlaku 24 jam penuh per hari sejak serah terima unit armada di Merauke.',
              style: const TextStyle(
                fontSize: AppTypography.sizeBody,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.45,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCTA() {
    final returnDate = _selectedDate.add(Duration(days: _durationDays));
    final formattedDate =
        '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1].substring(0, 3)}';
    final formattedReturn =
        '${returnDate.day} ${_monthNames[returnDate.month - 1].substring(0, 3)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Periode Sewa',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_durationDays Hari ($formattedDate - $formattedReturn)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: ElevatedButton(
                  onPressed: () {
                    final error = validasiJadwalSewa(
                      tanggal: _selectedDate,
                      labelJam: _selectedTime,
                      now: _sekarang(),
                    );
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }
                    context.read<BookingController>().setSchedule(
                          date: _selectedDate,
                          time: _selectedTime,
                          durationDays: _durationDays,
                        );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrderReviewScreen(
                          vehicle: widget.vehicle,
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Lanjut ke Tinjau Pesanan',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

