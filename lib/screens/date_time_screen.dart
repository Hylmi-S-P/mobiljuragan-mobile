import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTextThemeData,
        CupertinoTheme,
        CupertinoThemeData;
import 'package:flutter/material.dart';
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
              const Text(
                'Bulan terpilih',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalGridItems,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        if (index < emptyLeadingDays) {
          return const SizedBox.shrink();
        }

        final int day = index - emptyLeadingDays + 1;
        final DateTime currentDayOnly = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          day,
        );

        final bool isStartDate = currentDayOnly.isAtSameMomentAs(startDayOnly);
        final bool isEndDate = currentDayOnly.isAtSameMomentAs(endDayOnly);
        final bool isInRange = currentDayOnly.isAfter(startDayOnly) &&
            currentDayOnly.isBefore(endDayOnly);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                day,
              );
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
      child: Wrap(
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

  void _showAlarmStyleTimePickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AlarmTimePickerSheet(
          initialTime: _selectedTime,
          onTimeSelected: (formattedTime, description) {
            _applyTime(formattedTime, desc: description);
          },
        );
      },
    );
  }

  Widget _buildScheduleConfigCard() {
    final quickTimes = [
      '06.00 WIT',
      '08.00 WIT',
      '10.00 WIT',
      '13.00 WIT',
      '16.00 WIT',
      '19.00 WIT',
      '22.00 WIT',
    ];

    final quickDays = [
      {'label': '1 Hari', 'days': 1},
      {'label': '2 Hari', 'days': 2},
      {'label': '3 Hari', 'days': 3},
      {'label': '5 Hari', 'days': 5},
      {'label': '7 Hari (1 Mgg)', 'days': 7},
      {'label': '14 Hari (2 Mgg)', 'days': 14},
      {'label': '30 Hari (1 Bln)', 'days': 30},
    ];

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
          // Wrap: tombol "Pilih Jam Lain" turun ke baris berikutnya saat ukuran
          // teks sistem diperbesar, bukan terpotong di tepi kanan kartu.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Wrap bersarang: judul dan badge jam boleh terpisah baris saat
              // ukuran teks sistem ekstrem, bukan saling mendorong keluar.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      const Text(
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
              InkWell(
                onTap: _showAlarmStyleTimePickerSheet,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 13,
                        color: AppColors.primaryTeal,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Pilih Jam Lain',
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
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pilihan Chip Waktu
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...(() {
                  final timesToShow = List<String>.from(quickTimes);
                  if (!timesToShow.contains(_selectedTime)) {
                    final parsed = _parseTimeOfDay(_selectedTime);
                    if (_isWithinOperationalHours(parsed)) {
                      timesToShow.insert(0, _selectedTime);
                    }
                  }
                  return timesToShow.map((time) {
                    final isSelected = _selectedTime == time;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => _applyTime(time),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryNavy : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: AppTypography.sizeBody,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                })(),
                InkWell(
                  onTap: _showAlarmStyleTimePickerSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.alarm_rounded, size: 14, color: AppColors.primaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'Jam Lain...',
                          style: TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
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
          const SizedBox(height: 6),
          Text(
            'Jam sewa terpilih: $_selectedTime (Sesi $_timeDescription)',
            style: const TextStyle(
              fontSize: AppTypography.sizeCaption,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
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

          // 2. Durasi Sewa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: AppColors.primaryNavy,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durasi Sewa',
                            style: TextStyle(
                              fontSize: AppTypography.sizeBodyLarge,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            'Sewa harian hingga 30 hari',
                            style: TextStyle(
                              fontSize: AppTypography.sizeTiny,
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
              const SizedBox(width: 8),
              Row(
                children: [
                  InkWell(
                    onTap: _durationDays > 1
                        ? () {
                            setState(() => _durationDays--);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _durationDays > 1 ? AppColors.surfaceLight : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _durationDays > 1 ? AppColors.borderSubtle : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 16,
                        color: _durationDays > 1 ? AppColors.primaryNavy : AppColors.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 64),
                    alignment: Alignment.center,
                    child: Text(
                      '$_durationDays Hari',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeTitle,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _durationDays < 30
                        ? () {
                            setState(() => _durationDays++);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _durationDays < 30 ? AppColors.surfaceLight : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _durationDays < 30 ? AppColors.borderSubtle : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: _durationDays < 30 ? AppColors.primaryTeal : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pilihan Chip Durasi Hari
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickDays.map((item) {
                final days = item['days'] as int;
                final label = item['label'] as String;
                final isSelected = _durationDays == days;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _durationDays = days;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryNavy : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Ringkasan Pengembalian Armada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kembali: $formattedReturnDate pukul $_selectedTime',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF166534),
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Durasi total $_durationDays hari sewa (${_durationDays * 24} jam penuh)',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeTiny,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        // Wrap: saat ukuran teks sangat besar, tombol turun ke barisnya sendiri
        // sehingga label periode sewa tetap terbaca wajar.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 120,
                maxWidth: MediaQuery.sizeOf(context).width - 200,
              ),
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
                  Text(
                    '$_durationDays Hari ($formattedDate - $formattedReturn)',
                    maxLines: 2,
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
            SizedBox(
              // Tinggi ikut skala teks sistem agar label tombol tidak terpotong.
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

/// Bottom Sheet Interaktif dengan roda pemutar (wheel scroll) jam dan menit 24 jam ala alarm
class _AlarmTimePickerSheet extends StatefulWidget {
  final String initialTime;
  final Function(String formattedTime, String description) onTimeSelected;

  const _AlarmTimePickerSheet({
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<_AlarmTimePickerSheet> createState() => _AlarmTimePickerSheetState();
}

class _AlarmTimePickerSheetState extends State<_AlarmTimePickerSheet> {
  late final ValueNotifier<TimeOfDay> _selectedTimeNotifier;
  int _pickerKey = 0;

  @override
  void initState() {
    super.initState();
    final parsed = _parseInitialTime(widget.initialTime);
    _selectedTimeNotifier = ValueNotifier<TimeOfDay>(parsed);
  }

  @override
  void dispose() {
    _selectedTimeNotifier.dispose();
    super.dispose();
  }

  TimeOfDay _parseInitialTime(String timeStr) {
    try {
      final clean = timeStr.replaceAll(' WIT', '').trim();
      final parts = clean.contains(':') ? clean.split(':') : clean.split('.');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  bool _isWithinOperationalHours(TimeOfDay time) {
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

  void _snapMinute(int targetMinute) {
    final current = _selectedTimeNotifier.value;
    final updated = TimeOfDay(hour: current.hour, minute: targetMinute);
    _selectedTimeNotifier.value = updated;
    setState(() {
      _pickerKey++;
    });
  }

  void _setTime(int hour, int minute) {
    _selectedTimeNotifier.value = TimeOfDay(hour: hour, minute: minute);
    setState(() {
      _pickerKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Judul & Tombol Tutup
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.alarm_rounded,
                          size: 18,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atur Jam Sewa',
                              style: TextStyle(
                                fontSize: AppTypography.sizeAmount,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Geser jam dan menit (Format 24 Jam WIT)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tampilan Digital Jam Real-time (Reaktif tanpa rebuild picker)
            ValueListenableBuilder<TimeOfDay>(
              valueListenable: _selectedTimeNotifier,
              builder: (context, time, _) {
                final isValid = _isWithinOperationalHours(time);
                final hourStr = time.hour.toString().padLeft(2, '0');
                final minuteStr = time.minute.toString().padLeft(2, '0');
                final sessionDesc = _getTimeDescription(time.hour);

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isValid ? AppColors.borderSubtle : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$hourStr : $minuteStr',
                            style: TextStyle(
                              fontSize: AppTypography.sizeClock,
                              fontWeight: FontWeight.w800,
                              color: isValid ? AppColors.primaryNavy : const Color(0xFF64748B),
                              letterSpacing: 2,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isValid ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isValid ? 'WIT' : 'TUTUP',
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeTiny,
                                    fontWeight: FontWeight.w700,
                                    color: isValid ? Colors.white : const Color(0xFF475569),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isValid ? 'Sesi $sessionDesc' : 'Di luar jam operasional',
                                style: TextStyle(
                                  fontSize: AppTypography.sizeCaption,
                                  fontWeight: FontWeight.w600,
                                  color: isValid ? AppColors.primaryTeal : const Color(0xFF64748B),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isValid) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Waktu operasional tersedia pukul 06.00 s.d. 22.00 WIT. Untuk penjemputan subuh/malam hari, silakan konfirmasi khusus via Chat CS Merauke.',
                                style: TextStyle(
                                  fontSize: AppTypography.sizeTiny,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF92400E),
                                  fontFamily: 'Inter',
                                  height: 1.3,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (time.hour < 6) {
                                  _setTime(6, 0);
                                } else {
                                  _setTime(22, 0);
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  time.hour < 6 ? 'Atur 06.00' : 'Atur 22.00',
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Area Roda Pemutar Jam & Menit Native Cupertino Wheel
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              clipBehavior: Clip.antiAlias,
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.light,
                  primaryColor: AppColors.primaryTeal,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: AppTypography.sizePicker,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  key: ValueKey(_pickerKey),
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(
                    2026,
                    1,
                    1,
                    _selectedTimeNotifier.value.hour,
                    _selectedTimeNotifier.value.minute,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    _selectedTimeNotifier.value = TimeOfDay(
                      hour: newDateTime.hour,
                      minute: newDateTime.minute,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Pintas Jam Operasional Cepat
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Jam Populer: ',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  ...[
                    {'label': '06.00', 'h': 6, 'm': 0},
                    {'label': '09.00', 'h': 9, 'm': 0},
                    {'label': '13.00', 'h': 13, 'm': 0},
                    {'label': '17.00', 'h': 17, 'm': 0},
                    {'label': '22.00', 'h': 22, 'm': 0},
                  ].map((preset) {
                    final h = preset['h'] as int;
                    final m = preset['m'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        onTap: () => _setTime(h, m),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            preset['label'] as String,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryNavy,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tombol Pintas Menit (:00, :15, :30, :45)
            ValueListenableBuilder<TimeOfDay>(
              valueListenable: _selectedTimeNotifier,
              builder: (context, time, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bulatkan Menit: ',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    ...[0, 15, 30, 45].map((quickMin) {
                      final isCurrentMin = time.minute == quickMin;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: InkWell(
                          onTap: () => _snapMinute(quickMin),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrentMin ? AppColors.tealLight : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCurrentMin ? AppColors.primaryTeal : AppColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              ':${quickMin.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                fontWeight: isCurrentMin ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrentMin ? AppColors.primaryTeal : AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // Tombol Aksi
            ValueListenableBuilder<TimeOfDay>(
              valueListenable: _selectedTimeNotifier,
              builder: (context, time, _) {
                final isValid = _isWithinOperationalHours(time);
                return Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: AppTypography.sizeBodyLarge,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: isValid
                              ? () {
                                  final current = _selectedTimeNotifier.value;
                                  final formattedTime =
                                      '${current.hour.toString().padLeft(2, '0')}.${current.minute.toString().padLeft(2, '0')} WIT';
                                  final sessionDesc = _getTimeDescription(current.hour);
                                  widget.onTimeSelected(formattedTime, sessionDesc);
                                  Navigator.pop(context);
                                }
                              : () {
                                  if (time.hour < 6) {
                                    _setTime(6, 0);
                                  } else {
                                    _setTime(22, 0);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isValid ? AppColors.primaryNavy : const Color(0xFFF1F5F9),
                            foregroundColor: isValid ? AppColors.textWhite : AppColors.primaryNavy,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isValid ? Colors.transparent : AppColors.borderSubtle,
                              ),
                            ),
                          ),
                          child: Text(
                            isValid
                                ? 'Terapkan Jam Sewa'
                                : (time.hour < 6
                                    ? 'Atur ke Jam Buka (06.00)'
                                    : 'Atur ke Jam Tutup (22.00)'),
                            style: TextStyle(
                              fontSize: AppTypography.sizeBodyLarge,
                              fontWeight: FontWeight.w700,
                              color: isValid ? Colors.white : AppColors.primaryNavy,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
