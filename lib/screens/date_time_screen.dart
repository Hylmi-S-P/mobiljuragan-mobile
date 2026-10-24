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
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'order_review_screen.dart';
import '../theme/app_typography.dart';

/// Layar pemilihan jadwal tanggal dan durasi sewa
class DateTimeScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const DateTimeScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  
  String _selectedTime = '09.00 WIT';
  String _timeDescription = 'Pagi hari';
  int _durationDays = 2;
  bool _isSelectingEndDate = false; // Siklus 2 ketukan: false = pilih mulai, true = pilih selesai

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    final booking = context.read<BookingController>();
    _displayedMonth = DateTime(booking.selectedDate.year, booking.selectedDate.month, 1);
    _selectedDate = booking.selectedDate;
    final initialParsed = _parseTimeOfDay(booking.selectedTime);
    if (_isWithinOperationalHours(initialParsed)) {
      _selectedTime = booking.selectedTime;
    } else {
      _selectedTime = '09.00 WIT';
    }
    _durationDays = booking.durationDays.clamp(1, 30);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          // Header Bulan & Navigasi Kalender
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: _previousMonth,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$monthName $formattedYear',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeTitle,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _nextMonth,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSelectingEndDate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'Pilih tanggal selesai',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayNames.map((day) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    day,
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
          const SizedBox(height: 14),
          _buildCalendarLegend(returnDate),
        ],
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

        final bool isStartDate = currentDayOnly.isAtSameMomentAs(startDayOnly);
        final bool isEndDate = currentDayOnly.isAtSameMomentAs(endDayOnly);
        final bool isInRange = currentDayOnly.isAfter(startDayOnly) &&
            currentDayOnly.isBefore(endDayOnly);

        return InkWell(
          onTap: () {
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
                  final diff = currentDayOnly.difference(_selectedDate).inDays;
                  _durationDays = diff.clamp(1, 30);
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
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  ),
                )
              else if (isStartDate && _durationDays > 0)
                Positioned(
                  right: 0,
                  top: 3,
                  bottom: 3,
                  left: 17,
                  child: Container(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  ),
                )
              else if (isEndDate && _durationDays > 0)
                Positioned(
                  left: 0,
                  top: 3,
                  bottom: 3,
                  right: 17,
                  child: Container(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  ),
                ),

              // Lingkaran penanda tanggal
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isStartDate
                      ? AppColors.primaryTeal
                      : isEndDate
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
                              : isOtherMonth
                                  ? AppColors.textSecondary.withValues(alpha: 0.35)
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

  Widget _buildCalendarLegend(DateTime returnDate) {
    final startFormatted =
        '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1].substring(0, 3)}';
    final returnFormatted =
        '${returnDate.day} ${_monthNames[returnDate.month - 1].substring(0, 3)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mulai: $startFormatted',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Selesai: $returnFormatted',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_durationDays Hari',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primaryTeal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isSelectingEndDate
                      ? 'Ketukan 2/2: Ketuk tanggal selesai untuk mengatur durasi sewa'
                      : 'Ketukan 1/2: Ketuk tanggal di kalender untuk tanggal mulai sewa',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  bool _isWithinOperationalHours(TimeOfDay? time) {
    if (time == null) return false;
    final totalMinutes = time.hour * 60 + time.minute;
    return totalMinutes >= 360 && totalMinutes <= 1320;
  }

  String _getTimeDescription(int hour) {
    if (hour >= 6 && hour < 11) {
      return 'Pagi hari';
    } else if (hour >= 11 && hour < 15) {
      return 'Siang hari';
    } else if (hour >= 15 && hour < 18) {
      return 'Sore hari';
    } else {
      return 'Malam hari';
    }
  }

  void _applyTime(String timeStr, {String? desc}) {
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
    if (!_isWithinOperationalHours(parsed)) {
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
    final description = desc ?? _getTimeDescription(parsed.hour);
    setState(() {
      _selectedTime = timeStr;
      _timeDescription = description;
    });
  }

  Future<void> _pickTimeManually() async {
    final parsed = _parseTimeOfDay(_selectedTime) ?? const TimeOfDay(hour: 9, minute: 0);
    DateTime tempTime = DateTime(
      2026,
      1,
      1,
      parsed.hour,
      parsed.minute,
    );

    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentHour = tempTime.hour;
            final isOperational = currentHour >= 6 && currentHour <= 22;

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Bottom Sheet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Jam Penjemputan',
                              style: TextStyle(
                                fontSize: AppTypography.sizeHeading,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Format digital 24 jam (WIT)',
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Digital Wheel Picker
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
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
                              tempTime = newDateTime;
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
                          isOperational ? Icons.check_circle_outline : Icons.info_outline,
                          size: 16,
                          color: isOperational ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isOperational
                                ? 'Jam operasional normal Merauke (06.00 - 22.00 WIT)'
                                : 'Di luar jam operasional (06.00 - 22.00 WIT). Butuh konfirmasi khusus CS.',
                            style: TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              fontWeight: FontWeight.w500,
                              color: isOperational ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tombol Konfirmasi
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(tempTime);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Terapkan Jam Sewa',
                          style: TextStyle(
                            fontSize: AppTypography.sizeBodyLarge,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Jam Sewa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.primaryTeal,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Jam Sewa',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  '06.00 - 22.00 WIT',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pilihan Jam Mandiri
          InkWell(
            onTap: _pickTimeManually,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
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
                          'Sesi $_timeDescription • Ketuk untuk ubah jam',
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 13, color: AppColors.primaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'Pilih Jam',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.primaryTeal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Penjemputan dilayani pukul 06.00 - 22.00 WIT. Untuk kebutuhan penjemputan subuh/malam hari, silakan konfirmasi khusus via Chat CS Merauke.',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 14),

          // 2. Ringkasan Durasi & Pengembalian Armada (Ditentukan via Kalender)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 18,
                  color: Color(0xFF16A34A),
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
                          color: Color(0xFF166534),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Durasi total $_durationDays hari sewa (${_durationDays * 24} jam penuh, diatur via kalender)',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF15803D),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDriver
                  ? 'Layanan supir aktif 12 jam per hari (mulai pukul $_selectedTime). Supir standby setiap hari sesuai jadwal di Merauke.'
                  : 'Hitungan sewa berlaku 24 jam penuh per hari sejak serah terima kunci unit di Merauke.',
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            SizedBox(
              height: (44 * MediaQuery.textScalerOf(context).scale(1)).clamp(44, 88),
              child: ElevatedButton(
                onPressed: () {
                  final parsed = _parseTimeOfDay(_selectedTime);
                  if (!_isWithinOperationalHours(parsed)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Jam sewa harus dalam batas operasional (06.00 s.d. 22.00 WIT). Hubungi Chat CS Merauke jika butuh penjemputan khusus.',
                        ),
                        backgroundColor: Color(0xFFDC2626),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Lanjut ke Tinjau Pesanan',
                  style: AppTypography.cardTitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

